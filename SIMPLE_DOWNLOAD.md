# Download Your Files - SUPER SIMPLE

## In Replit (Right Now):

1. Look at the **left sidebar** - you should see a file tree
   - If you don't see it, click the **file icon** or press **Ctrl+B**

2. In that file list, look for: **`vast-optimizer.tar.gz`**
   - This is your complete project file

3. **Right-click on `vast-optimizer.tar.gz`** → **Download**

4. Save it to your Windows PC (e.g., `Downloads` folder)

---

## On Your Windows PC:

1. **Extract the file**:
   - Right-click `vast-optimizer.tar.gz`
   - Use 7-Zip, WinRAR, or Windows built-in extractor to unzip
   - Creates folder: `vast-optimizer\`

2. **Download WinSCP**: https://winscp.net/

3. **Open WinSCP**:
   - Host: `your-server-ip`
   - User: `chris`
   - Password: `your-password`
   - Click **Login**

4. **Drag and drop**:
   - Left side: `C:\Users\YourUser\Downloads\vast-optimizer\`
   - Right side: `/opt/vast-optimizer/`
   - Drag all files from left to right

5. **Open PuTTY** and type:
```bash
cd /opt/vast-optimizer
chmod +x setup.sh && ./setup.sh
```

6. **Done!** Wait 5 minutes, then access: `http://your-server-ip:5000`

---

## Can't Find the File in Replit?

Click the **menu button** (☰) in Replit → **Download**

This downloads the whole project as one ZIP file.
