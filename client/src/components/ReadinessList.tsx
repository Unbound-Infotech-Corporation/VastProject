import { CheckCircle2, AlertTriangle, XCircle } from "lucide-react";
import type { SystemStatusResponse } from "@shared/schema";
import { cn } from "@/lib/utils";

const LABELS: Array<{ key: keyof Omit<SystemStatusResponse, "readiness">; label: string }> = [
  { key: "os", label: "Ubuntu 22.04/24.04" },
  { key: "storage", label: "Docker XFS volume" },
  { key: "gpu", label: "NVIDIA driver" },
  { key: "docker", label: "Docker + nvidia runtime" },
  { key: "host", label: "Vast daemon" },
  { key: "network", label: "Port range" },
  { key: "ssh", label: "SSH keys only" },
];

export function ReadinessList({ status }: { status: SystemStatusResponse }) {
  return (
    <div className="glass-panel rounded-xl p-6">
      <div className="mb-4 flex items-center justify-between gap-4">
        <h2 className="font-display text-xl font-bold">Rent-ready checklist</h2>
        <span
          className={cn(
            "rounded-full border px-3 py-1 text-xs font-bold uppercase tracking-wider",
            status.readiness.ready
              ? "border-success/30 bg-success/10 text-success"
              : "border-warning/30 bg-warning/10 text-warning",
          )}
        >
          {status.readiness.ready ? "All checks green" : "Not listed yet"}
        </span>
      </div>
      <ol className="space-y-3">
        {LABELS.map((item, index) => {
          const check = status[item.key];
          const Icon =
            check.severity === "ok" ? CheckCircle2 : check.severity === "fail" ? XCircle : AlertTriangle;
          const color =
            check.severity === "ok"
              ? "text-success"
              : check.severity === "fail"
                ? "text-destructive"
                : "text-warning";
          return (
            <li key={item.key} className="flex items-start gap-3 border-b border-border/40 pb-3 last:border-0">
              <span className="w-6 font-mono text-xs text-muted-foreground">{index + 1}</span>
              <Icon className={cn("mt-0.5 h-4 w-4 shrink-0", color)} />
              <div>
                <p className="text-sm font-semibold">{item.label}</p>
                <p className="text-xs text-muted-foreground">{check.message}</p>
              </div>
            </li>
          );
        })}
      </ol>
    </div>
  );
}
