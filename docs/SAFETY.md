# Safety

These tools run as root for driver/Docker/disk work. Treat them like any other host-provisioning kit.

## Never implicit

| Action | Default | How to do it on purpose |
| --- | --- | --- |
| `mkfs` / wipe a disk | **No** | `./scripts/optimize/fix-storage.sh --confirm-wipe /dev/DISK` + type the path again |
| Overwrite `/etc/docker/daemon.json` | Merge only | Manual edit |
| Enable UFW | Adds rules, does not `ufw enable` | You enable after review |
| Install Vast daemon | Asks for a console key | `--auth-key` |
| Dashboard optimize | Off unless `ALLOW_OPTIMIZE=true` | Localhost unless you opt into remote |

`ASSUME_YES=1` skips *non-destructive* prompts. It **cannot** wipe a disk.

## Refused wipe targets

`fix-storage.sh --confirm-wipe` exits if the device appears to back `/`, `/boot`, or `/home`.

## What “Optimize” on the dashboard does

- **GPU** — `nvidia-smi -pm 1` (and enable `nvidia-persistenced` if present)
- **Docker** — `nvidia-ctk runtime configure --runtime=docker` + overlay2 merge (no image delete)
- **Network** — conservative `sysctl.d` values; optional UFW allows if a port range is known
- **Storage** — fstab `pquota,noatime` on an *existing* XFS docker volume; never `mkfs`

## Secrets

- `install-dashboard.sh` generates a random Postgres password into `.env` (mode 600).
- Do not commit `.env`.
- Vast authorization keys expire (~1 hour) and are not stored by this repo.

## Scope of this agent run

No SSH into LAN hosts. No production wipe. Code + docs + scripts only.
