import { Response } from "express";
import { z } from "zod";
import { AuthRequest } from "../middleware/auth";
import { createNote } from "../services/noteService";

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
