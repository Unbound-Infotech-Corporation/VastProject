import type { Express } from "express";
import type { Server } from "http";
import { z } from "zod";
import { api } from "@shared/routes";
import { requireOptimizeToken, tokenConfigured } from "./lib/auth";
import { collectSystemStatus } from "./lib/checks";
import { isSafeComponent, runSafeOptimize } from "./lib/optimizer";
import { mutationRateLimit } from "./lib/rateLimit";
import { storageReady } from "./storage";

const DOCS = {
  hostSetup: "https://cloud.vast.ai/host/setup/",
  hostingOverview: "https://docs.vast.ai/host/hosting-overview",
  verification: "https://docs.vast.ai/host/verification-stages",
  ssh: "https://docs.vast.ai/host/disable-ssh-password-login",
  kernel: "https://docs.vast.ai/host/upgrade-kernel",
  selfTest: "https://docs.vast.ai/host/how-to-self-test",
  docker: "https://docs.docker.com/engine/install/ubuntu/",
  nvidiaCtk:
    "https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html",
};

export async function registerRoutes(httpServer: Server, app: Express): Promise<Server> {
  const storage = await storageReady;

  app.get(api.meta.get.path, (_req, res) => {
    res.json({
      tokenRequired: tokenConfigured() || process.env.NODE_ENV === "production",
      docs: DOCS,
    });
  });

  app.get(api.status.get.path, async (_req, res) => {
    try {
      const status = await collectSystemStatus();
      res.json(status);
    } catch (err) {
      console.error(err);
      res.status(500).json({ message: "Failed to collect host status" });
    }
  });

  app.post(api.optimize.run.path, mutationRateLimit, requireOptimizeToken, async (req, res) => {
    const parsed = api.optimize.run.input.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({
        message:
          "Invalid input. Send { component: Storage|GPU|Docker|Network|All, confirm: true, dryRun?: boolean }. Disk wipe is never available via this API.",
      });
    }

    const { component, dryRun } = parsed.data;
    if (!isSafeComponent(component)) {
      return res.status(400).json({ message: "Component is not on the optimizer allowlist." });
    }

    if (component === "Storage" && !dryRun) {
      const log = await storage.createLog({
        component,
        status: "success",
        details:
          "Storage changes that format disks are blocked. Use scripts/host/prepare-docker-xfs.sh on the host with explicit wipe flags after identifying a spare device. This API only reports mount state.",
      });
      const status = await collectSystemStatus();
      return res.json({
        success: true,
        message: status.storage.message,
        logId: log.id,
        dryRun: false,
        output: status.storage.details.join("\n"),
      });
    }

    try {
      const result = await runSafeOptimize(component, { dryRun: Boolean(dryRun) });
      const log = await storage.createLog({
        component,
        status: result.ok ? "success" : "failed",
        details: result.output,
      });
      res.json({
        success: result.ok,
        message: result.ok
          ? `${component} allowlisted ${dryRun ? "dry-run" : "fix"} finished`
          : `${component} allowlisted fix failed`,
        logId: log.id,
        dryRun: Boolean(dryRun),
        output: result.output,
      });
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      try {
        await storage.createLog({
          component,
          status: "failed",
          details: message,
        });
      } catch {
        // ignore secondary log failure
      }
      if (err instanceof z.ZodError) {
        return res.status(400).json({ message: "Invalid input" });
      }
      res.status(500).json({ message: "Optimizer failed" });
    }
  });

  app.get(api.logs.list.path, async (_req, res) => {
    try {
      const logs = await storage.getLogs();
      res.json(logs);
    } catch (err) {
      console.error(err);
      res.status(500).json({ message: "Failed to fetch logs" });
    }
  });

  return httpServer;
}
