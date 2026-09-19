import type { ElementType } from "react";
import { CheckCircle2, AlertTriangle, Monitor, Cpu, Box, Radio } from "lucide-react";
import type { ComponentStatus } from "@shared/schema";
import { cn } from "@/lib/utils";

interface HostReadinessProps {
  os?: ComponentStatus;
  vast?: ComponentStatus;
  gpu?: ComponentStatus;
  docker?: ComponentStatus;
}

function Chip({
  label,
  status,
  icon: Icon,
}: {
  label: string;
  status?: ComponentStatus;
  icon: ElementType;
}) {
  const verified = status?.verified === true;
  return (
    <div
      className={cn(
        "flex items-start gap-3 rounded-lg border p-3 min-h-[88px]",
        verified ? "border-success/25 bg-success/5" : "border-warning/25 bg-warning/5",
      )}
    >
      <Icon className={cn("w-4 h-4 mt-0.5 shrink-0", verified ? "text-success" : "text-warning")} />
      <div className="min-w-0">
        <div className="flex items-center gap-2 text-sm font-semibold">
          {label}
          {verified ? (
            <CheckCircle2 className="w-3.5 h-3.5 text-success" />
          ) : (
            <AlertTriangle className="w-3.5 h-3.5 text-warning" />
          )}
        </div>
        <p className="text-xs text-muted-foreground mt-1 leading-relaxed break-words">
          {status?.message ?? "Waiting for status…"}
        </p>
      </div>
    </div>
  );
}

export function HostReadiness({ os, vast, gpu, docker }: HostReadinessProps) {
  return (
    <section>
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-xl font-display font-bold text-foreground">Host Readiness</h2>
        <p className="text-xs text-muted-foreground font-mono">OS · driver · docker · vastai</p>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3">
        <Chip label="Ubuntu" status={os} icon={Monitor} />
        <Chip label="GPU driver" status={gpu} icon={Cpu} />
        <Chip label="Docker + toolkit" status={docker} icon={Box} />
        <Chip label="Vast daemon" status={vast} icon={Radio} />
      </div>
    </section>
  );
}
