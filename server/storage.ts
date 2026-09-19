import { optimizationLogs, type InsertOptimizationLog, type OptimizationLog } from "@shared/schema";
import { desc } from "drizzle-orm";
import { db } from "./db";
import { MemoryStorage } from "./memoryStorage";

export interface IStorage {
  getLogs(): Promise<OptimizationLog[]>;
  createLog(log: InsertOptimizationLog): Promise<OptimizationLog>;
}

export class DatabaseStorage implements IStorage {
  async getLogs(): Promise<OptimizationLog[]> {
    if (!db) {
      throw new Error("DATABASE_URL is not configured");
    }
    return await db.select().from(optimizationLogs).orderBy(desc(optimizationLogs.createdAt));
  }

  async createLog(log: InsertOptimizationLog): Promise<OptimizationLog> {
    if (!db) {
      throw new Error("DATABASE_URL is not configured");
    }
    const [inserted] = await db.insert(optimizationLogs).values(log).returning();
    return inserted;
  }
}

export const storageBackend: "postgres" | "memory" = db ? "postgres" : "memory";
export const storage: IStorage = db ? new DatabaseStorage() : new MemoryStorage();
