# How to Download Files from Replit

## Quick Method: Download ZIP from Replit

1. **Click the three dots menu** (⋮) in the top-right of Replit
2. **Select "Download"**
3. Wait for `replit.zip` or `project.zip` to download to your Windows PC

---

## Alternative: Use Command Line (if Download doesn't work)

### If you see a terminal in Replit:

1. In the terminal, type:
```bash
cd /home/runner/workspace
zip -r vast-optimizer.zip . -x "node_modules/*" "dist/*" ".git/*"
```

2. The file `vast-optimizer.zip` will be created in Replit
3. Click on it in the Files panel (left sidebar) and download

---

## After Downloading the ZIP

### On your Windows PC:

1. **Extract the ZIP** to a folder (e.g., `C:\vast-optimizer\`)
2. **Open WinSCP**
3. Connect to your server (IP, username, password)
4. **Drag the extracted files** to `/opt/vast-optimizer/` on your server
5. **Open PuTTY and run**:
```bash
cd /opt/vast-optimizer
chmod +x setup.sh && ./setup.sh
```

---

## The Files Tab in Replit

If you don't see a Files panel on the left:
- Click the **file icon** (looks like a folder) in the left sidebar
- Or press **Ctrl+B** to toggle the file explorer

The zip file should appear in the file list once created.

---

## Still Having Issues?

The absolute simplest approach:
1. Open PuTTY terminal on your server
2. Type:
```bash
mkdir -p /opt/vast-optimizer && cd /opt/vast-optimizer
git clone https://github.com/your-username/vast-optimizer.git .
chmod +x setup.sh && ./setup.sh
```

(If your code is on GitHub, this downloads everything directly)
