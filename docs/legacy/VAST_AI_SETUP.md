# Vast.AI Server Optimization Dashboard - Deployment Guide

## Prerequisites

Your Ubuntu 22 server needs:
- Node.js 18+ 
- PostgreSQL 14+
- npm

## Quick Setup on Ubuntu 22

### 1. Install Node.js and npm
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### 2. Install PostgreSQL
```bash
sudo apt-get install -y postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### 3. Create PostgreSQL User and Database
```bash
sudo -u postgres psql << EOF
CREATE USER vastai_user WITH PASSWORD 'your_secure_password';
CREATE DATABASE vastai_optimizer OWNER vastai_user;
ALTER USER vastai_user CREATEDB;
\q
EOF
```

### 4. Clone/Copy Project Files
```bash
cd /opt
sudo git clone <your-repo-url> vast-optimizer
# OR manually copy the files to /opt/vast-optimizer
cd /opt/vast-optimizer
```

### 5. Set Environment Variables
Create `.env` file:
```bash
cat > /opt/vast-optimizer/.env << EOF
DATABASE_URL=postgresql://vastai_user:your_secure_password@localhost:5432/vastai_optimizer
NODE_ENV=production
PORT=5000
EOF
```

### 6. Install Dependencies and Setup Database
```bash
cd /opt/vast-optimizer
npm install
npm run db:push
```

### 7. Start the Application
```bash
npm run dev
```

The app will be available at `http://your-server-ip:5000`

## Systemd Service (Auto-start on Reboot)

Create `/etc/systemd/system/vast-optimizer.service`:
```ini
[Unit]
Description=Vast.AI Optimizer Dashboard
After=network.target postgresql.service

[Service]
Type=simple
User=node
WorkingDirectory=/opt/vast-optimizer
Environment="NODE_ENV=production"
EnvironmentFile=/opt/vast-optimizer/.env
ExecStart=/usr/bin/node --loader tsx server/index.ts
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable vast-optimizer
sudo systemctl start vast-optimizer
sudo systemctl status vast-optimizer
```

View logs:
```bash
sudo journalctl -u vast-optimizer -f
```

## Firewall Setup
```bash
sudo ufw allow 5000/tcp
sudo ufw allow 22/tcp
```

## Troubleshooting

**Port already in use:**
```bash
sudo lsof -i :5000
sudo kill -9 <PID>
```

**Database connection failed:**
```bash
psql -h localhost -U vastai_user -d vastai_optimizer
```

**Check PostgreSQL status:**
```bash
sudo systemctl status postgresql
```
