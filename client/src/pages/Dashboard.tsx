import { useSystemStatus } from "@/hooks/use-system";
import { Header } from "@/components/Header";
import { StatusCard } from "@/components/StatusCard";
import { LogTerminal } from "@/components/LogTerminal";
import { SafetyBanner } from "@/components/SafetyBanner";
import { HostReadiness } from "@/components/HostReadiness";
import { SetupGuide } from "@/components/SetupGuide";
import { Skeleton } from "@/components/ui/skeleton";

export default function Dashboard() {
  const { data: status, isLoading, error } = useSystemStatus();

  return (
    <div className="relative min-h-screen pt-8 pb-16 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
      {/* Decorative ambient background elements */}
      <div className="scanline" />
      <div className="fixed top-[-20%] left-[-10%] w-[50%] h-[50%] rounded-full bg-primary/5 blur-[120px] pointer-events-none" />
      <div className="fixed bottom-[-20%] right-[-10%] w-[50%] h-[50%] rounded-full bg-blue-600/5 blur-[120px] pointer-events-none" />

      <Header />

      <main className="relative z-10 space-y-12">
        <SafetyBanner />
        {status && (
          <HostReadiness
            os={status.os}
            vast={status.vast}
            gpu={status.gpu}
            docker={status.docker}
          />
        )}
        {/* Status Grid */}
        <div>
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-xl font-display font-bold text-foreground">System Integrity</h2>
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <span className="relative flex h-2.5 w-2.5">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-success opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-success"></span>
              </span>
              Live Monitoring Active
            </div>
          </div>

          {error ? (
            <div className="glass-panel p-8 rounded-xl border-destructive/30 text-center">
              <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-destructive/10 text-destructive mb-4">
                <span className="text-2xl">!</span>
              </div>
              <h3 className="text-lg font-bold text-destructive mb-2">Connection Lost</h3>
              <p className="text-muted-foreground">Failed to connect to the server daemon. Ensure the backend is running.</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
              {isLoading || !status ? (
                // Loading Skeletons
                Array.from({ length: 4 }).map((_, i) => (
                  <div key={i} className="glass-panel rounded-xl p-6 h-[260px] flex flex-col">
                    <div className="flex items-center gap-3 mb-4">
                      <Skeleton className="w-12 h-12 rounded-lg bg-muted/20" />
                      <Skeleton className="h-6 w-24 bg-muted/20" />
                    </div>
                    <Skeleton className="h-16 w-full mb-4 bg-muted/20" />
                    <Skeleton className="h-12 w-full mt-auto bg-muted/20" />
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

        <SetupGuide />

        {/* Logs Section */}
        <div>
          <h2 className="text-xl font-display font-bold text-foreground mb-2">Execution Logs</h2>
          <p className="text-sm text-muted-foreground">Detailed output from system optimization scripts.</p>
          <LogTerminal />
        </div>
      </main>
    </div>
  );
}
