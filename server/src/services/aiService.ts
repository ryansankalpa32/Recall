import { GoogleGenAI } from "@google/genai";
import { SYSTEM_INSTRUCTION } from "../prompt";
import {
  PARSE_RESULT_JSON_SCHEMA,
  ParseResultSchema,
  toParsedNoteResponse,
  ParsedNoteResponse,
} from "../schema";

const MODEL = "gemini-3.5-flash-lite";

export class AiParseError extends Error {
  constructor(
    message: string,
    public statusCode: number = 503,
  ) {
    super(message);
    this.name = "AiParseError";
  }
}

/**
 * Parses a free-text note into a structured reminder trigger using Gemini.
 *
 * Enforces:
 * - Structured JSON output format
 * - Validation against ParseResultSchema
 * - Resolved datetime strictly after current time `now`
 */
export async function parseNoteWithGemini(
  rawText: string,
  now: string,
  timeZone: string,
): Promise<ParsedNoteResponse> {
  const geminiApiKey = process.env.GEMINI_API_KEY;
  if (!geminiApiKey) {
    throw new AiParseError("GEMINI_API_KEY is not configured", 500);
  }

  const client = new GoogleGenAI({ apiKey: geminiApiKey });

  let outputText = "";
  try {
    const interaction = await client.interactions.create({
      model: MODEL,
      system_instruction: SYSTEM_INSTRUCTION,
      input: `Current local time: ${now}\nTimezone: ${timeZone}\nNote: ${rawText}`,
      generation_config: { thinking_level: "low", max_output_tokens: 512 },
      response_format: {
        type: "text",
        mime_type: "application/json",
        schema: PARSE_RESULT_JSON_SCHEMA,
      },
    });

    if (interaction.status !== "completed") {
      console.warn("Interaction did not complete", {
        status: interaction.status,
      });
    }
    outputText = interaction.output_text ?? "";
  } catch (error) {
    console.error("Gemini call failed", { error });
    throw new AiParseError("Could not reach the parsing service.", 503);
  }

  if (outputText.trim().length === 0) {
    console.warn("Gemini returned no output text", { rawText });
    throw new AiParseError("The note could not be interpreted.", 503);
  }

  let result;
  try {
    result = ParseResultSchema.parse(JSON.parse(outputText));
  } catch (error) {
    console.warn("Gemini output failed validation", { outputText, error });
    throw new AiParseError("The note could not be interpreted.", 503);
  }

  if (result.resolvedDatetime !== null && result.resolvedDatetime <= now) {
    console.warn("Gemini resolved a datetime in the past", {
      rawText,
      now,
      resolved: result.resolvedDatetime,
    });
    throw new AiParseError(
      "The note could not be interpreted (resolved in the past).",
      503,
    );
  }

  return toParsedNoteResponse(result);
}
