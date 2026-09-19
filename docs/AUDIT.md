# Audit: VastProject vs stale Replit docs

## Decision: stay on VastProject

| Repo | State |
| --- | --- |
| [VastProject](https://github.com/Unbound-Infotech-Corporation/VastProject) | React / Express / Postgres dashboard, deploy scripts, this work |
| [VastAI](https://github.com/Unbound-Infotech-Corporation/VastAI) | Empty (GitHub 409, no default branch) |

Migrating to VastAI would copy the stack into a blank repo and lose history. Continue VastProject.

## What was stale (Replit-era)

- `START_HERE.md`, `DOWNLOAD_FILES.md`, `SIMPLE_DOWNLOAD.md`, `TRANSFER_GUIDE.md`, `WINDOWS_SETUP.md`, `QUICK_START.txt` — Replit zip / WinSCP / PuTTY “chris@192.168…” transfer fiction
- README claimed “production-ready” Ubuntu 22-only optimizer
- `GET /api/status` and `POST /api/optimize` were **simulated** (`setTimeout(2000)` + hardcoded messages)
- `deploy.sh` / `setup.sh` used invalid `CREATE USER IF NOT EXISTS` (PostgreSQL 14), hardcoded `vastai_secure_2024`, and `node --loader tsx` instead of `npm run build`
- systemd unit would not survive a clean production start
- No Vast host bootstrap (NVIDIA / Docker / daemon / ports)
- No API auth, rate limit, or disk-wipe guard

Moved those transfer notes to `docs/legacy/` so they are not the default path.

## What was revived

- Dark terminal dashboard (glass panels, scanline, StatusCard, LogTerminal)
- Express + Vite + Drizzle/Postgres schema for optimization logs
- shadcn/ui + Tailwind cyberpunk theme
- `deploy.sh` as the dashboard installer (rewritten, not discarded)

## What was rewritten / added

- Real host checks (`server/lib/checks.ts`) against this machine
- Allowlisted optimizer (`scripts/host/optimize-safe.sh` + token + confirm)
- Ubuntu 22.04/24.04 host bootstrap aligned with public Vast / Docker / NVIDIA docs
- Destructive XFS helper isolated and triple-gated
- Memory log fallback when `DATABASE_URL` is unset (dev / CI)
- README new-machine → rent path and safety warnings
- Tests for parsers and the optimizer allowlist
