> **OBSOLETE (Replit-era).** Do not follow this for a new host. Use the repository README and `scripts/host/bootstrap.sh`.

# Windows to Ubuntu Server Setup

## Easiest Method: WinSCP (Recommended)

### 1. Download WinSCP
- Go to https://winscp.net/
- Download and install the portable or installer version
- It's a GUI SFTP client for Windows - very easy to use

### 2. Connect to Your Server
- Open WinSCP
- **Host name**: your-server-ip
- **User name**: chris
- **Password**: your-password
- Click **Login**

### 3. Transfer Files
- Left side: Local folder (C:\path\to\vast-optimizer\)
- Right side: /opt/vast-optimizer
- Select all files (Ctrl+A) in left panel
- Drag to right panel to upload

### 4. Run Setup on Server
- Open PuTTY terminal
- Type:
```bash
cd /opt/vast-optimizer
chmod +x setup.sh && ./setup.sh
```

---

## Alternative: PowerShell SCP (If you have OpenSSH)

```powershell
# In Windows PowerShell:
scp -r "C:\path\to\vast-optimizer\*" chris@your-server-ip:/opt/vast-optimizer/

# Then in PuTTY:
cd /opt/vast-optimizer
chmod +x setup.sh && ./setup.sh
```

---

## Alternative: Git Clone (Simplest if repo is on GitHub)

```bash
# In PuTTY terminal on your server:
mkdir -p /opt/vast-optimizer
cd /opt
git clone https://github.com/your-username/vast-optimizer.git
cd vast-optimizer
chmod +x setup.sh && ./setup.sh
```

---

## Quick Summary

1. **Use WinSCP to drag-and-drop files** from Windows to `/opt/vast-optimizer`
2. **Open PuTTY and SSH to server**
3. **Run**: `cd /opt/vast-optimizer && chmod +x setup.sh && ./setup.sh`
4. **Done!** Access at `http://your-server-ip:5000`

That's it!
