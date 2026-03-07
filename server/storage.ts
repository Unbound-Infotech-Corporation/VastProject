import { db } from "./db";
import { optimizationLogs, type InsertOptimizationLog, type OptimizationLog } from "@shared/schema";
import { desc } from "drizzle-orm";

export interface IStorage {
  getLogs(): Promise<OptimizationLog[]>;
  createLog(log: InsertOptimizationLog): Promise<OptimizationLog>;
}

export class DatabaseStorage implements IStorage {
  async getLogs(): Promise<OptimizationLog[]> {
    return await db.select().from(optimizationLogs).orderBy(desc(optimizationLogs.createdAt));
  }

  async createLog(log: InsertOptimizationLog): Promise<OptimizationLog> {
    const [inserted] = await db.insert(optimizationLogs).values(log).returning();
    return inserted;
  }
}

export const storage = new DatabaseStorage();
