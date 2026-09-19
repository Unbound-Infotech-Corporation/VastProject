import { z } from "zod";
import {
  optimizeComponentSchema,
  optimizationLogs,
  systemStatusSchema,
} from "./schema";

export const errorSchemas = {
  internal: z.object({
    message: z.string(),
  }),
};

export const api = {
  health: {
    get: {
      method: "GET" as const,
      path: "/api/health" as const,
      responses: {
        200: z.object({
          ok: z.boolean(),
          service: z.string(),
          storageBackend: z.enum(["postgres", "memory"]),
          optimizeEnabled: z.boolean(),
        }),
      },
    },
  },
  status: {
    get: {
      method: "GET" as const,
      path: "/api/status" as const,
      responses: {
        200: systemStatusSchema,
      },
    },
  },
  optimize: {
    run: {
      method: "POST" as const,
      path: "/api/optimize" as const,
      input: z.object({
        component: optimizeComponentSchema,
      }),
      responses: {
        200: z.object({
          success: z.boolean(),
          message: z.string(),
          logId: z.number(),
          status: systemStatusSchema.optional(),
        }),
        403: errorSchemas.internal,
        429: errorSchemas.internal,
        500: errorSchemas.internal,
      },
    },
  },
  logs: {
    list: {
      method: "GET" as const,
      path: "/api/logs" as const,
      responses: {
        200: z.array(z.custom<typeof optimizationLogs.$inferSelect>()),
      },
    },
  },
};

export function buildUrl(path: string, params?: Record<string, string | number>): string {
  let url = path;
  if (params) {
    Object.entries(params).forEach(([key, value]) => {
      if (url.includes(`:${key}`)) {
        url = url.replace(`:${key}`, String(value));
      }
    });
  }
  return url;
}
