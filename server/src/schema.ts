import { z } from "zod";

/**
 * ISO-8601 local wall-clock, no offset and no trailing `Z`.
 *
 * The Flutter client parses this with `DateTime.parse`, which yields a *local*
 * `DateTime` only when there is no zone designator — and `SchedulingService`
 * then hands that to `tz.TZDateTime.from(..., tz.local)`. A stray `Z` would
 * silently shift every reminder by the device's UTC offset, so it is rejected
 * here rather than debugged later.
 */
export const LOCAL_DATETIME_RE = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$/;

/** Request body of the `parseNote` callable. */
export const ParseNoteRequestSchema = z.object({
  /** Bounded to keep a single call's token cost predictable. */
  rawText: z.string().trim().min(1).max(1000),
  now: z.string().regex(LOCAL_DATETIME_RE, "now must be ISO-8601 local, no offset"),
  /** IANA zone, e.g. `Asia/Colombo`. Passed to the model as context only. */
  timeZone: z.string().min(1).max(64),
});

export type ParseNoteRequest = z.infer<typeof ParseNoteRequestSchema>;

/**
 * What the model is asked to produce — deliberately *narrower* than
 * `ParsedNote` on the Dart side.
 *
 * `locationKind` / `locationValue` are absent because Phase 2 is time
 * intelligence only (see Claude.md's build order); leaving them out of the
 * schema means the model structurally cannot emit a location trigger, which is
 * a stronger guarantee than instructing it not to. `recurrenceRule` is absent
 * for the same reason — `SchedulingService` has no recurrence support until
 * Phase 8, and storing an RRULE we would not honour is worse than dropping it.
 *
 * The callable fills all three in as `null` when it builds the response.
 */
export const PARSE_RESULT_JSON_SCHEMA = {
  type: "object",
  properties: {
    taskDescription: {
      type: "string",
      description:
        "The task, with the time expression removed. 'call mum at 4pm' -> 'call mum'.",
    },
    triggerType: {
      type: "string",
      enum: ["time", "none"],
      description:
        "'time' when the note contains a resolvable time expression, otherwise 'none'.",
    },
    resolvedDatetime: {
      anyOf: [{ type: "string" }, { type: "null" }],
      description:
        "ISO-8601 local wall-clock (YYYY-MM-DDTHH:mm:ss), no offset, no 'Z'. " +
        "Null when triggerType is 'none'. Must be strictly after the supplied current time.",
    },
    confidence: {
      type: "number",
      description:
        "0..1 confidence in this interpretation. Low when the time expression is vague or ambiguous.",
    },
  },
  required: ["taskDescription", "triggerType", "resolvedDatetime", "confidence"],
} as const;

/**
 * Validator for what actually comes back. Hand-written rather than derived
 * from the JSON Schema above so the datetime format and the
 * triggerType/resolvedDatetime agreement are enforced properly — a structured
 * output is schema-shaped, not necessarily semantically correct.
 */
export const ParseResultSchema = z
  .object({
    taskDescription: z.string().trim().min(1),
    triggerType: z.enum(["time", "none"]),
    resolvedDatetime: z.string().regex(LOCAL_DATETIME_RE).nullable(),
    confidence: z.number().min(0).max(1),
  })
  .refine(
    (v) => (v.triggerType === "time") === (v.resolvedDatetime !== null),
    "triggerType 'time' requires a resolvedDatetime, and 'none' requires null",
  );

export type ParseResult = z.infer<typeof ParseResultSchema>;

/** The wire shape the Flutter `ParsedNote` is built from. */
export interface ParsedNoteResponse {
  taskDescription: string;
  triggerType: "time" | "none";
  locationKind: null;
  locationValue: null;
  resolvedDatetime: string | null;
  recurrenceRule: null;
  confidence: number;
}

export function toParsedNoteResponse(result: ParseResult): ParsedNoteResponse {
  return {
    taskDescription: result.taskDescription,
    triggerType: result.triggerType,
    locationKind: null,
    locationValue: null,
    resolvedDatetime: result.resolvedDatetime,
    recurrenceRule: null,
    confidence: result.confidence,
  };
}
