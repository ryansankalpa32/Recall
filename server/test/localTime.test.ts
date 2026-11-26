import { test } from "node:test";
import assert from "node:assert/strict";

import { localWallClockToUtc } from "../src/localTime";

const iso = (d: Date) => d.toISOString();

test("Asia/Colombo is UTC+05:30", () => {
  assert.equal(
    iso(localWallClockToUtc("2026-09-25T15:00:00", "Asia/Colombo")),
    "2026-09-25T09:30:00.000Z",
  );
});

test("UTC is unchanged", () => {
  assert.equal(
    iso(localWallClockToUtc("2026-01-01T00:00:00", "UTC")),
    "2026-01-01T00:00:00.000Z",
  );
});

test("America/New_York uses EST in winter and EDT in summer", () => {
  assert.equal(
    iso(localWallClockToUtc("2026-01-15T09:00:00", "America/New_York")),
    "2026-01-15T14:00:00.000Z",
  );
  assert.equal(
    iso(localWallClockToUtc("2026-07-15T09:00:00", "America/New_York")),
    "2026-07-15T13:00:00.000Z",
  );
});

test("Times next to a DST transition resolve correctly", () => {
  // US spring-forward 2026-03-08 at 02:00 local. 01:30 is still EST,
  // 03:30 is already EDT.
  assert.equal(
    iso(localWallClockToUtc("2026-03-08T01:30:00", "America/New_York")),
    "2026-03-08T06:30:00.000Z",
  );
  assert.equal(
    iso(localWallClockToUtc("2026-03-08T03:30:00", "America/New_York")),
    "2026-03-08T07:30:00.000Z",
  );
});

test("Rejects an unknown zone instead of guessing", () => {
  assert.throws(() => localWallClockToUtc("2026-01-01T00:00:00", "Mars/Base"));
});

test("Rejects a datetime with an offset or Z", () => {
  assert.throws(() => localWallClockToUtc("2026-01-01T00:00:00Z", "UTC"));
  assert.throws(() =>
    localWallClockToUtc("2026-01-01T00:00:00+05:30", "Asia/Colombo"),
  );
});
