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

export const componentStatusSchema = z.object({
  verified: z.boolean(),
  message: z.string(),
});

export type ComponentStatus = z.infer<typeof componentStatusSchema>;

export const systemStatusSchema = z.object({
  storage: componentStatusSchema,
  gpu: componentStatusSchema,
  docker: componentStatusSchema,
  network: componentStatusSchema,
  os: componentStatusSchema,
  vast: componentStatusSchema,
});

export type SystemStatusResponse = z.infer<typeof systemStatusSchema>;

export const optimizeComponentSchema = z.enum([
  "Storage",
  "GPU",
  "Docker",
  "Network",
  "All",
]);

export type OptimizeRequest = {
  component: z.infer<typeof optimizeComponentSchema>;
};

export type OptimizeResponse = {
  success: boolean;
  message: string;
  logId: number;
  status?: SystemStatusResponse;
};
