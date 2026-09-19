import { TerminalSquare } from "lucide-react";

const steps = [
  {
    n: "01",
    title: "Install Ubuntu Server 22.04 or 24.04",
    body: "EFI ≥256 MB, root ext4 ≥80 GB, remaining disks as XFS for Docker. ISO: releases.ubuntu.com",
  },
  {
    n: "02",
    title: "Bootstrap this host",
    body: "./scripts/vast-host-setup   or   ./scripts/bootstrap-host.sh",
  },
  {
    n: "03",
    title: "Reboot and verify the driver",
    body: "nvidia-smi -q   — Vast asks you to test the driver before their installer.",
  },
  {
    n: "04",
    title: "Register a dedicated HOST account",
    body: "Not your renter account. Open cloud.vast.ai/host/setup, accept the agreement, copy the key (≈1 hour).",
  },
  {
    n: "05",
    title: "Install the Vast daemon",
    body: "./scripts/install-vast-daemon.sh --auth-key YOUR_KEY   — only documented flags: --interactive, --reset-machine.",
  },
  {
    n: "06",
    title: "Forward ports, then list the machine",
    body: "Continuous TCP+UDP range (3 ports/GPU min, 100 preferred). Machine should appear on the Vast Machines page.",
  },
];

export function SetupGuide() {
  return (
    <section className="glass-panel rounded-xl p-6">
      <div className="flex items-center gap-2 mb-4">
        <TerminalSquare className="w-5 h-5 text-primary" />
        <h2 className="text-xl font-display font-bold">New machine → rent on Vast</h2>
      </div>
      <ol className="space-y-3">
        {steps.map((step) => (
          <li key={step.n} className="flex gap-4">
            <span className="font-mono text-primary text-sm pt-0.5">{step.n}</span>
            <div>
              <p className="font-semibold text-sm">{step.title}</p>
              <p className="text-xs text-muted-foreground mt-0.5 leading-relaxed font-mono">
                {step.body}
              </p>
            </div>
          </li>
        ))}
      </ol>
    </section>
  );
}
