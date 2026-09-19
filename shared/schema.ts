import { pgTable, text, serial, timestamp } from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod";

export const optimizationLogs = pgTable("optimization_logs", {
  id: serial("id").primaryKey(),
  component: text("component").notNull(),
  status: text("status").notNull(),
  details: text("details"),
  createdAt: timestamp("created_at").defaultNow(),
});

export const insertOptimizationLogSchema = createInsertSchema(optimizationLogs).omit({
  id: true,
  createdAt: true,
});

export type OptimizationLog = typeof optimizationLogs.$inferSelect;
export type InsertOptimizationLog = z.infer<typeof insertOptimizationLogSchema>;

export const componentCheckSchema = z.object({
  verified: z.boolean(),
  message: z.string(),
  severity: z.enum(["ok", "warn", "fail", "unknown"]),
  details: z.array(z.string()),
});

export const systemStatusSchema = z.object({
  storage: componentCheckSchema,
  gpu: componentCheckSchema,
  docker: componentCheckSchema,
  network: componentCheckSchema,
  os: componentCheckSchema,
  host: componentCheckSchema,
  ssh: componentCheckSchema,
  readiness: z.object({
    ready: z.boolean(),
    blockers: z.array(z.string()),
    warnings: z.array(z.string()),
  }),
});

export type SystemStatusResponse = z.infer<typeof systemStatusSchema>;

export const optimizeRequestSchema = z.object({
  component: z.enum(["Storage", "GPU", "Docker", "Network", "All"]),
  confirm: z.literal(true),
  dryRun: z.boolean().optional().default(false),
});

export type OptimizeRequest = z.infer<typeof optimizeRequestSchema>;

export const optimizeResponseSchema = z.object({
  success: z.boolean(),
  message: z.string(),
  logId: z.number(),
  dryRun: z.boolean(),
  output: z.string(),
});

export type OptimizeResponse = z.infer<typeof optimizeResponseSchema>;
