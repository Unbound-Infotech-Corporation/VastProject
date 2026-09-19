# Audit — what worked, what was stale, what changed

Repo: `Unbound-Infotech-Corporation/VastProject`  
Sister repo `VastAI` is empty (no default branch). **Continued here** so history, the dashboard, and existing clones stay valid.

## What already worked

- React 18 + Vite + Tailwind dark “terminal” dashboard (`StatusCard`, `LogTerminal`, glass panels).
- Express API contracts in `shared/routes.ts` (`/api/status`, `/api/optimize`, `/api/logs`).
- Drizzle schema for `optimization_logs`.
- `npm run build` pipeline (`script/build.ts` → `dist/public` + `dist/index.cjs`).

## What was simulated or broken

| Item | Old behavior | Now |
| --- | --- | --- |
| `GET /api/status` | Hard-coded “unoptimized” strings | Runs `scripts/optimize/collect-status.sh` |
| `POST /api/optimize` | `sleep 2` then always “success” | Real check/fix scripts; no disk wipe |
| `deploy.sh` / `setup.sh` | Invalid `CREATE USER IF NOT EXISTS`, hardcoded password `vastai_secure_2024`, production via `node --loader tsx` | Random DB password, idempotent SQL, `node dist/index.cjs` |
| `DATABASE_URL` | Required or the process throws | Optional; in-memory logs |
| Listen | `reusePort: true` always | Off unless `REUSE_PORT=true` |
| Host install | Missing | `bootstrap-host.sh` + Vast daemon wrapper |
| Replit / WinSCP docs | Primary “START HERE” | Moved to `docs/legacy/` |

## Stale docs (archived, not deleted)

- `START_HERE.md`, `DOWNLOAD_FILES.md`, `SIMPLE_DOWNLOAD.md`, `TRANSFER_GUIDE.md`, `WINDOWS_SETUP.md`, `QUICK_START.txt`
- Replit download / WinSCP / hardcoded user `chris`
- `VAST_AI_SETUP.md` only covered the Node dashboard, not Vast hosting

## Verified against public docs (not invented)

- Ubuntu 22.04/24.04, EFI + 80 GB ext4 root, Docker on XFS — Vast host setup page
- `ubuntu-drivers install --gpgpu` — Ubuntu Server NVIDIA docs
- Docker apt repo + `docker-ce` packages — docs.docker.com
- NVIDIA toolkit apt repo + `nvidia-ctk runtime configure --runtime=docker` — NVIDIA docs
- Vast installer: `wget https://console.vast.ai/install` + `python3 install KEY --interactive` / `--reset-machine`
- Daemon paths: `vastai.service`, `/var/lib/vastai_kaalia/{api_key,machine_id,host_port_range}`

If Vast’s console copy-button text changes, use that text.
