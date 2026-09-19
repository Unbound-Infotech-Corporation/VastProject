import { useState } from "react";
import { Server, Activity, ShieldCheck, Zap } from "lucide-react";
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

export function Header() {
  const { mutate: optimize, isPending } = useOptimize();
  const [open, setOpen] = useState(false);

  return (
    <header className="relative z-10 mb-12 w-full">
      <div className="pointer-events-none absolute inset-0 rounded-full bg-primary/5 blur-[100px]" />
      <div className="glass-panel flex flex-col justify-between gap-6 rounded-2xl p-6 md:flex-row md:items-center">
        <div className="flex items-center gap-4">
          <div className="relative flex h-14 w-14 items-center justify-center rounded-xl border border-primary/20 bg-secondary shadow-[0_0_15px_rgba(0,240,255,0.15)]">
            <Server className="h-7 w-7 text-primary" />
            <div className="absolute right-0 top-0 h-3 w-3 animate-pulse rounded-full border-2 border-secondary bg-green-500" />
          </div>
          <div>
            <h1 className="text-gradient flex items-center gap-2 text-2xl font-bold md:text-3xl">
              Vast Host Setup
            </h1>
            <p className="mt-1 flex items-center gap-2 text-sm text-muted-foreground">
              <Activity className="h-4 w-4" /> Ubuntu 22.04 / 24.04 · optimizer + bootstrap
            </p>
          </div>
        </div>

        <Button
          size="lg"
          onClick={() => setOpen(true)}
          disabled={isPending}
          className="group relative overflow-hidden border border-primary/30 bg-primary/10 font-bold text-primary shadow-[0_0_20px_rgba(0,240,255,0.1)] transition-all duration-300 hover:border-primary hover:bg-primary/20"
        >
          <div className="absolute inset-0 h-full w-full -translate-x-full bg-gradient-to-r from-transparent via-primary/20 to-transparent group-hover:animate-[shimmer_1.5s_infinite]" />
          {isPending ? (
            <>
              <Zap className="mr-2 h-5 w-5 animate-pulse" />
              Executing allowlisted fixes...
            </>
          ) : (
            <>
              <ShieldCheck className="mr-2 h-5 w-5" />
              Optimize all (safe)
            </>
          )}
        </Button>
      </div>

      <AlertDialog open={open} onOpenChange={setOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Run every allowlisted fix?</AlertDialogTitle>
            <AlertDialogDescription>
              GPU persistence, Docker NVIDIA runtime, and UFW for the existing Vast port range.
              Storage stays report-only. No disk wipe. No remote SSH.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={() => {
                optimize({ component: "All", confirm: true, dryRun: false });
                setOpen(false);
              }}
            >
              Confirm
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </header>
  );
}
