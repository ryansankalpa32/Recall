import { Router, Response } from "express";
import { z } from "zod";
import { AuthRequest, authenticateUser } from "../middleware/auth";
import { db } from "../config/firebase";
import { FieldValue } from "firebase-admin/firestore";

const router = Router();

const FcmTokenSchema = z.object({
  token: z.string().min(1).max(500),
});

/**
 * POST /api/fcm-token — register (or refresh) a device's FCM token.
 *
 * The token is stored under `users/{uid}/fcmTokens/{token}` using the raw
 * token string as the document ID. This gives us a natural upsert: the first
 * registration is a create, and every token-refresh from
 * `FirebaseMessaging.onTokenRefresh` is a merge-set that only updates
 * `updatedAt`.
 */
router.post(
  "/fcm-token",
  authenticateUser,
  async (req: AuthRequest, res: Response) => {
    const uid = req.uid;
    if (!uid) {
      res.status(401).json({ error: "User not authenticated" });
      return;
    }

    const parsed = FcmTokenSchema.safeParse(req.body);
    if (!parsed.success) {
      res
        .status(400)
        .json({ error: `Invalid request: ${parsed.error.message}` });
      return;
    }

    try {
      const { token } = parsed.data;

      // Use the token as the document ID for easy upsert
      await db
        .collection("users")
        .doc(uid)
        .collection("fcmTokens")
        .doc(token)
        .set(
          {
            token,
            updatedAt: FieldValue.serverTimestamp(),
            platform: (req.headers["x-platform"] as string) || "unknown",
          },
          { merge: true },
        );

      console.log(`[FCM] Token stored for user ${uid}`);
      res.json({ success: true, message: "FCM token registered" });
    } catch (error) {
      console.error("[FCM] Failed to store token:", error);
      res.status(500).json({ error: "Failed to register FCM token" });
    }
  },
);

export default router;
