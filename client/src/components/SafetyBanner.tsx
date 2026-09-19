import { AlertTriangle } from "lucide-react";

export function SafetyBanner() {
  return (
    <section className="glass-panel rounded-xl border border-destructive/40 bg-destructive/5 p-5">
      <div className="flex items-start gap-3">
        <AlertTriangle className="mt-0.5 h-5 w-5 shrink-0 text-destructive" />
        <div className="space-y-2 text-sm leading-relaxed">
          <p className="font-display text-base font-bold text-destructive">
            Disk wipe is never a one-click action
          </p>
          <p className="text-muted-foreground">
            This dashboard will not format, repartition, or SSH into any SuperMicro or other host.
            The only wipe path is <code className="text-foreground">scripts/host/prepare-docker-xfs.sh</code>{" "}
            on the machine itself, and it requires{" "}
            <code className="text-foreground">--i-understand-this-wipes-disks</code> plus the exact
            device name. Identify disks with <code className="text-foreground">lsblk</code> first.
            Wiping the OS disk or a rented machine is unrecoverable.
          </p>
        </div>
      </div>
    </section>
  );
}
