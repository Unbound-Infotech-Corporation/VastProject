import type { Request, Response, NextFunction } from "express";
import { timingSafeEqual } from "node:crypto";

const MUTATING_METHODS = new Set(["POST", "PUT", "PATCH", "DELETE"]);

function readBearer(req: Request): string | undefined {
  const header = req.header("authorization");
  if (header?.toLowerCase().startsWith("bearer ")) {
    return header.slice(7).trim();
  }
  const queryToken = req.query.token;
  if (typeof queryToken === "string" && queryToken.length > 0) {
    return queryToken;
  }
  return undefined;
}

function safeEqual(a: string, b: string): boolean {
  const left = Buffer.from(a);
  const right = Buffer.from(b);
  if (left.length !== right.length) {
    return false;
  }
  return timingSafeEqual(left, right);
}

export function requireOptimizeToken(req: Request, res: Response, next: NextFunction): void {
  if (!MUTATING_METHODS.has(req.method)) {
    next();
    return;
  }

  const expected = process.env.OPTIMIZER_API_TOKEN;
  if (!expected) {
    if (process.env.NODE_ENV === "production") {
      res.status(403).json({
        message:
          "Mutating optimizer APIs are disabled until OPTIMIZER_API_TOKEN is set. This prevents unauthenticated host changes.",
      });
      return;
    }
    next();
    return;
  }

  const provided = readBearer(req);
  if (!provided || !safeEqual(provided, expected)) {
    res.status(401).json({ message: "Unauthorized: valid optimizer token required" });
    return;
  }
  next();
}

export function tokenConfigured(): boolean {
  return Boolean(process.env.OPTIMIZER_API_TOKEN);
}
