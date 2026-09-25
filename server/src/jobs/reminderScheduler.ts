import cron from "node-cron";
import { db, messaging } from "../config/firebase";
import { Timestamp, FieldValue, QueryDocumentSnapshot } from "firebase-admin/firestore";

/**
 * Starts a cron job that runs every 60 seconds, queries Firestore for tasks
 * whose `resolvedDatetime` has arrived, and sends an FCM push notification
 * for each one.
 *
 * This replaces the old client-side WorkManager + flutter_local_notifications
 * approach, which failed whenever Android's battery optimization killed the
 * app process or Doze mode deferred background work.
 */
export function startReminderScheduler(): void {
  console.log("[Scheduler] Starting reminder scheduler (every 60 seconds)");

  // Run immediately on startup, then every minute
  void checkDueTasks();

  cron.schedule("* * * * *", async () => {
    console.log("[Scheduler] Running — checking for due tasks...");
    try {
      await checkDueTasks();
    } catch (error) {
      console.error("[Scheduler] Unhandled error:", error);
    }
  });
}

async function checkDueTasks(): Promise<void> {
  const now = Timestamp.now();

  // collectionGroup('notes') queries every user's notes subcollection at once.
  // Requires a composite index on (status, notificationSent, resolvedDatetime)
  // for the 'notes' collection group. The first time this runs against
  // production Firestore it will fail with an error containing the direct
  // URL to create that index — follow it once and the query works from then on.
  const snapshot = await db
    .collectionGroup("notes")
    .where("status", "==", "scheduled")
    .where("notificationSent", "==", false)
    .where("resolvedDatetime", "<=", now)
    .get();

  if (snapshot.empty) {
    console.log("[Scheduler] No due tasks found");
    return;
  }

  console.log(`[Scheduler] Found ${snapshot.size} due task(s)`);

  for (const doc of snapshot.docs) {
    await processTask(doc);
  }
}

async function processTask(
  doc: QueryDocumentSnapshot,
): Promise<void> {
  const data = doc.data();
  const taskDescription =
    (data.taskDescription as string) || "You have a reminder";

  // Extract userId from the document path: users/{uid}/notes/{noteId}
  const pathParts = doc.ref.path.split("/");
  const userId = pathParts[1];
  const noteId = doc.id;

  console.log(
    `[Scheduler] Processing task ${noteId} for user ${userId}: "${taskDescription}"`,
  );

  // Get user's FCM tokens
  const tokensSnapshot = await db
    .collection("users")
    .doc(userId)
    .collection("fcmTokens")
    .get();

  if (tokensSnapshot.empty) {
    console.warn(
      `[Scheduler] No FCM tokens found for user ${userId}, skipping task ${noteId}`,
    );
    return;
  }

  const tokens = tokensSnapshot.docs.map((d: any) => d.data().token as string);
  console.log(
    `[Scheduler] Sending to ${tokens.length} device(s) for user ${userId}`,
  );

  let successCount = 0;
  const invalidTokens: string[] = [];

  for (const token of tokens) {
    try {
      await messaging.send({
        token,
        notification: {
          title: "Reminder",
          body: taskDescription,
        },
        data: {
          noteId,
          userId,
          type: "reminder",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "note_reminders",
            priority: "high",
          },
        },
      });

      console.log(
        `[FCM] Notification sent successfully to token ${token.substring(0, 20)}...`,
      );
      successCount++;
    } catch (error: unknown) {
      const err = error as { code?: string; message?: string };
      console.error(
        `[FCM] Failed to send to token ${token.substring(0, 20)}...:`,
        err.message || error,
      );

      // Remove invalid/expired tokens
      if (
        err.code === "messaging/invalid-registration-token" ||
        err.code === "messaging/registration-token-not-registered"
      ) {
        invalidTokens.push(token);
      }
    }
  }

  // Clean up invalid tokens
  for (const token of invalidTokens) {
    try {
      await db
        .collection("users")
        .doc(userId)
        .collection("fcmTokens")
        .doc(token)
        .delete();
      console.log(`[FCM] Removed invalid token for user ${userId}`);
    } catch (err) {
      console.error("[FCM] Failed to remove invalid token:", err);
    }
  }

  // Only mark as notified if at least one send succeeded
  if (successCount > 0) {
    try {
      const updateData: Record<string, unknown> = {
        notificationSent: true,
        status: "notified",
        updatedAt: FieldValue.serverTimestamp(),
      };

      // Handle recurring tasks — compute the next occurrence and reset
      // the notification flag so the scheduler picks it up again.
      if (data.recurrenceRule) {
        const nextDatetime = calculateNextOccurrence(
          data.resolvedDatetime as Timestamp,
          data.recurrenceRule as string,
        );
        if (nextDatetime) {
          updateData.resolvedDatetime = nextDatetime;
          updateData.notificationSent = false;
          updateData.status = "scheduled";
          console.log(
            `[Scheduler] Recurring task ${noteId}: next occurrence scheduled`,
          );
        }
      }

      await doc.ref.update(updateData);
      console.log(`[Scheduler] Task ${noteId} marked as notified`);
    } catch (error) {
      console.error(`[Scheduler] Failed to update task ${noteId}:`, error);
    }
  } else {
    console.warn(
      `[Scheduler] No successful sends for task ${noteId}, will retry next cycle`,
    );
  }
}

/**
 * Calculates the next occurrence for a recurring task.
 *
 * Handles basic RRULE patterns (FREQ=DAILY/WEEKLY/MONTHLY/YEARLY with
 * optional INTERVAL). Returns null if the rule is unsupported.
 */
function calculateNextOccurrence(
  currentDatetime: Timestamp,
  recurrenceRule: string,
): Timestamp | null {
  try {
    const current = currentDatetime.toDate();

    const freqMatch = recurrenceRule.match(/FREQ=(\w+)/);
    const intervalMatch = recurrenceRule.match(/INTERVAL=(\d+)/);

    if (!freqMatch) return null;

    const freq = freqMatch[1];
    const interval = intervalMatch ? parseInt(intervalMatch[1], 10) : 1;

    const next = new Date(current);

    switch (freq) {
      case "DAILY":
        next.setDate(next.getDate() + interval);
        break;
      case "WEEKLY":
        next.setDate(next.getDate() + 7 * interval);
        break;
      case "MONTHLY":
        next.setMonth(next.getMonth() + interval);
        break;
      case "YEARLY":
        next.setFullYear(next.getFullYear() + interval);
        break;
      default:
        console.warn(
          `[Scheduler] Unsupported RRULE frequency: ${freq}`,
        );
        return null;
    }

    return Timestamp.fromDate(next);
  } catch (error) {
    console.error(
      "[Scheduler] Failed to calculate next occurrence:",
      error,
    );
    return null;
  }
}
