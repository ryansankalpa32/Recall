import "dotenv/config";

import express from "express";
import cors from "cors";

import { ParseNoteRequestSchema } from "./schema";
import { parseNoteWithGemini, AiParseError } from "./services/aiService";
import noteRoutes from "./routes/noteRoutes";
import fcmRoutes from "./routes/fcmRoutes";
import { startReminderScheduler } from "./jobs/reminderScheduler";

const PORT = parseInt(process.env.PORT ?? "5001", 10);

const geminiApiKey = process.env.GEMINI_API_KEY;
if (!geminiApiKey) {
  console.error("GEMINI_API_KEY is not set in the environment. Exiting.");
  process.exit(1);
}

const app = express();
app.use(cors());
app.use(express.json());

app.use("/api", noteRoutes);
app.use("/api", fcmRoutes);

/** Health check — handy for uptime monitors on Render / Railway. */
app.get("/", (_req, res) => {
  res.json({ status: "ok", service: "recall-server" });
});

/**
 * Parses one free-text note into a reminder trigger.
 *
 * Phase 2 is time intelligence only — the response's location fields are always
 * null (see `schema.ts` for why the model is never even asked for them).
 *
 * Every failure path returns an error status, and the Flutter client degrades to
 * the manual date/time picker rather than saving a guess. Returning a
 * low-confidence or half-parsed note would violate Claude.md's "show before
 * commit" rule the moment the user tapped Confirm on something we were not
 * actually sure of.
 */
app.post("/parse-note", async (req, res) => {
  const parsedRequest = ParseNoteRequestSchema.safeParse(req.body);
  if (!parsedRequest.success) {
    res.status(400).json({
      error: `Malformed parseNote request: ${parsedRequest.error.message}`,
    });
    return;
  }
  const { rawText, now, timeZone } = parsedRequest.data;

  try {
    const result = await parseNoteWithGemini(rawText, now, timeZone);
    res.json(result);
  } catch (error) {
    if (error instanceof AiParseError) {
      res.status(error.statusCode).json({ error: error.message });
      return;
    }
    console.error("Unexpected error in /parse-note:", error);
    res.status(503).json({ error: "The note could not be interpreted." });
  }
});

app.listen(PORT, () => {
  console.log(`recall-server listening on http://localhost:${PORT}`);
  startReminderScheduler();
});
