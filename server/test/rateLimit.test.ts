import { test } from "node:test";
import assert from "node:assert/strict";

import { createUidRateLimiter } from "../src/middleware/rateLimit";

/** Minimal stand-ins for Express req/res; enough for the middleware. */
function call(
  mw: ReturnType<typeof createUidRateLimiter>,
  uid: string | undefined,
): number {
  let status = 200;
  const res = {
    setHeader() {},
    status(code: number) {
      status = code;
      return { json() {} };
    },
  };
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  mw({ uid } as any, res as any, () => {});
  return status;
}

test("allows up to the limit, then returns 429", () => {
  const mw = createUidRateLimiter({ limit: 2, windowMs: 60_000, now: () => 0 });
  assert.equal(call(mw, "a"), 200);
  assert.equal(call(mw, "a"), 200);
  assert.equal(call(mw, "a"), 429);
});

test("limits each uid separately", () => {
  const mw = createUidRateLimiter({ limit: 1, windowMs: 60_000, now: () => 0 });
  assert.equal(call(mw, "a"), 200);
  assert.equal(call(mw, "b"), 200);
  assert.equal(call(mw, "a"), 429);
});

test("resets after the window", () => {
  let t = 0;
  const mw = createUidRateLimiter({ limit: 1, windowMs: 1000, now: () => t });
  assert.equal(call(mw, "a"), 200);
  assert.equal(call(mw, "a"), 429);
  t = 1000;
  assert.equal(call(mw, "a"), 200);
});

test("rejects a request with no uid", () => {
  const mw = createUidRateLimiter({ limit: 5, windowMs: 1000 });
  assert.equal(call(mw, undefined), 401);
});
