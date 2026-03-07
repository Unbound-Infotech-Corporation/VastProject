import { z } from 'zod';
import { insertOptimizationLogSchema, optimizationLogs } from './schema';

export const errorSchemas = {
  internal: z.object({
    message: z.string(),
  }),
};

export const api = {
  status: {
    get: {
      method: 'GET' as const,
      path: '/api/status' as const,
      responses: {
        200: z.object({
          storage: z.object({ verified: z.boolean(), message: z.string() }),
          gpu: z.object({ verified: z.boolean(), message: z.string() }),
          docker: z.object({ verified: z.boolean(), message: z.string() }),
          network: z.object({ verified: z.boolean(), message: z.string() }),
        }),
      },
    }
  },
  optimize: {
    run: {
      method: 'POST' as const,
      path: '/api/optimize' as const,
      input: z.object({
        component: z.enum(['Storage', 'GPU', 'Docker', 'Network', 'All']),
      }),
      responses: {
        200: z.object({
          success: z.boolean(),
          message: z.string(),
          logId: z.number(),
        }),
        500: errorSchemas.internal,
      }
    }
  },
  logs: {
    list: {
      method: 'GET' as const,
      path: '/api/logs' as const,
      responses: {
        200: z.array(z.custom<typeof optimizationLogs.$inferSelect>()),
      }
    }
  }
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
