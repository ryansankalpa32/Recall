import { createUidRateLimiter } from "./rateLimit";

/** Per-user budget for routes that call Gemini (`/parse-note`). */
export const geminiRateLimit = createUidRateLimiter({
  limit: 20,
  windowMs: 60_000,
});
