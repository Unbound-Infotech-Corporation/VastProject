import { useState } from "react";
import { HardDrive, Cpu, Container, Network, CheckCircle2, AlertTriangle, ChevronRight, Loader2 } from "lucide-react";
import { useOptimize } from "@/hooks/use-system";
import { Button } from "@/components/ui/button";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { cn } from "@/lib/utils";

type ComponentType = "Storage" | "GPU" | "Docker" | "Network";

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
  Storage: "Reports Docker mount/XFS/pquota. Will not format disks.",
  GPU: "Checks NVIDIA drivers and persistence mode (nvidia-smi -pm 1).",
  Docker: "Validates daemon + nvidia-ctk runtime. Restarts Docker only.",
  Network: "Reads the installer port range and can open matching UFW rules.",
};

export function StatusCard({ title, component, verified, message, isLoading = false }: StatusCardProps) {
  const Icon = icons[component];
  const { mutate: optimize, isPending } = useOptimize();
  const [open, setOpen] = useState(false);

  return (
    <div className={cn(
      "glass-panel glass-panel-hover group relative flex h-full flex-col overflow-hidden rounded-xl p-6",
      !verified && "border-warning/30 shadow-[0_0_15px_rgba(255,204,0,0.05)] hover:border-warning/50",
    )}>
      <div className={cn(
        "pointer-events-none absolute -right-20 -top-20 h-40 w-40 rounded-full opacity-20 blur-[80px] transition-colors duration-500",
        verified ? "bg-success" : "bg-warning",
      )} />

      <div className="relative z-10 mb-4 flex items-start justify-between">
        <div className="flex items-center gap-3">
          <div className={cn(
            "rounded-lg border p-3",
            verified ? "border-success/20 bg-success/10 text-success" : "border-warning/20 bg-warning/10 text-warning",
          )}>
            <Icon className="h-6 w-6" />
          </div>
          <h3 className="font-display text-xl font-bold text-foreground">{title}</h3>
        </div>

        <div className="flex items-center">
          {isLoading ? (
            <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
          ) : verified ? (
            <div className="flex items-center gap-1.5 rounded-full border border-success/20 bg-success/10 px-3 py-1 text-sm font-medium text-success">
              <CheckCircle2 className="h-4 w-4" />
              Verified
            </div>
          ) : (
            <div className="flex items-center gap-1.5 rounded-full border border-warning/20 bg-warning/10 px-3 py-1 text-sm font-medium text-warning">
              <AlertTriangle className="h-4 w-4" />
              Issues Found
            </div>
          )}
        </div>
      </div>

      <div className="relative z-10 flex-grow">
        <p className="mb-4 text-sm leading-relaxed text-muted-foreground">
          {descriptions[component]}
        </p>

        <div className="flex min-h-[60px] items-center rounded-lg border border-border/50 bg-secondary/50 p-3 font-mono text-xs text-secondary-foreground">
          <span className={cn("mr-2 inline-block", verified ? "text-success" : "text-warning")}>❯</span>
          <span className="opacity-90">{message}</span>
        </div>
      </div>

      <div className="relative z-10 mt-6">
        <Button
          variant={verified ? "outline" : "default"}
          className={cn(
            "w-full justify-between transition-all duration-300",
            !verified && "bg-primary/90 text-primary-foreground shadow-[0_0_15px_rgba(0,240,255,0.2)] hover:bg-primary",
            verified && "border-border hover:bg-secondary",
          )}
          onClick={() => setOpen(true)}
          disabled={isPending || isLoading}
        >
          {isPending ? (
            <span className="flex items-center">
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              Running allowlisted fix...
            </span>
          ) : (
            <span className="flex items-center font-semibold">
              {component === "Storage" ? "Re-check storage" : verified ? "Re-run safe fix" : "Run safe optimization"}
            </span>
          )}
          {!isPending && <ChevronRight className="h-4 w-4 opacity-50 transition-all group-hover:translate-x-1 group-hover:opacity-100" />}
        </Button>
      </div>

      <AlertDialog open={open} onOpenChange={setOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Run {component} allowlisted fix?</AlertDialogTitle>
            <AlertDialogDescription>
              This calls scripts/host/optimize-safe.sh only. It will not mkfs, wipe a SuperMicro,
              or run the Vast installer. Storage is report-only. GPU may enable persistence mode.
              Docker may restart the daemon. Network may add UFW rules for the existing Vast port range.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={() => {
                optimize({ component, confirm: true, dryRun: false });
                setOpen(false);
              }}
            >
              Confirm
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
