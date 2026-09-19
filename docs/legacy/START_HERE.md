> **OBSOLETE (Replit-era).** Do not follow this for a new host. Use the repository README and `scripts/host/bootstrap.sh`.

# START HERE - Windows User Guide

## Step 1: Download Project from Replit (2 min)

**Look at the top of Replit screen:**
- You'll see a **menu button** (looks like ☰ or three dots)
- Click it
- Select **"Download as zip"** or just **"Download"**
- It downloads everything as `project.zip` to your Windows `Downloads` folder

If you don't see a download button:
- Look on the **left side** of Replit - there's a file/folder icon
- Click it to show the file list
- Find any file and right-click → Download

---

## Step 2: Extract the ZIP on Windows (1 min)

1. Go to `C:\Users\YourName\Downloads\`
2. You'll see `project.zip`
3. **Right-click** → **Extract All** → **Extract**
4. Creates folder: `project` or `replit_project`

---

## Step 3: Upload to Server with WinSCP (5 min)

1. **Download WinSCP**: https://winscp.net/
2. **Install it**
3. **Open WinSCP**
4. **Enter your server details**:
   - Host name: `your-server-ip` (or the number like `192.168.1.50`)
   - User name: `chris`
   - Password: (your password)
   - Click **Login**

5. **Drag files**:
   - Left side: `C:\Users\YourName\Downloads\project\`
   - Right side: `/opt/vast-optimizer/`
   - Select everything in left → Drag to right side

---

## Step 4: Run Setup on Server (5 min)

1. **Open PuTTY** (your SSH terminal)
2. **Paste this one command**:

```bash
cd /opt/vast-optimizer && chmod +x setup.sh && ./setup.sh
```

3. **Wait 5 minutes** - let it install everything
4. Done!

---

## Step 5: Access Your Dashboard

Open in a browser:
```
http://your-server-ip:5000
```

That's it! You now have a working Vast.AI optimizer running on your server.

---

## Common Questions

**Q: Where's my server IP?**
A: In PuTTY window title or wherever you see it listed. Usually looks like `192.168.x.x` or similar.

**Q: Setup is slow?**
A: Normal - it's installing Node.js, PostgreSQL, and dependencies. Let it run.

**Q: What if I get an error?**
A: Screenshot the error and I can help. Usually it's just needing to wait longer or checking PostgreSQL is running.

---

**That's everything you need!**
