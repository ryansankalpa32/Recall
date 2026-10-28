import { Response } from "express";
import { z } from "zod";
import { AuthRequest } from "../middleware/auth";
import { createNote } from "../services/noteService";
import { parseNoteWithGemini, AiParseError } from "../services/aiService";
import { LOCAL_DATETIME_RE } from "../schema";

function getCurrentLocalWallClock(): string {
  const d = new Date();
  const pad = (n: number) => n.toString().padStart(2, "0");
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
}

const CreateNoteSchema = z.object({
  firestoreId: z.string().optional(),
  rawText: z.string().trim().min(1).max(2000).optional(),
  taskDescription: z.string().trim().min(1).max(2000),
  triggerType: z.enum(["time", "none", "location", "both"]),
  locationKind: z.string().nullable().optional(),
  locationValue: z.string().nullable().optional(),
  resolvedDatetime: z.string().nullable().optional(),
  recurrenceRule: z.string().nullable().optional(),
  confidence: z.number().min(0).max(1).optional(),
  timeZone: z.string().min(1).max(64).optional(),
});

const QuickCreateNoteSchema = z.object({
  rawText: z.string().trim().min(1).max(1000),
  now: z
    .string()
    .regex(LOCAL_DATETIME_RE, "now must be ISO-8601 local, no offset")
    .optional(),
  timeZone: z.string().min(1).max(64).optional(),
});

export async function createNoteHandler(
  req: AuthRequest,
  res: Response,
): Promise<void> {
  const uid = req.uid;
  if (!uid) {
    res.status(401).json({ error: "User not authenticated" });
    return;
  }

  const parsed = CreateNoteSchema.safeParse(req.body);
  if (!parsed.success) {
    res
      .status(400)
      .json({ error: `Invalid request body: ${parsed.error.message}` });
    return;
  }

  try {
    const noteId = await createNote(uid, {
      firestoreId: parsed.data.firestoreId,
      rawText: parsed.data.rawText || parsed.data.taskDescription,
      taskDescription: parsed.data.taskDescription,
      triggerType: parsed.data.triggerType,
      locationKind: parsed.data.locationKind ?? null,
      locationValue: parsed.data.locationValue ?? null,
      resolvedDatetime: parsed.data.resolvedDatetime ?? null,
      recurrenceRule: parsed.data.recurrenceRule ?? null,
      confidence: parsed.data.confidence ?? 0,
      timeZone: parsed.data.timeZone,
    });

    res.status(201).json({
      success: true,
      message: "Note created successfully",
      noteId,
    });
  } catch (error) {
    console.error("[NoteController] Failed to create note:", error);
    res.status(500).json({ error: "Failed to create note" });
  }
}

/**
 * Convenience endpoint for testing or quick capture:
 * Parses the raw text note using Gemini and immediately commits it to Firestore
 * under users/{uid}/notes in a single request.
 */
export async function quickCreateNoteHandler(
  req: AuthRequest,
  res: Response,
): Promise<void> {
  const uid = req.uid;
  if (!uid) {
    res.status(401).json({ error: "User not authenticated" });
    return;
  }

  const parsed = QuickCreateNoteSchema.safeParse(req.body);
  if (!parsed.success) {
    res
      .status(400)
      .json({ error: `Invalid request body: ${parsed.error.message}` });
    return;
  }

  const timeZone = parsed.data.timeZone || "Asia/Colombo";
  const now = parsed.data.now || getCurrentLocalWallClock();
  const rawText = parsed.data.rawText;

  try {
    const parseResult = await parseNoteWithGemini(rawText, now, timeZone);

    const noteId = await createNote(uid, {
      rawText: rawText,
      taskDescription: parseResult.taskDescription,
      triggerType: parseResult.triggerType,
      locationKind: parseResult.locationKind,
      locationValue: parseResult.locationValue,
      resolvedDatetime: parseResult.resolvedDatetime,
      recurrenceRule: parseResult.recurrenceRule,
      confidence: parseResult.confidence,
      timeZone: timeZone,
    });

    res.status(201).json({
      success: true,
      message: "Note parsed and created successfully",
      noteId,
      parsed: parseResult,
    });
  } catch (error) {
    if (error instanceof AiParseError) {
      res.status(error.statusCode).json({ error: error.message });
      return;
    }
    console.error("[NoteController] Failed in quickCreateNote:", error);
    res.status(500).json({ error: "Failed to parse and create note" });
  }
}

