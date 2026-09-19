# Host bootstrap (Ubuntu 22.04 / 24.04)

Aligned with public Vast host documentation. Commands and flags below are either from those pages, Ubuntu, Docker, or NVIDIA — not invented Vast installer options.

## Official references

| Topic | URL |
| --- | --- |
| Host setup (installer + disk layout) | https://cloud.vast.ai/host/setup/ |
| Hosting overview | https://docs.vast.ai/host/hosting-overview |
| Verification minima | https://docs.vast.ai/host/verification-stages |
| SSH password off | https://docs.vast.ai/host/disable-ssh-password-login |
| Kernel patch / reboot | https://docs.vast.ai/host/upgrade-kernel |
| Self-test | https://docs.vast.ai/host/how-to-self-test |
| Docker Engine | https://docs.docker.com/engine/install/ubuntu/ |
| NVIDIA Container Toolkit | https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html |

## Script map

| Script | What it does |
| --- | --- |
| `00-preflight.sh` | OS, Secure Boot hint, mounts, sshd probe — no writes |
| `10-ubuntu-prep.sh` | Packages; hold NVIDIA against unattended driver swaps |
| `20-nvidia-driver.sh` | `ubuntu-drivers autoinstall`; `nvidia-smi -pm 1` |
| `30-docker.sh` | Official Docker apt repo + official nvidia-ctk + `nvidia-ctk runtime configure --runtime=docker` |
| `40-vast-daemon.sh` | Your dashboard command or `python3 install <key>` with no extra flags |
| `50-network.sh` | UFW for `/var/lib/vastai_kaalia/host_port_range` or `VAST_PORT_RANGE` |
| `prepare-docker-xfs.sh` | **Destructive** XFS + `pquota,noatime` mount |
| `optimize-safe.sh` | Allowlisted fixes for the API |
| `bootstrap.sh` | Guided runner |

## Verification numbers we treat as current

From [verification-stages](https://docs.vast.ai/host/verification-stages) (prefer this over older “3 ports / 4 GB RAM” blurbs):

- Ubuntu Server 22.04 or 24.04; latest security kernel for that release
- NVIDIA Maxwell+, >7 GB VRAM, CUDA 11.8+, identical models
- 2 physical CPU cores per GPU, AVX, RAM ≥ 95% of total GPU VRAM
- Dedicated Docker SSD ≥ 200 GB; `/` ≥ 20 GB free
- 500 Mbps symmetric, public IPv4, **5 ports/GPU** (100 recommended)
- SSH keys only; unique key per machine; Secure Boot off
- Dedicated machine — no desktop/mining/personal jobs while listed

Host setup still documents EFI 256 MB, root ext4 80 GB+, Docker on XFS, and `nvidia-smi -q` before continuing.

## After bootstrap

```bash
# Confirm driver
nvidia-smi -q

# Optional GPU-in-Docker smoke test (pulls an image; not during a rental)
docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi

# List from host UI, then:
vastai self-test machine <machine_id>
```

Uninstall documented by Vast: https://s3.amazonaws.com/vast.ai/uninstall
