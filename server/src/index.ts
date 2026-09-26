import "dotenv/config";

import express from "express";
import cors from "cors";
import { GoogleGenAI } from "@google/genai";

import { SYSTEM_INSTRUCTION } from "./prompt";
import {
  PARSE_RESULT_JSON_SCHEMA,
  ParseNoteRequestSchema,
  ParseResultSchema,
  toParsedNoteResponse,
} from "./schema";
import noteRoutes from "./routes/noteRoutes";
import fcmRoutes from "./routes/fcmRoutes";
import { startReminderScheduler } from "./jobs/reminderScheduler";

const PORT = parseInt(process.env.PORT ?? "5001", 10);

const geminiApiKey = process.env.GEMINI_API_KEY;
if (!geminiApiKey) {
  console.error("GEMINI_API_KEY is not set in the environment. Exiting.");
  process.exit(1);
}

/**
 * Latest stable Flash. The today/tomorrow arithmetic wants a little reasoning,
 * so this rather than a lite variant; `gemini-3.5-flash-lite` is the cost
 * step-down if call volume ever justifies it.
 */
const MODEL = "gemini-3.5-flash-lite";

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

  const client = new GoogleGenAI({ apiKey: geminiApiKey });

  let outputText = "";
  try {
    const interaction = await client.interactions.create({
      model: MODEL,
      system_instruction: SYSTEM_INSTRUCTION,
      input: `Current local time: ${now}\nTimezone: ${timeZone}\nNote: ${rawText}`,
      generation_config: { thinking_level: "low", max_output_tokens: 512 },
      // Unified `response_format` — @google/genai v2 replaced the old split
      // `response_format` + `response_mime_type` pair, and the server now
      // rejects the v1 shape outright ("legacy Interactions API schema").
      response_format: {
        type: "text",
        mime_type: "application/json",
        schema: PARSE_RESULT_JSON_SCHEMA,
      },
    });

    if (interaction.status !== "completed") {
      console.warn("Interaction did not complete", { status: interaction.status });
    }
    outputText = interaction.output_text ?? "";
  } catch (error) {
    console.error("Gemini call failed", { error });
    res.status(503).json({ error: "Could not reach the parsing service." });
    return;
  }

  // A safety block or an incomplete interaction yields no text blocks rather
  // than an exception.
  if (outputText.trim().length === 0) {
    console.warn("Gemini returned no output text", { rawText });
    res.status(503).json({ error: "The note could not be interpreted." });
    return;
  }

  let result;
  try {
    result = ParseResultSchema.parse(JSON.parse(outputText));
  } catch (error) {
    console.warn("Gemini output failed validation", { outputText, error });
    res.status(503).json({ error: "The note could not be interpreted." });
    return;
  }

  // Structured output guarantees the shape, not the semantics — the model can
  // still hand back a time that has already passed, which would schedule a
  // notification that fires immediately or never.
  if (result.resolvedDatetime !== null && result.resolvedDatetime <= now) {
    console.warn("Gemini resolved a datetime in the past", {
      rawText,
      now,
      resolved: result.resolvedDatetime,
    });
    res.status(503).json({ error: "The note could not be interpreted." });
    return;
  }

  res.json(toParsedNoteResponse(result));
});

app.listen(PORT, () => {
  console.log(`recall-server listening on http://localhost:${PORT}`);
  startReminderScheduler();
});
