import { pgTable, text, serial, timestamp, boolean } from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod";

export const optimizationLogs = pgTable("optimization_logs", {
  id: serial("id").primaryKey(),
  component: text("component").notNull(), // 'Storage', 'GPU', 'Docker', 'Network', 'All'
  status: text("status").notNull(), // 'success', 'failed', 'running'
  details: text("details"),
  createdAt: timestamp("created_at").defaultNow(),
});

export const insertOptimizationLogSchema = createInsertSchema(optimizationLogs).omit({
  id: true,
  createdAt: true
});

export type OptimizationLog = typeof optimizationLogs.$inferSelect;
export type InsertOptimizationLog = z.infer<typeof insertOptimizationLogSchema>;

export interface SystemStatusResponse {
  storage: { verified: boolean; message: string };
  gpu: { verified: boolean; message: string };
  docker: { verified: boolean; message: string };
  network: { verified: boolean; message: string };
}

export type OptimizeRequest = {
  component: 'Storage' | 'GPU' | 'Docker' | 'Network' | 'All';
};

export type OptimizeResponse = {
  success: boolean;
  message: string;
  logId: number;
};
