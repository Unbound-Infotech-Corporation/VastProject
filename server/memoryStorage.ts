import type { InsertOptimizationLog, OptimizationLog } from "@shared/schema";

export class MemoryStorage {
  private logs: OptimizationLog[] = [];
  private nextId = 1;

  async getLogs(): Promise<OptimizationLog[]> {
    return [...this.logs].sort((a, b) => {
      const at = a.createdAt?.getTime() ?? 0;
      const bt = b.createdAt?.getTime() ?? 0;
      return bt - at;
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
    this.logs.unshift(inserted);
    this.logs = this.logs.slice(0, 200);
    return inserted;
  }
}
