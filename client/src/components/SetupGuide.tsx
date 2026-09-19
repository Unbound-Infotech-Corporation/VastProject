import { useState } from "react";
import { ExternalLink, KeyRound } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { getOptimizerToken, setOptimizerToken } from "@/lib/authToken";
import { useMeta } from "@/hooks/use-system";

const STEPS = [
  {
    title: "Install Ubuntu Server 22.04 or 24.04",
    body: "Use the Server ISO, not Desktop. Secure Boot off. Plan EFI ≥256 MB, root ext4 ≥80 GB, leftover disks for Docker (XFS). Official: cloud.vast.ai/host/setup/",
  },
  {
    title: "Run host bootstrap on the machine",
    body: "On the host: git clone this repo, then sudo bash scripts/host/bootstrap.sh. It prepares Ubuntu, NVIDIA, Docker, and waits for your Vast dashboard command.",
  },
  {
    title: "Dedicated Docker volume (optional, destructive)",
    body: "Only if you still need XFS for Docker. scripts/host/prepare-docker-xfs.sh wipes a device you name. Never point it at the OS disk or a SuperMicro over LAN from this app.",
  },
  {
    title: "Paste the Vast installer from the host dashboard",
    body: "Create a host account (not your renter account). Open cloud.vast.ai/host/setup/, accept the agreement, copy the command. Do not invent installer flags. Keys expire.",
  },
  {
    title: "Forward ports, disable SSH passwords, self-test",
    body: "Verification wants 5 ports/GPU (100 recommended), public IPv4, SSH keys only after a key works, then vastai self-test machine <id>. Kernel patches need a maintenance window.",
  },
];

export function SetupGuide() {
  const { data: meta } = useMeta();
  const [token, setToken] = useState(getOptimizerToken());

  return (
    <div className="glass-panel rounded-xl p-6">
      <h2 className="mb-4 font-display text-xl font-bold">Guided host setup</h2>
      <ol className="space-y-4">
        {STEPS.map((step, index) => (
          <li key={step.title} className="flex gap-4">
            <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg border border-primary/30 bg-primary/10 font-mono text-sm text-primary">
              {index + 1}
            </span>
            <div>
              <p className="font-semibold">{step.title}</p>
              <p className="mt-1 text-sm text-muted-foreground">{step.body}</p>
            </div>
          </li>
        ))}
      </ol>

      <div className="mt-6 space-y-3 border-t border-border/50 pt-4">
        <p className="flex items-center gap-2 text-sm font-semibold">
          <KeyRound className="h-4 w-4 text-primary" />
          Optimizer API token
        </p>
        <p className="text-xs text-muted-foreground">
          Production mutations require OPTIMIZER_API_TOKEN. Paste it here so Run Optimization can call the allowlisted fixer. Disk wipe stays blocked.
        </p>
        <div className="flex flex-col gap-2 sm:flex-row">
          <Input
            type="password"
            value={token}
            onChange={(event) => setToken(event.target.value)}
            placeholder="OPTIMIZER_API_TOKEN"
            className="font-mono"
          />
          <Button
            type="button"
            variant="outline"
            onClick={() => setOptimizerToken(token)}
          >
            Store in this browser
          </Button>
        </div>
        {meta?.docs && (
          <div className="flex flex-wrap gap-3 pt-2 text-xs">
            {Object.entries(meta.docs).map(([name, href]) => (
              <a
                key={name}
                href={href}
                target="_blank"
                rel="noreferrer"
                className="inline-flex items-center gap-1 text-primary hover:underline"
              >
                {name} <ExternalLink className="h-3 w-3" />
              </a>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
