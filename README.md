# Vast Host Setup (VastProject)

Guided tooling so Unbound operators (C L first, others later) can take a **new Ubuntu Server machine** to a **Vast.ai rent-ready host**: prepare Ubuntu, install NVIDIA drivers, Docker, the Vast host daemon, run optimizer checks/fixes, and list the machine.

This repository is **VastProject**. The sibling **VastAI** repo is empty. Continue here — migrating would throw away the working dashboard and history for no gain.

## What this is

| Piece | Role |
| --- | --- |
| `scripts/host/bootstrap.sh` | On-box guided install (Ubuntu 22.04 / 24.04) |
| Optimizer dashboard | Dark terminal UI: live checks, allowlisted fixes, logs |
| `deploy.sh` | Install Node, Postgres, build, systemd for the dashboard |

**This app does not SSH to SuperMicro hardware and will not wipe disks from the UI.**

## Hard safety warning

**Disk wipe is unrecoverable.** The only format/repartition path is:

```bash
# On the host, after lsblk. Never the OS disk. Never a rented machine.
sudo bash scripts/host/prepare-docker-xfs.sh --help
sudo bash scripts/host/prepare-docker-xfs.sh \
  --i-understand-this-wipes-disks \
  --device /dev/DISK \
  --yes-wipe-device DISKNAME
```

If those three arguments are not exact, the script exits without touching storage. The dashboard API cannot call this script.

## New machine → rent (do this)

Official Vast docs this path follows (do not invent installer flags):

- [Host setup](https://cloud.vast.ai/host/setup/)
- [Hosting overview](https://docs.vast.ai/host/hosting-overview)
- [Verification](https://docs.vast.ai/host/verification-stages)
- [Disable SSH password login](https://docs.vast.ai/host/disable-ssh-password-login)
- [Upgrade the kernel](https://docs.vast.ai/host/upgrade-kernel)
- [Self-test](https://docs.vast.ai/host/how-to-self-test)

1. **Install Ubuntu Server 22.04 or 24.04** (not Desktop). Secure Boot off. SSH server on. Plan: EFI ≥256 MB, `/` ext4 ≥80 GB, remaining SSD for Docker as **XFS**.
2. **Create a Vast *host* account** (separate from any renter/client account) and accept the hosting agreement on the setup page.
3. **On the machine** (local console or your own SSH — this repo never SSHes for you):

   ```bash
   sudo apt-get update && sudo apt-get install -y git
   sudo mkdir -p /opt && sudo git clone https://github.com/Unbound-Infotech-Corporation/VastProject.git /opt/vast-optimizer
   sudo chown -R "$USER:$USER" /opt/vast-optimizer
   cd /opt/vast-optimizer
   sudo bash scripts/host/bootstrap.sh
   ```

   Bootstrap runs preflight → Ubuntu prep → NVIDIA (`ubuntu-drivers`) → Docker + [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) → **your pasted Vast installer command** → UFW for the range the installer wrote.
4. **Vast daemon:** copy the command from [cloud.vast.ai/host/setup/](https://cloud.vast.ai/host/setup/). Keys expire. Export `VAST_INSTALL_CMD='…paste…'` or `VAST_HOST_KEY=…`. Extra flags only if **that page** shows them.
5. **Ports:** verification wants **5 ports per GPU** (100 recommended), continuous TCP+UDP, public IPv4, same range forwarded on the router. CGNAT will not verify. Self-test still needs at least 3 direct ports even with `--ignore-requirements`.
6. **SSH:** confirm a key works, then disable password login using Vast’s documented steps. Do not lock yourself out.
7. **List the machine**, then `vastai self-test machine <id>`.
8. **Dashboard (optional, on the host):**

   ```bash
   cd /opt/vast-optimizer
   ./deploy.sh
   # open http://<host-ip>:5000
   # paste OPTIMIZER_API_TOKEN from .env for mutations
   ```

Kernel security updates are required. They need a reboot — schedule maintenance; do not interrupt rentals. Hold NVIDIA packages so unattended upgrades do not swap drivers mid-job.

## Optimizer API (hardened)

- `GET /api/status` — real host probes (degrade gracefully off-box)
- `GET /api/logs` — optimization history
- `GET /api/meta` — doc links + whether a token is required
- `POST /api/optimize` — `{ "component": "GPU"|"Docker"|"Network"|"Storage"|"All", "confirm": true, "dryRun": false }`
  - Production requires `Authorization: Bearer $OPTIMIZER_API_TOKEN`
  - Allowlisted `scripts/host/optimize-safe.sh` only
  - Storage is **report-only** (no `mkfs`)
  - Rate-limited

## Local development

```bash
npm install
npm test
npm run check
npm run build
NODE_ENV=development npm run dev   # http://localhost:5000 — memory logs if DATABASE_URL unset
```

## Docs

- [docs/HOST_SETUP.md](docs/HOST_SETUP.md) — bootstrap details
- [docs/SAFETY.md](docs/SAFETY.md) — wipe / SSH / SuperMicro rules
- [docs/AUDIT.md](docs/AUDIT.md) — revived vs rewritten
- [docs/legacy/](docs/legacy/) — stale Replit/WinSCP transfer notes (do not follow)

## License

MIT
