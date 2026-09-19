import type { Express, Request, Response } from "express";
import type { Server } from "http";
import { storage, storageBackend } from "./storage";
import { api } from "@shared/routes";
import { z } from "zod";
import {
  collectHostStatus,
  runOptimization,
  summarizeStatus,
} from "./hostChecks";

const optimizeEnabled = process.env.ALLOW_OPTIMIZE === "true";
const optimizeToken = process.env.OPTIMIZE_TOKEN ?? "";

let optimizeBusy = false;
const optimizeHits: number[] = [];
const OPTIMIZE_WINDOW_MS = 60_000;
const OPTIMIZE_MAX_PER_WINDOW = 8;

function clientIp(req: Request): string {
  return req.socket.remoteAddress ?? "";
}

function isLoopback(req: Request): boolean {
  const ip = clientIp(req);
  return ip === "127.0.0.1" || ip === "::1" || ip === ":ffff:127.0.0.1";
}

function allowOptimize(req: Request, res: Response): boolean {
  if (!optimizeEnabled) {
    res.status(403).json({
      message:
        "Optimizations are disabled. Set ALLOW_OPTIMIZE=true in .env to enable safe one-click fixes.",
    });
    return false;
  }

  if (optimizeToken) {
    const header = req.get("x-optimize-token") ?? "";
    if (header !== optimizeToken) {
      res.status(403).json({ message: "Missing or invalid X-Optimize-Token." });
      return false;
    }
  } else if (process.env.ALLOW_REMOTE_OPTIMIZE !== "true" && !isLoopback(req)) {
    res.status(403).json({
      message:
        "Optimize is limited to localhost unless ALLOW_REMOTE_OPTIMIZE=true or OPTIMIZE_TOKEN is set.",
    });
    return false;
  }

  const now = Date.now();
  while (optimizeHits.length && now - optimizeHits[0] > OPTIMIZE_WINDOW_MS) {
    optimizeHits.shift();
  }
  if (optimizeHits.length >= OPTIMIZE_MAX_PER_WINDOW) {
    res.status(429).json({ message: "Too many optimize requests. Try again in a minute." });
    return false;
  }
  optimizeHits.push(now);
  return true;
}

export async function registerRoutes(
  httpServer: Server,
  app: Express
): Promise<Server> {
  app.get(api.health.get.path, (_req, res) => {
    res.json({
      ok: true,
      service: "vast-host-setup",
      storageBackend,
      optimizeEnabled,
    });
  });

  app.get(api.status.get.path, async (_req, res) => {
    try {
      const status = await collectHostStatus();
      res.json(status);
    } catch (err) {
      console.error("status check failed", err);
      res.status(500).json({ message: "Failed to fetch system status" });
    }
  });

  app.post(api.optimize.run.path, async (req, res) => {
    if (!allowOptimize(req, res)) {
      return;
    }
    if (optimizeBusy) {
      return res.status(429).json({ message: "An optimization is already running." });
    }

    try {
      const input = api.optimize.run.input.parse(req.body);
      optimizeBusy = true;

      const result = await runOptimization(input.component, true);
      const success = result.code === 0;
      const details = [
        success
          ? `Applied safe ${input.component} settings (no disk wipe).`
          : `Optimization exited with code ${result.code}.`,
        summarizeStatus(result.status),
        result.stderr.trim() ? `stderr:\n${result.stderr.trim()}` : "",
      ]
        .filter(Boolean)
        .join("\n\n");

      const log = await storage.createLog({
        component: input.component,
        status: success ? "success" : "failed",
        details,
      });

      res.status(success ? 200 : 500).json({
        success,
        message: success
          ? `${input.component} optimization completed`
          : `${input.component} optimization failed`,
        logId: log.id,
        status: result.status,
      });
    } catch (err) {
      if (err instanceof z.ZodError) {
        return res.status(400).json({ message: "Invalid input" });
      }

      try {
        const component = req.body?.component ? String(req.body.component) : "Unknown";
        await storage.createLog({
          component,
          status: "failed",
          details: err instanceof Error ? err.message : String(err),
        });
      } catch {
        // ignore secondary log failures
      }

      res.status(500).json({
        message: err instanceof Error ? err.message : "Internal server error during optimization",
      });
    } finally {
      optimizeBusy = false;
    }
  });

  app.get(api.logs.list.path, async (_req, res) => {
    try {
      const logs = await storage.getLogs();
      res.json(logs);
    } catch (err) {
      console.error("logs failed", err);
      res.status(500).json({ message: "Failed to fetch logs" });
    }
  });

  return httpServer;
}
