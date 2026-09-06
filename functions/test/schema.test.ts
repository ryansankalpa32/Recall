import assert from "node:assert/strict";
import { test } from "node:test";

import {
  ParseNoteRequestSchema,
  ParseResultSchema,
  toParsedNoteResponse,
} from "../src/schema";

test("a well-formed request validates", () => {
  const result = ParseNoteRequestSchema.safeParse({
    rawText: "call mum at 4pm",
    now: "2026-09-05T18:30:00",
    timeZone: "Asia/Colombo",
  });
  assert.equal(result.success, true);
});

test("a request is rejected when now carries a zone designator", () => {
  for (const now of ["2026-09-05T18:30:00Z", "2026-09-05T18:30:00+05:30", "2026-09-05"]) {
    const result = ParseNoteRequestSchema.safeParse({
      rawText: "call mum",
      now,
      timeZone: "Asia/Colombo",
    });
    assert.equal(result.success, false, `${now} should be rejected`);
  }
});

test("a request is rejected when rawText is blank or oversized", () => {
  const base = { now: "2026-09-05T18:30:00", timeZone: "Asia/Colombo" };
  assert.equal(ParseNoteRequestSchema.safeParse({ ...base, rawText: "   " }).success, false);
  assert.equal(
    ParseNoteRequestSchema.safeParse({ ...base, rawText: "x".repeat(1001) }).success,
    false,
  );
});

test("a time result validates and round-trips", () => {
  const result = ParseResultSchema.parse({
    taskDescription: "call mum",
    triggerType: "time",
    resolvedDatetime: "2026-09-06T16:00:00",
    confidence: 0.95,
  });

  assert.deepEqual(toParsedNoteResponse(result), {
    taskDescription: "call mum",
    triggerType: "time",
    locationKind: null,
    locationValue: null,
    resolvedDatetime: "2026-09-06T16:00:00",
    recurrenceRule: null,
    confidence: 0.95,
  });
});

test("a none result must carry a null datetime", () => {
  assert.equal(
    ParseResultSchema.safeParse({
      taskDescription: "buy shoes",
      triggerType: "none",
      resolvedDatetime: null,
      confidence: 0.9,
    }).success,
    true,
  );

  // The two fields must agree — these are the shapes structured output allows
  // but that would break the Dart side.
  assert.equal(
    ParseResultSchema.safeParse({
      taskDescription: "buy shoes",
      triggerType: "none",
      resolvedDatetime: "2026-09-06T16:00:00",
      confidence: 0.9,
    }).success,
    false,
  );
  assert.equal(
    ParseResultSchema.safeParse({
      taskDescription: "call mum",
      triggerType: "time",
      resolvedDatetime: null,
      confidence: 0.9,
    }).success,
    false,
  );
});

test("a resolved datetime carrying an offset is rejected", () => {
  assert.equal(
    ParseResultSchema.safeParse({
      taskDescription: "call mum",
      triggerType: "time",
      resolvedDatetime: "2026-09-06T16:00:00Z",
      confidence: 0.9,
    }).success,
    false,
  );
});

test("confidence outside 0..1 is rejected", () => {
  const base = {
    taskDescription: "call mum",
    triggerType: "time" as const,
    resolvedDatetime: "2026-09-06T16:00:00",
  };
  assert.equal(ParseResultSchema.safeParse({ ...base, confidence: 1.5 }).success, false);
  assert.equal(ParseResultSchema.safeParse({ ...base, confidence: -0.1 }).success, false);
});

test("lexicographic comparison orders same-format local datetimes", () => {
  // index.ts relies on this to reject a resolved time in the past.
  assert.ok("2026-09-05T18:29:00" < "2026-09-05T18:30:00");
  assert.ok("2026-09-06T00:00:00" > "2026-09-05T23:59:59");
});
