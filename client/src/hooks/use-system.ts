import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { api } from "@shared/routes";
import { useToast } from "@/hooks/use-toast";
import { z } from "zod";

// Error logging helper
function parseWithLogging<T>(schema: z.ZodSchema<T>, data: unknown, label: string): T {
  const result = schema.safeParse(data);
  if (!result.success) {
    console.error(`[Zod] ${label} validation failed:`, result.error.format());
    throw result.error;
  }
  return result.data;
}

export function useSystemStatus() {
  return useQuery({
    queryKey: [api.status.get.path],
    queryFn: async () => {
      const res = await fetch(api.status.get.path, { credentials: "include" });
      if (!res.ok) throw new Error("Failed to fetch system status");
      const data = await res.json();
      return parseWithLogging(api.status.get.responses[200], data, "status.get");
    },
    // Refresh every 15 seconds to keep dashboard live
    refetchInterval: 15000,
  });
}

export function useSystemLogs() {
  return useQuery({
    queryKey: [api.logs.list.path],
    queryFn: async () => {
      const res = await fetch(api.logs.list.path, { credentials: "include" });
      if (!res.ok) throw new Error("Failed to fetch optimization logs");
      const data = await res.json();
      return parseWithLogging(api.logs.list.responses[200], data, "logs.list");
    },
    refetchInterval: 15000,
  });
}

type OptimizeInput = z.infer<typeof api.optimize.run.input>;

export function useOptimize() {
  const queryClient = useQueryClient();
  const { toast } = useToast();

  return useMutation({
    mutationFn: async (data: OptimizeInput) => {
      const validated = api.optimize.run.input.parse(data);
      const res = await fetch(api.optimize.run.path, {
        method: api.optimize.run.method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(validated),
        credentials: "include",
      });
      
      if (!res.ok) {
        let errorMessage = "Failed to run optimization";
        try {
          const errorData = await res.json();
          if (res.status === 500) {
            const parsedError = api.optimize.run.responses[500].parse(errorData);
            errorMessage = parsedError.message;
          }
        } catch (e) {
          // Fallback to generic message
        }
        throw new Error(errorMessage);
      }
      
      const responseData = await res.json();
      return parseWithLogging(api.optimize.run.responses[200], responseData, "optimize.run");
    },
    onSuccess: (data, variables) => {
      // Invalidate both status and logs to refresh the dashboard
      queryClient.invalidateQueries({ queryKey: [api.status.get.path] });
      queryClient.invalidateQueries({ queryKey: [api.logs.list.path] });
      
      toast({
        title: "Optimization Complete",
        description: `${variables.component} optimization finished: ${data.message}`,
        variant: data.success ? "default" : "destructive",
      });
    },
    onError: (error: Error) => {
      toast({
        title: "Optimization Failed",
        description: error.message,
        variant: "destructive",
      });
    },
  });
}
