import { createUidRateLimiter } from "./rateLimit";

/**
 * One shared budget per user across every route that calls Gemini
 * (`/parse-note` and `/api/notes/quick-create`).
 */
export const geminiRateLimit = createUidRateLimiter({
  limit: 20,
  windowMs: 60_000,
});
