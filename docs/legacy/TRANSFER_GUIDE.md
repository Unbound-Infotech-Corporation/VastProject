> **OBSOLETE (Replit-era).** Do not follow this for a new host. Use the repository README and `scripts/host/bootstrap.sh`.

# How to Transfer Files to Your Server

## Option 1: Using Git (Recommended if repo is public)
```bash
cd /opt
sudo git clone <your-repo-url> vast-optimizer
cd vast-optimizer
sudo chown -R $USER:$USER .
chmod +x deploy.sh
./deploy.sh
```

## Option 2: Download Archive from Replit (Easiest)

The project has been packaged as `vast-optimizer.tar.gz` (available for download from Replit).

```bash
# On your Ubuntu server via PuTTY:

# 1. Download the archive (you can download from Replit web interface)
# Then transfer to server or use wget if hosted

# 2. Extract it
tar -xzf vast-optimizer.tar.gz -C /opt/vast-optimizer

# 3. Navigate and run setup
cd /opt/vast-optimizer
chmod +x deploy.sh
./deploy.sh
```

## Option 3: Manual SCP Transfer (from your local computer)
```bash
# On your LOCAL computer (not the server):
scp -r /path/to/vast-optimizer chris@your-server-ip:/opt/

# Then on server via PuTTY:
ssh chris@your-server-ip
cd /opt/vast-optimizer
chmod +x deploy.sh
./deploy.sh
```

## Option 4: Copy Files Individually via PuTTY
If you're using PuTTY with PSFTP (PuTTY SFTP client):
```
# In PSFTP:
open chris@your-server-ip
cd /opt/vast-optimizer
mput *
```

## Quick Verification
After transferring files, verify with:
```bash
ls -la /opt/vast-optimizer/
# Should see: deploy.sh, package.json, server/, client/, shared/, etc.
```

---

**Once files are in place**, run:
```bash
cd /opt/vast-optimizer
chmod +x deploy.sh
./deploy.sh
```

The script handles everything else automatically!
