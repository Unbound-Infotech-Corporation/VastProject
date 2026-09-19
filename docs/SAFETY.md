# Safety rules

## Never from this application

- Format, `mkfs`, `sgdisk`, or repartition any disk via the dashboard or `/api/optimize`
- SSH into a SuperMicro, iDRAC, or any LAN host
- Guess Vast installer flags or reuse an expired host key
- Disable SSH passwords before a working key is confirmed
- Auto-select a “spare” disk for Docker

## Disk wipe

Only `scripts/host/prepare-docker-xfs.sh` may wipe a device. It requires:

1. `--i-understand-this-wipes-disks`
2. `--device /dev/…` that is a block device
3. `--yes-wipe-device` equal to that device’s basename

It refuses the OS/boot disk and mounted `/`, `/boot`, `/boot/efi`. Identify devices with `lsblk` and `blkid` on the machine you are standing at.

Wiping the wrong NVMe destroys the OS and any client data. There is no undo.

## Physical SuperMicro

This cloud agent and this codebase do **not** reach Unbound’s LAN. Do not ask the tooling to wipe or SSH those chassis. Run bootstrap only when you are on the host (console, IPMI, or your own SSH).

## Vast installer

The host install command is issued on [cloud.vast.ai/host/setup/](https://cloud.vast.ai/host/setup/) after you accept the hosting agreement. It is account-specific and short-lived. Community guides show `https://console.vast.ai/install` plus a key; we download that URL only when you supply a key, and we add **no** flags unless you set `VAST_INSTALL_ARGS` or paste the full dashboard command as `VAST_INSTALL_CMD`.
