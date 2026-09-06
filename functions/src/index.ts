import { GoogleGenAI } from "@google/genai";
import { defineSecret } from "firebase-functions/params";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

import { SYSTEM_INSTRUCTION } from "./prompt";
import {
  PARSE_RESULT_JSON_SCHEMA,
  ParseNoteRequestSchema,
  ParseResultSchema,
  toParsedNoteResponse,
} from "./schema";

/**
 * Held in Cloud Secret Manager, injected at runtime. This is the whole point of
 * the proxy: per Claude.md, no LLM key ever ships in the Flutter app.
 */
const geminiKey = defineSecret("GEMINI_API_KEY");

/**
 * Latest stable Flash. The today/tomorrow arithmetic wants a little reasoning,
 * so this rather than a lite variant; `gemini-3.5-flash-lite` is the cost
 * step-down if call volume ever justifies it.
 */
const MODEL = "gemini-3.8-flash";

/**
 * Parses one free-text note into a reminder trigger.
 *
 * Phase 2 is time intelligence only — the response's location fields are always
 * null (see `schema.ts` for why the model is never even asked for them).
 *
 * Every failure path throws, and the Flutter client degrades to the manual
 * date/time picker rather than saving a guess. Returning a low-confidence or
 * half-parsed note would violate Claude.md's "show before commit" rule the
 * moment the user tapped Confirm on something we were not actually sure of.
 */
export const parseNote = onCall(
  {
    region: "us-central1",
    secrets: [geminiKey],
    // Without this the endpoint is an open, paid Gemini relay for anyone who
    // finds the URL.
    enforceAppCheck: true,
    timeoutSeconds: 30,
  },
  async (request) => {
    const parsedRequest = ParseNoteRequestSchema.safeParse(request.data);
    if (!parsedRequest.success) {
      // Reject before spending a token.
      throw new HttpsError(
        "invalid-argument",
        `Malformed parseNote request: ${parsedRequest.error.message}`,
      );
    }
    const { rawText, now, timeZone } = parsedRequest.data;

    const client = new GoogleGenAI({ apiKey: geminiKey.value() });

    let outputText = "";
    try {
      const interaction = await client.interactions.create({
        model: MODEL,
        system_instruction: SYSTEM_INSTRUCTION,
        input: `Current local time: ${now}\nTimezone: ${timeZone}\nNote: ${rawText}`,
        generation_config: { thinking_level: "low", max_output_tokens: 512 },
        // These are two separate top-level fields on the Interactions API —
        // `response_mime_type` is required whenever `response_format` is set.
        response_format: PARSE_RESULT_JSON_SCHEMA,
        response_mime_type: "application/json",
      });

      if (interaction.status !== "completed") {
        logger.warn("Interaction did not complete", { status: interaction.status });
      }
      for (const block of interaction.outputs ?? []) {
        if (block.type === "text") outputText += block.text;
      }
    } catch (error) {
      logger.error("Gemini call failed", { error });
      throw new HttpsError("unavailable", "Could not reach the parsing service.");
    }

    // A safety block or an incomplete interaction yields no text blocks rather
    // than an exception.
    if (outputText.trim().length === 0) {
      logger.warn("Gemini returned no output text", { rawText });
      throw new HttpsError("unavailable", "The note could not be interpreted.");
    }

    let result;
    try {
      result = ParseResultSchema.parse(JSON.parse(outputText));
    } catch (error) {
      logger.warn("Gemini output failed validation", { outputText, error });
      throw new HttpsError("unavailable", "The note could not be interpreted.");
    }

    // Structured output guarantees the shape, not the semantics — the model can
    // still hand back a time that has already passed, which would schedule a
    // notification that fires immediately or never.
    if (result.resolvedDatetime !== null && result.resolvedDatetime <= now) {
      logger.warn("Gemini resolved a datetime in the past", {
        rawText,
        now,
        resolved: result.resolvedDatetime,
      });
      throw new HttpsError("unavailable", "The note could not be interpreted.");
    }

    return toParsedNoteResponse(result);
  },
);
