import { Router } from "express";
import { authenticateUser } from "../middleware/auth";
import {
  createNoteHandler,
  quickCreateNoteHandler,
} from "../controllers/noteController";

const router = Router();

/** POST /api/notes — save an existing/parsed note to Firestore. */
router.post("/notes", authenticateUser, createNoteHandler);

/** POST /api/notes/quick-create — parse free-text via Gemini and save to Firestore in one step. */
router.post("/notes/quick-create", authenticateUser, quickCreateNoteHandler);

export default router;

