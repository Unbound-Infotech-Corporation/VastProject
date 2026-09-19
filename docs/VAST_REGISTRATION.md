# Vast.ai host registration

Source of truth: **https://cloud.vast.ai/host/setup/**  
Overview: **https://docs.vast.ai/host/hosting-overview**

This file only restates what those pages (and their documented installer) already say. If the console text disagrees with this repo, **trust the console**.

## Account

- Create a **new host account**. Do not host on your renter/client account (Vast: not supported).
- Open the host setup guide and accept the hosting agreement. The account becomes a hosting account and a Machines link appears.

## Installer

The setup page gives you a **copy button**. The command includes a unique authorization key that expires in about **one hour**. Refresh the page if it expires or you get HTTP 403 (re-accept the agreement).

Documented command shape:

```bash
wget https://console.vast.ai/install -O install
sudo python3 install YOUR_AUTH_KEY --interactive
history -d $((HISTCMD-1))
```

Documented flags:

| Flag | Purpose |
| --- | --- |
| `--interactive` | Prompts for port range / GPU selection |
| `--reset-machine` | New `machine_id` when a machine is stuck or deregistered |

The installer installs Docker, `nvidia-ctk`, and the Vast daemon when they are missing. Vast also says: if drivers are broken, **reinstall NVIDIA drivers first**, then re-run the installer.

This repo’s wrapper (same command, key-only input):

```bash
./scripts/install-vast-daemon.sh --auth-key YOUR_AUTH_KEY
# optional documented flag:
./scripts/install-vast-daemon.sh --auth-key YOUR_AUTH_KEY --reset-machine
```

If Vast changes the download URL, paste and run the console command yourself instead of forcing this wrapper.

## After install

```bash
sudo systemctl status vastai
sudo test -f /var/lib/vastai_kaalia/api_key && echo api_key present
sudo tail -f /var/lib/vastai_kaalia/kaalia.log
```

Healthy logs talk to a real backend IP (not `:0`). `:0` usually means a missing `api_key` — copy a fresh installer command.

Port range (no trailing newline):

```bash
sudo bash -c 'echo -n "50000-50100" > /var/lib/vastai_kaalia/host_port_range'
```

NAT public-IP override:

```bash
sudo bash -c 'echo -n "YOUR.PUBLIC.IP" > /var/lib/vastai_kaalia/host_ipaddr'
sudo systemctl restart vastai
```

## Ports

- Continuous range, **TCP and UDP**.
- At least **3 ports per GPU**; Vast prefers about **100 per GPU**.
- Forward the range on the router to this host’s **private** IP.
- SSH (22/tcp) for you; do not confuse it with instance ports.

## Listing

Once the machine appears on Machines, set pricing / offer end date in the Vast UI or CLI. Honor rental contracts until their end dates. Vast does not support getting a broken host working — use the host-only Discord after linking the host account.
