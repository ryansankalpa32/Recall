import { Response, NextFunction } from "express";
import { AuthRequest } from "./auth";

/**
 * Fixed-window, in-memory rate limit keyed by the authenticated uid.
 *
 * Runs after `authenticateUser`. It's per server process (fine for a single
 * instance); a multi-instance deploy would need a shared store.
 */
export function createUidRateLimiter(options: {
  limit: number;
  windowMs: number;
  now?: () => number;
}) {
  const { limit, windowMs, now = Date.now } = options;
  const windows = new Map<string, { start: number; count: number }>();

  return function uidRateLimit(
    req: AuthRequest,
    res: Response,
    next: NextFunction,
  ): void {
    const key = req.uid;
    if (!key) {
      res.status(401).json({ error: "User not authenticated" });
      return;
    }

    const t = now();
    const w = windows.get(key);
    if (!w || t - w.start >= windowMs) {
      windows.set(key, { start: t, count: 1 });
      next();
      return;
    }

    if (w.count >= limit) {
      const retryAfterSec = Math.ceil((w.start + windowMs - t) / 1000);
      res.setHeader("Retry-After", String(retryAfterSec));
      res.status(429).json({ error: "Too many requests. Try again shortly." });
      return;
    }

    w.count++;
    next();
  };
}
