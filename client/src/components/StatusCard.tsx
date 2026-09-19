import { HardDrive, Cpu, Container, Network, CheckCircle2, AlertTriangle, ChevronRight, Loader2 } from "lucide-react";
import { useOptimize } from "@/hooks/use-system";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

type ComponentType = 'Storage' | 'GPU' | 'Docker' | 'Network';

interface StatusCardProps {
  title: string;
  component: ComponentType;
  verified: boolean;
  message: string;
  isLoading?: boolean;
}

const icons: Record<ComponentType, React.ElementType> = {
  Storage: HardDrive,
  GPU: Cpu,
  Docker: Container,
  Network: Network,
};

const descriptions: Record<ComponentType, string> = {
  Storage: "XFS + pquota on /var/lib/docker. Never formats a disk from this button.",
  GPU: "NVIDIA driver presence and persistence mode (nvidia-smi -pm 1).",
  Docker: "Docker daemon, nvidia-ctk, and nvidia runtime in daemon.json.",
  Network: "ip_forward, Vast port-range file, and UFW hints — router still required.",
};

export function StatusCard({ title, component, verified, message, isLoading = false }: StatusCardProps) {
  const Icon = icons[component];
  const { mutate: optimize, isPending } = useOptimize();
  const isOptimizing = isPending;

  return (
    <div className={cn(
      "glass-panel glass-panel-hover rounded-xl p-6 relative overflow-hidden group flex flex-col h-full",
      !verified && "border-warning/30 hover:border-warning/50 shadow-[0_0_15px_rgba(255,204,0,0.05)]"
    )}>
      {/* Decorative background glow based on status */}
      <div className={cn(
        "absolute -right-20 -top-20 w-40 h-40 blur-[80px] rounded-full opacity-20 pointer-events-none transition-colors duration-500",
        verified ? "bg-success" : "bg-warning"
      )} />

      <div className="flex justify-between items-start mb-4 relative z-10">
        <div className="flex items-center gap-3">
          <div className={cn(
            "p-3 rounded-lg border",
            verified ? "bg-success/10 border-success/20 text-success" : "bg-warning/10 border-warning/20 text-warning"
          )}>
            <Icon className="w-6 h-6" />
          </div>
          <h3 className="text-xl font-bold text-foreground font-display">{title}</h3>
        </div>
        
        <div className="flex items-center">
          {isLoading ? (
            <Loader2 className="w-6 h-6 text-muted-foreground animate-spin" />
          ) : verified ? (
            <div className="flex items-center gap-1.5 px-3 py-1 rounded-full bg-success/10 border border-success/20 text-success text-sm font-medium">
              <CheckCircle2 className="w-4 h-4" />
              Verified
            </div>
          ) : (
            <div className="flex items-center gap-1.5 px-3 py-1 rounded-full bg-warning/10 border border-warning/20 text-warning text-sm font-medium">
              <AlertTriangle className="w-4 h-4" />
              Issues Found
            </div>
          )}
        </div>
      </div>

      <div className="flex-grow relative z-10">
        <p className="text-muted-foreground text-sm mb-4 leading-relaxed">
          {descriptions[component]}
        </p>
        
        <div className="bg-secondary/50 rounded-lg p-3 border border-border/50 font-mono text-xs text-secondary-foreground min-h-[60px] flex items-center">
          <span className={cn(
            "inline-block mr-2",
            verified ? "text-success" : "text-warning"
          )}>❯</span>
          <span className="opacity-90">{message}</span>
        </div>
      </div>

      <div className="mt-6 relative z-10">
        <Button 
          variant={verified ? "outline" : "default"}
          className={cn(
            "w-full justify-between transition-all duration-300",
            !verified && "bg-primary/90 hover:bg-primary text-primary-foreground shadow-[0_0_15px_rgba(0,240,255,0.2)]",
            verified && "hover:bg-secondary border-border"
          )}
          onClick={() => optimize({ component })}
          disabled={isOptimizing || isLoading}
        >
          {isOptimizing ? (
            <span className="flex items-center">
              <Loader2 className="w-4 h-4 mr-2 animate-spin" />
              Running Scripts...
            </span>
          ) : (
            <span className="flex items-center font-semibold">
              {verified ? "Re-verify Component" : "Run Optimization"}
            </span>
          )}
          {!isOptimizing && <ChevronRight className="w-4 h-4 opacity-50 group-hover:opacity-100 group-hover:translate-x-1 transition-all" />}
        </Button>
      </div>
    </div>
  );
}
