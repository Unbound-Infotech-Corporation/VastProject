# Vast Host Setup

Turn an Ubuntu **22.04 / 24.04** box into a [Vast.ai](https://cloud.vast.ai/) GPU host, then keep it rent-ready with real optimizer checks and a dark-terminal dashboard.

This is the Unbound Infotech host toolkit, revived from the Replit-era **Vast.AI Server Optimization Dashboard** in this repository (`VastProject`). Work continues **here**, not in the empty [`VastAI`](https://github.com/Unbound-Infotech-Corporation/VastAI) repo — `VastProject` already has the dashboard, scripts, and git history.

Official Vast docs (do not invent installer flags):

- Host setup: https://cloud.vast.ai/host/setup/
- Hosting overview: https://docs.vast.ai/host/hosting-overview

## New machine → rent on Vast

```
Ubuntu Server 22.04/24.04
        ↓
./scripts/vast-host-setup          # guided CLI (desktop terminal or SSH)
        ↓
reboot + nvidia-smi -q
        ↓
Dedicated HOST account + key from cloud.vast.ai/host/setup
        ↓
./scripts/install-vast-daemon.sh --auth-key YOUR_KEY
        ↓
Forward a continuous TCP+UDP port range (3/GPU min, 100/GPU preferred)
        ↓
./scripts/optimize/run.sh All --apply
        ↓
Machine appears on Vast → list offer → rent
```

Optional dashboard (same dark UI):

```bash
./scripts/install-dashboard.sh
# http://<this-host>:5000
```

**This cloud agent cannot SSH into C L’s SuperMicro or wipe any physical disk.** Scripts are for you to run on the host.

## Safety

**Formatting a disk is never the default.**

- Bootstrap / dashboard / `run.sh --apply` never call `mkfs`.
- The only wipe path is explicit:

  ```bash
  ./scripts/optimize/fix-storage.sh --confirm-wipe /dev/DISK
  ```

  You must type the device path again. The OS disk (`/`, `/boot`, `/home`) is refused. `ASSUME_YES=1` cannot bypass this.

See [docs/SAFETY.md](docs/SAFETY.md).

## Guided install UX

| Surface | Command |
| --- | --- |
| CLI menu (primary) | `./scripts/vast-host-setup` or `./setup.sh` |
| Desktop launcher | `./scripts/install-desktop-launcher.sh` |
| Dashboard | `./scripts/install-dashboard.sh` or `./deploy.sh` |
| Headless bootstrap | `./scripts/bootstrap-host.sh` (`--dry-run` to print steps) |

`bootstrap-host.sh` uses only public documented steps:

1. **NVIDIA drivers** — `ubuntu-drivers install --gpgpu`  
   https://ubuntu.com/server/docs/how-to/graphics/install-nvidia-drivers/
2. **Docker Engine** — Docker’s apt repository  
   https://docs.docker.com/engine/install/ubuntu/
3. **NVIDIA Container Toolkit** — NVIDIA apt repo + `nvidia-ctk runtime configure --runtime=docker`  
   https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html

Vast’s own installer (from the console) also installs Docker and `nvidia-ctk` if they are missing. Pre-installing them here is optional.

The host daemon is **not** bundled. Copy a fresh authorization key from https://cloud.vast.ai/host/setup/ (expires ~1 hour). This repo only runs the documented shape:

```bash
wget https://console.vast.ai/install -O install
sudo python3 install YOUR_AUTH_KEY --interactive
```

Documented extra flag: `--reset-machine`. Prefer pasting Vast’s copied command if the console text ever changes. Details: [docs/VAST_REGISTRATION.md](docs/VAST_REGISTRATION.md). OS partition layout: [docs/HOST_INSTALL.md](docs/HOST_INSTALL.md).

## npm scripts (repo builds)

```bash
npm install          # dependencies
npm run dev          # dashboard + API on :5000 (Vite, no Postgres required)
npm run build        # client → dist/public + server → dist/index.cjs
npm start            # NODE_ENV=production node dist/index.cjs
npm run check        # tsc --noEmit
npm test             # status JSON unit tests
npm run db:push      # drizzle schema (needs DATABASE_URL)
npm run host:check   # bash scripts/optimize/collect-status.sh
npm run host:setup   # guided CLI
```

Copy `.env.example` to `.env`. `DATABASE_URL` is optional; without it, optimization logs stay in memory.

## Optimizer APIs

| Method | Path | Notes |
| --- | --- | --- |
| `GET` | `/api/health` | liveness, storage backend, optimize flag |
| `GET` | `/api/status` | live host checks (storage / GPU / Docker / network / OS / Vast daemon) |
| `POST` | `/api/optimize` | `{ "component": "Storage"\|"GPU"\|"Docker"\|"Network"\|"All" }` |
| `GET` | `/api/logs` | recent runs |

`POST /api/optimize` is off until `ALLOW_OPTIMIZE=true`. It is localhost-only unless `ALLOW_REMOTE_OPTIMIZE=true` or `OPTIMIZE_TOKEN` is set. Rate-limited. Storage “optimize” from the API **never** wipes disks.

What each check expects (Vast host practice):

- **Storage** — `/var/lib/docker` on **XFS** with **pquota** / **prjquota**
- **GPU** — `nvidia-smi` works; persistence mode enabled
- **Docker** — daemon up; `nvidia-ctk` present; nvidia runtime in `daemon.json`
- **Network** — `ip_forward=1`; Vast port-range file if the daemon has been installed
- **Vast** — `vastai.service` active and `/var/lib/vastai_kaalia/api_key` present

## Project layout

```
scripts/vast-host-setup      Guided CLI
scripts/bootstrap-host.sh    Ubuntu + drivers + Docker + nvidia-ctk
scripts/install-vast-daemon.sh
scripts/install-dashboard.sh
scripts/optimize/            Real checks + safe fixes
client/                      React dark-terminal dashboard
server/                      Express API
shared/                      Zod contracts + Drizzle schema
docs/                        Host install, safety, Vast registration
docs/legacy/                 Stale Replit / WinSCP transfer notes
```

## What was revived vs rewritten

See [docs/AUDIT.md](docs/AUDIT.md). Short version: the React/Express dashboard UI was kept; simulated “always fail / fake success” optimizer APIs were replaced with real host scripts; deploy/setup no longer hard-code a DB password or start production via `tsx`; Replit/Windows zip-transfer docs were archived.

## License

MIT
