#!/usr/bin/env bash
# Deploy the optimizer dashboard on the Vast host (Ubuntu 22.04/24.04).
# Does not wipe disks. Does not install the Vast daemon.

set -euo pipefail

if [[ "${EUID}" -eq 0 ]]; then
  echo "Run as a normal user with sudo, not as root."
  exit 1
fi

if [[ ! -f package.json ]]; then
  echo "Run this from the VastProject repository root."
  exit 1
fi

echo "================================"
echo "Vast Host Optimizer — dashboard"
echo "================================"

sudo apt-get update
if ! command -v node >/dev/null 2>&1; then
  echo "Installing Node.js 20..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi

if ! command -v psql >/dev/null 2>&1; then
  echo "Installing PostgreSQL..."
  sudo apt-get install -y postgresql postgresql-contrib
fi
sudo systemctl enable --now postgresql

PROJECT_DIR="$(pwd)"
DB_PASS="$(openssl rand -hex 16)"
API_TOKEN="$(openssl rand -hex 24)"

if [[ -f .env ]]; then
  echo "Keeping existing .env (not overwriting secrets)."
else
  sudo -u postgres psql -v ON_ERROR_STOP=1 <<SQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'vastai_user') THEN
    CREATE ROLE vastai_user LOGIN PASSWORD '${DB_PASS}';
  END IF;
END
\$\$;
SELECT 'CREATE DATABASE vastai_optimizer OWNER vastai_user'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'vastai_optimizer')\gexec
ALTER ROLE vastai_user CREATEDB;
SQL

  cat > .env <<EOF
DATABASE_URL=postgresql://vastai_user:${DB_PASS}@localhost:5432/vastai_optimizer
NODE_ENV=production
PORT=5000
OPTIMIZER_API_TOKEN=${API_TOKEN}
EOF
  chmod 600 .env
  echo "Wrote .env with a generated DB password and OPTIMIZER_API_TOKEN."
  echo "Save the token from .env — the dashboard needs it for mutations."
fi

npm install
npm run build
npm run db:push

sudo tee /etc/systemd/system/vast-optimizer.service >/dev/null <<EOF
[Unit]
Description=Vast Host Optimizer Dashboard
After=network.target postgresql.service

[Service]
Type=simple
User=${USER}
WorkingDirectory=${PROJECT_DIR}
Environment=NODE_ENV=production
EnvironmentFile=${PROJECT_DIR}/.env
ExecStart=$(command -v node) ${PROJECT_DIR}/dist/index.cjs
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable vast-optimizer
sudo systemctl restart vast-optimizer

echo
echo "Dashboard: http://$(hostname -I | awk '{print $1}'):5000"
echo "Status:    sudo systemctl status vast-optimizer"
echo "Host setup: sudo bash scripts/host/bootstrap.sh"
echo "Disk wipe is NOT part of this deploy."
