# Ubuntu host OS install path

Vast.ai cannot be installed from this cloud agent onto C L’s SuperMicro. Use this on the physical (or local) machine.

Official layout: https://cloud.vast.ai/host/setup/

## 1. Download Ubuntu Server

- **22.04 LTS** or **24.04 LTS** (64-bit AMD64). Vast recommends these for all GPUs.
- ISO: https://releases.ubuntu.com/
- Write the USB with Balena Etcher, `dd`, or another imager.

Ubuntu 20.04 is tolerated by some hosts but is slower and missing newer hardware support. Only use it if you have a specific reason.

## 2. Firmware / boot

- Enable virtualization (VT-x / AMD-V) if you will ever run nested workloads; not required for standard Vast Docker hosts.
- For AMD EPYC, read Vast’s IOMMU notes on the official host setup page before you go to production.
- If you use Secure Boot, Ubuntu’s `ubuntu-drivers` path installs signed modules by default.

## 3. Partition layout (do this in the installer)

Vast software lives on `/`. Docker must live on a **separate XFS** mount.

| Mount | FS | Size |
| --- | --- | --- |
| EFI | vfat | ≥ 256 MB |
| `/` | ext4 | ≥ 80 GB |
| `/var/lib/docker` (or leftover space) | **XFS** | rest of the NVMe/SSD |

If the installer will not mount Docker yet, leave the remaining space **unformatted** and configure it after first boot. Do **not** put Docker on the root ext4 volume if you want Vast storage quotas (`--storage-opt` requires overlay2 on XFS with `pquota`).

Suggested `/etc/fstab` line after you know the UUID:

```
UUID=<uuid>  /var/lib/docker  xfs  rw,auto,pquota,noatime,nofail  0  0
```

Create that filesystem yourself only if you understand it destroys the target:

```bash
# Review lsblk first. This is the dangerous path.
./scripts/optimize/fix-storage.sh --confirm-wipe /dev/DISK
```

## 4. First boot

```bash
sudo apt update && sudo apt upgrade
# Vast hosting overview: disable auto-updates so a driver update
# does not interrupt an active rental.
sudo systemctl disable --now unattended-upgrades
```

Give the host a stable address (DHCP reservation or netplan static IP) so router port-forwards survive reboots.

## 5. Drivers, Docker, toolkit

```bash
git clone https://github.com/Unbound-Infotech-Corporation/VastProject.git
cd VastProject
./scripts/bootstrap-host.sh
sudo reboot
nvidia-smi -q
```

Vast: test the driver **before** running their host installer.

## 6. Network

- Open a **continuous** TCP **and** UDP range to this machine.
- Minimum **3 ports per GPU**; Vast prefers about **100 per GPU**.
- The installer writes `/var/lib/vastai_kaalia/host_port_range`.
- Forward that range on the router to the host’s **LAN** IP, not the public IP.

See [VAST_REGISTRATION.md](VAST_REGISTRATION.md).
