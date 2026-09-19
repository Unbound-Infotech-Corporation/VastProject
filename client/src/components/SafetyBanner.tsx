import { AlertTriangle } from "lucide-react";

export function SafetyBanner() {
  return (
    <div className="glass-panel rounded-xl border-warning/40 bg-warning/5 p-4 flex gap-3 items-start">
      <AlertTriangle className="w-5 h-5 text-warning shrink-0 mt-0.5" />
      <div className="text-sm leading-relaxed">
        <p className="font-semibold text-warning mb-1">Disk wipe is never one-click</p>
        <p className="text-muted-foreground">
          Dashboard optimizations only apply safe fixes (NVIDIA persistence mode, Docker
          NVIDIA runtime, conservative sysctls). Formatting a drive for XFS+pquota requires
          the CLI: <code className="text-foreground">./scripts/optimize/fix-storage.sh --confirm-wipe /dev/DISK</code>.
          Official Vast host docs:{" "}
          <a
            className="text-primary underline-offset-2 hover:underline"
            href="https://cloud.vast.ai/host/setup/"
            target="_blank"
            rel="noreferrer"
          >
            cloud.vast.ai/host/setup
          </a>
          .
        </p>
      </div>
    </div>
  );
}
