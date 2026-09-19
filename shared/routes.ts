import { z } from "zod";
import { optimizationLogs, optimizeRequestSchema, optimizeResponseSchema, systemStatusSchema } from "./schema";

export const errorSchemas = {
  internal: z.object({
    message: z.string(),
  }),
};

const logRow = z.object({
  id: z.number(),
  component: z.string(),
  status: z.string(),
  details: z.string().nullable().optional(),
  createdAt: z.union([z.string(), z.date(), z.null()]).optional(),
});

export const api = {
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
      input: optimizeRequestSchema,
      responses: {
        200: optimizeResponseSchema,
        500: errorSchemas.internal,
      },
    },
  },
  logs: {
    list: {
      method: "GET" as const,
      path: "/api/logs" as const,
      responses: {
        200: z.array(logRow),
      },
    },
  },
  meta: {
    get: {
      method: "GET" as const,
      path: "/api/meta" as const,
      responses: {
        200: z.object({
          tokenRequired: z.boolean(),
          docs: z.record(z.string()),
        }),
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

export { optimizationLogs };
