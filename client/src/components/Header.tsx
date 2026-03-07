import { Server, Activity, ShieldCheck, Zap } from "lucide-react";
import { useOptimize } from "@/hooks/use-system";
import { Button } from "@/components/ui/button";

export function Header() {
  const { mutate: optimize, isPending } = useOptimize();

  return (
    <header className="relative z-10 w-full mb-12">
      <div className="absolute inset-0 bg-primary/5 blur-[100px] rounded-full pointer-events-none" />
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-6 p-6 glass-panel rounded-2xl">
        <div className="flex items-center gap-4">
          <div className="relative flex items-center justify-center w-14 h-14 rounded-xl bg-secondary border border-primary/20 shadow-[0_0_15px_rgba(0,240,255,0.15)]">
            <Server className="w-7 h-7 text-primary" />
            <div className="absolute top-0 right-0 w-3 h-3 bg-green-500 rounded-full border-2 border-secondary animate-pulse" />
          </div>
          <div>
            <h1 className="text-2xl md:text-3xl font-bold text-gradient flex items-center gap-2">
              Vast.AI Optimizer
            </h1>
            <p className="text-sm text-muted-foreground flex items-center gap-2 mt-1">
              <Activity className="w-4 h-4" /> Ubuntu 22.04 LTS Server Management
            </p>
          </div>
        </div>

        <Button
          size="lg"
          onClick={() => optimize({ component: 'All' })}
          disabled={isPending}
          className="relative overflow-hidden group bg-primary/10 text-primary border border-primary/30 hover:bg-primary/20 hover:border-primary shadow-[0_0_20px_rgba(0,240,255,0.1)] transition-all duration-300 font-bold"
        >
          <div className="absolute inset-0 w-full h-full bg-gradient-to-r from-transparent via-primary/20 to-transparent -translate-x-full group-hover:animate-[shimmer_1.5s_infinite]" />
          {isPending ? (
            <>
              <Zap className="w-5 h-5 mr-2 animate-pulse" />
              Executing Sequence...
            </>
          ) : (
            <>
              <ShieldCheck className="w-5 h-5 mr-2" />
              Optimize All Systems
            </>
          )}
        </Button>
      </div>
    </header>
  );
}
