import { useSystemStatus } from "@/hooks/use-system";
import { Header } from "@/components/Header";
import { StatusCard } from "@/components/StatusCard";
import { LogTerminal } from "@/components/LogTerminal";
import { SafetyBanner } from "@/components/SafetyBanner";
import { ReadinessList } from "@/components/ReadinessList";
import { SetupGuide } from "@/components/SetupGuide";
import { Skeleton } from "@/components/ui/skeleton";

export default function Dashboard() {
  const { data: status, isLoading, error } = useSystemStatus();

  return (
    <div className="relative mx-auto min-h-screen max-w-7xl px-4 pb-16 pt-8 sm:px-6 lg:px-8">
      <div className="scanline" />
      <div className="pointer-events-none fixed left-[-10%] top-[-20%] h-[50%] w-[50%] rounded-full bg-primary/5 blur-[120px]" />
      <div className="pointer-events-none fixed bottom-[-20%] right-[-10%] h-[50%] w-[50%] rounded-full bg-blue-600/5 blur-[120px]" />

      <Header />

      <main className="relative z-10 space-y-12">
        <SafetyBanner />

        <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
          {status ? <ReadinessList status={status} /> : (
            <div className="glass-panel h-full rounded-xl p-6">
              <Skeleton className="mb-4 h-6 w-48 bg-muted/20" />
              <Skeleton className="h-40 w-full bg-muted/20" />
            </div>
          )}
          <SetupGuide />
        </div>

        <div>
          <div className="mb-6 flex items-center justify-between">
            <h2 className="font-display text-xl font-bold text-foreground">System integrity</h2>
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <span className="relative flex h-2.5 w-2.5">
                <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-success opacity-75" />
                <span className="relative inline-flex h-2.5 w-2.5 rounded-full bg-success" />
              </span>
              Live host checks
            </div>
          </div>

          {error ? (
            <div className="glass-panel rounded-xl border-destructive/30 p-8 text-center">
              <div className="mb-4 inline-flex h-16 w-16 items-center justify-center rounded-full bg-destructive/10 text-destructive">
                <span className="text-2xl">!</span>
              </div>
              <h3 className="mb-2 text-lg font-bold text-destructive">Connection Lost</h3>
              <p className="text-muted-foreground">Failed to connect to the optimizer API. Start the backend on this host.</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-4">
              {isLoading || !status ? (
                Array.from({ length: 4 }).map((_, i) => (
                  <div key={i} className="glass-panel flex h-[260px] flex-col rounded-xl p-6">
                    <div className="mb-4 flex items-center gap-3">
                      <Skeleton className="h-12 w-12 rounded-lg bg-muted/20" />
                      <Skeleton className="h-6 w-24 bg-muted/20" />
                    </div>
                    <Skeleton className="mb-4 h-16 w-full bg-muted/20" />
                    <Skeleton className="mt-auto h-12 w-full bg-muted/20" />
                  </div>
                ))
              ) : (
                <>
                  <StatusCard
                    title="Storage"
                    component="Storage"
                    verified={status.storage.verified}
                    message={status.storage.message}
                  />
                  <StatusCard
                    title="GPU Compute"
                    component="GPU"
                    verified={status.gpu.verified}
                    message={status.gpu.message}
                  />
                  <StatusCard
                    title="Docker"
                    component="Docker"
                    verified={status.docker.verified}
                    message={status.docker.message}
                  />
                  <StatusCard
                    title="Network"
                    component="Network"
                    verified={status.network.verified}
                    message={status.network.message}
                  />
                </>
              )}
            </div>
          )}
        </div>

        <div>
          <h2 className="mb-2 font-display text-xl font-bold text-foreground">Execution logs</h2>
          <p className="text-sm text-muted-foreground">Allowlisted optimizer output only. Disk wipe never appears here.</p>
          <LogTerminal />
        </div>
      </main>
    </div>
  );
}
