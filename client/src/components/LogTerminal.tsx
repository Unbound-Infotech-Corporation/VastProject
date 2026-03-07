import { Terminal, ScrollText, CheckCircle2, XCircle, Clock } from "lucide-react";
import { format } from "date-fns";
import { useSystemLogs } from "@/hooks/use-system";
import { cn } from "@/lib/utils";

export function LogTerminal() {
  const { data: logs = [], isLoading } = useSystemLogs();

  return (
    <div className="glass-panel rounded-xl overflow-hidden mt-12 border border-border">
      {/* Terminal Header */}
      <div className="bg-secondary/80 border-b border-border p-3 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <div className="flex gap-1.5 ml-2">
            <div className="w-3 h-3 rounded-full bg-destructive/80" />
            <div className="w-3 h-3 rounded-full bg-warning/80" />
            <div className="w-3 h-3 rounded-full bg-success/80" />
          </div>
          <div className="flex items-center gap-2 ml-4 text-xs font-mono text-muted-foreground uppercase tracking-wider">
            <Terminal className="w-3.5 h-3.5" />
            system_optimizer.log
          </div>
        </div>
        <div className="text-xs font-mono text-muted-foreground flex items-center gap-1">
          <ScrollText className="w-3.5 h-3.5" />
          {logs.length} entries
        </div>
      </div>

      {/* Terminal Body */}
      <div className="p-4 bg-[#050A14] min-h-[300px] max-h-[500px] overflow-y-auto font-mono text-sm">
        {isLoading ? (
          <div className="flex items-center justify-center h-[200px] text-primary/50 gap-3">
            <div className="w-1.5 h-4 bg-primary/50 animate-pulse" />
            Reading log buffer...
          </div>
        ) : logs.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-[200px] text-muted-foreground/50">
            <Terminal className="w-12 h-12 mb-3 opacity-20" />
            <p>No optimization logs found</p>
            <p className="text-xs mt-1 opacity-60">Run an optimization to generate logs</p>
          </div>
        ) : (
          <div className="space-y-3">
            {logs.map((log) => (
              <div 
                key={log.id} 
                className="group flex flex-col sm:flex-row sm:items-start gap-2 sm:gap-4 p-2 rounded hover:bg-white/[0.02] transition-colors border border-transparent hover:border-white/[0.05]"
              >
                <div className="flex items-center gap-3 min-w-[180px] shrink-0 text-muted-foreground">
                  {log.status === 'success' ? (
                    <CheckCircle2 className="w-4 h-4 text-success" />
                  ) : log.status === 'failed' ? (
                    <XCircle className="w-4 h-4 text-destructive" />
                  ) : (
                    <Clock className="w-4 h-4 text-primary animate-pulse" />
                  )}
                  <span className="opacity-70 text-xs">
                    {log.createdAt ? format(new Date(log.createdAt), "yyyy-MM-dd HH:mm:ss") : "Unknown time"}
                  </span>
                </div>
                
                <div className="flex flex-col gap-1 w-full">
                  <div className="flex items-center gap-2">
                    <span className="text-primary font-bold">[{log.component}]</span>
                    <span className={cn(
                      "uppercase text-[10px] px-1.5 py-0.5 rounded border font-bold tracking-wider",
                      log.status === 'success' ? "bg-success/10 text-success border-success/30" : 
                      log.status === 'failed' ? "bg-destructive/10 text-destructive border-destructive/30" : 
                      "bg-primary/10 text-primary border-primary/30"
                    )}>
                      {log.status}
                    </span>
                  </div>
                  {log.details && (
                    <div className={cn(
                      "pl-4 border-l-2 py-1 mt-1 text-xs/relaxed whitespace-pre-wrap break-words",
                      log.status === 'success' ? "border-success/30 text-success-foreground/80 terminal-glow" : 
                      log.status === 'failed' ? "border-destructive/30 text-destructive/90" : 
                      "border-primary/30 text-primary-foreground/80"
                    )}>
                      {log.details}
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
