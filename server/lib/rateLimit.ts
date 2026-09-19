import type { Request, Response, NextFunction } from "express";

type Bucket = { count: number; resetAt: number };

const buckets = new Map<string, Bucket>();
const WINDOW_MS = 60_000;
const MAX_MUTATIONS = 10;

export function mutationRateLimit(req: Request, res: Response, next: NextFunction): void {
  if (req.method === "GET" || req.method === "HEAD") {
    next();
    return;
  }
  const key = req.ip ?? "unknown";
  const now = Date.now();
  const existing = buckets.get(key);
  if (!existing || existing.resetAt < now) {
    buckets.set(key, { count: 1, resetAt: now + WINDOW_MS });
    next();
    return;
  }
  existing.count += 1;
  if (existing.count > MAX_MUTATIONS) {
    res.status(429).json({ message: "Too many optimizer requests. Wait a minute and retry." });
    return;
  }
  next();
}
