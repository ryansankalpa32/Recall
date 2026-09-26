import { db } from "../config/firebase";
import { Timestamp, FieldValue } from "firebase-admin/firestore";

/** UTC offset string for well-known IANA zones used by Sri Lankan users. */
const TIMEZONE_OFFSETS: Record<string, string> = {
  "Asia/Colombo": "+05:30",
  "Asia/Kolkata": "+05:30",
  "UTC": "+00:00",
  "Etc/UTC": "+00:00",
};

/**
 * Interprets a local wall-clock datetime string (e.g. `2026-09-25T15:00:00`)
 * in the given IANA timezone and returns a Firestore Timestamp.
 *
 * The string carries no offset or `Z` — the same ISO-8601 local format that
 * the parse-note endpoint and the Flutter client both use (see `_localIso` in
 * `http_recall_api_client.dart`). Appending the zone's UTC offset before
 * handing it to `Date()` makes the conversion unambiguous regardless of what
 * timezone the server process happens to run in.
 */
function localDatetimeToTimestamp(
  datetime: string,
  timeZone: string,
): Timestamp {
  const offset = TIMEZONE_OFFSETS[timeZone] || "+05:30"; // default to Sri Lanka
  const utcDate = new Date(`${datetime}${offset}`);

  if (isNaN(utcDate.getTime())) {
    throw new Error(`Invalid datetime: ${datetime}`);
  }

  return Timestamp.fromDate(utcDate);
}

export interface CreateNoteData {
  firestoreId?: string;
  rawText: string;
  taskDescription: string;
  triggerType: string;
  locationKind: string | null;
  locationValue: string | null;
  resolvedDatetime: string | null;
  recurrenceRule: string | null;
  confidence: number;
  timeZone?: string;
}

/**
 * Validates and saves a note to Firestore under `users/{uid}/notes`.
 *
 * Returns the auto-generated document ID so the Flutter client can store it
 * locally as `firestoreId` for subsequent sync-listener matching.
 */
export async function createNote(
  uid: string,
  data: CreateNoteData,
): Promise<string> {
  const hasTime = data.triggerType === "time" && data.resolvedDatetime;
  const timeZone = data.timeZone || "Asia/Colombo";

  const noteData: Record<string, unknown> = {
    rawText: data.rawText || data.taskDescription,
    taskDescription: data.taskDescription,
    triggerType: data.triggerType,
    locationKind: data.locationKind || null,
    locationValue: data.locationValue || null,
    resolvedDatetime: hasTime
      ? localDatetimeToTimestamp(data.resolvedDatetime!, timeZone)
      : null,
    recurrenceRule: data.recurrenceRule || null,
    confidence: data.confidence ?? 0,
    status: hasTime ? "scheduled" : "pending",
    notificationSent: false,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };

  const collectionRef = db.collection("users").doc(uid).collection("notes");
  let docRef;

  if (data.firestoreId) {
    docRef = collectionRef.doc(data.firestoreId);
    await docRef.set(noteData);
  } else {
    docRef = await collectionRef.add(noteData);
  }

  console.log(
    `[NoteService] Created note ${docRef.id} for user ${uid}, ` +
      `triggerType=${data.triggerType}, ` +
      `resolvedDatetime=${data.resolvedDatetime || "none"}`,
  );

  return docRef.id;
}
