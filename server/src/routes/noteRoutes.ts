import { Router } from "express";
import { authenticateUser } from "../middleware/auth";
import { createNoteHandler } from "../controllers/noteController";

const router = Router();

/** POST /api/notes — save a new note/reminder to Firestore. */
router.post("/notes", authenticateUser, createNoteHandler);

export default router;
