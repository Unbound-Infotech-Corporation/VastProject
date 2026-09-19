import { optimizationLogs, type InsertOptimizationLog, type OptimizationLog } from "@shared/schema";
import { desc } from "drizzle-orm";

export interface IStorage {
  getLogs(): Promise<OptimizationLog[]>;
  createLog(log: InsertOptimizationLog): Promise<OptimizationLog>;
}

class MemoryStorage implements IStorage {
  private rows: OptimizationLog[] = [];
  private nextId = 1;

  async getLogs(): Promise<OptimizationLog[]> {
    return [...this.rows].sort((a, b) => {
      const aTime = a.createdAt?.getTime() ?? 0;
      const bTime = b.createdAt?.getTime() ?? 0;
      return bTime - aTime;
    });
  }

  async createLog(log: InsertOptimizationLog): Promise<OptimizationLog> {
    const inserted: OptimizationLog = {
      id: this.nextId++,
      component: log.component,
      status: log.status,
      details: log.details ?? null,
      createdAt: new Date(),
    };
    this.rows.unshift(inserted);
    return inserted;
  }
}

class DatabaseStorage implements IStorage {
  constructor(private readonly db: ReturnType<typeof import("drizzle-orm/node-postgres").drizzle>) {}

  async getLogs(): Promise<OptimizationLog[]> {
    return await this.db.select().from(optimizationLogs).orderBy(desc(optimizationLogs.createdAt));
  }

  async createLog(log: InsertOptimizationLog): Promise<OptimizationLog> {
    const [inserted] = await this.db.insert(optimizationLogs).values(log).returning();
    if (!inserted) {
      throw new Error("Failed to insert optimization log");
    }
    return inserted;
  }
}

async function createStorage(): Promise<IStorage> {
  if (!process.env.DATABASE_URL) {
    console.warn("DATABASE_URL unset — using in-memory optimization logs.");
    return new MemoryStorage();
  }
  try {
    const { db } = await import("./db");
    return new DatabaseStorage(db);
  } catch (error) {
    console.warn("Database unavailable, falling back to memory logs:", error);
    return new MemoryStorage();
  }
}

export const storageReady = createStorage();
