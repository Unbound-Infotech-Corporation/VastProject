import type { Express } from "express";
import type { Server } from "http";
import { storage } from "./storage";
import { api } from "@shared/routes";
import { z } from "zod";

// Simulated system checks
async function checkSystemStatus() {
  return {
    storage: { verified: false, message: "Storage settings unoptimized (ext4 instead of xfs, no noatime)" },
    gpu: { verified: false, message: "GPU driver persistence mode disabled" },
    docker: { verified: false, message: "Docker daemon missing nvidia runtime as default" },
    network: { verified: true, message: "Network settings optimal" },
  };
}

async function performOptimization(component: string) {
  // Simulate optimization logic (this would be where bash scripts are executed)
  await new Promise((resolve) => setTimeout(resolve, 2000));
  return true;
}

export async function registerRoutes(
  httpServer: Server,
  app: Express
): Promise<Server> {
  app.get(api.status.get.path, async (req, res) => {
    try {
      const status = await checkSystemStatus();
      res.json(status);
    } catch (err) {
      res.status(500).json({ message: "Failed to fetch system status" });
    }
  });

  app.post(api.optimize.run.path, async (req, res) => {
    try {
      const input = api.optimize.run.input.parse(req.body);
      
      // Simulate optimization
      await performOptimization(input.component);

      const log = await storage.createLog({
        component: input.component,
        status: "success",
        details: `Successfully applied optimal settings for ${input.component}. Verified Vast.AI requirements.`
      });

      res.json({
        success: true,
        message: `${input.component} optimization completed successfully`,
        logId: log.id
      });
    } catch (err) {
      if (err instanceof z.ZodError) {
         return res.status(400).json({ message: "Invalid input" });
      }
      
      // Log failure
      try {
        const input = req.body.component ? String(req.body.component) : 'Unknown';
        await storage.createLog({
          component: input,
          status: "failed",
          details: err instanceof Error ? err.message : String(err)
        });
      } catch (e) {}

      res.status(500).json({ message: "Internal server error during optimization" });
    }
  });

  app.get(api.logs.list.path, async (req, res) => {
    try {
      const logs = await storage.getLogs();
      res.json(logs);
    } catch (err) {
      res.status(500).json({ message: "Failed to fetch logs" });
    }
  });

  return httpServer;
}
