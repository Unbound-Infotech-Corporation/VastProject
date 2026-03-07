#!/bin/bash
set -e

echo "===================================="
echo "Vast.AI Optimizer - Setup"
echo "===================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Check if files exist
if [ ! -f "package.json" ]; then
    echo -e "${RED}Error: package.json not found${NC}"
    echo "Make sure you're in the project directory with all files"
    exit 1
fi

echo "Step 1: Installing Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - > /dev/null 2>&1
sudo apt-get install -y nodejs > /dev/null 2>&1
echo -e "${GREEN}✓ Node.js installed${NC}"

echo "Step 2: Installing PostgreSQL..."
sudo apt-get install -y postgresql postgresql-contrib > /dev/null 2>&1
sudo systemctl start postgresql > /dev/null 2>&1
sudo systemctl enable postgresql > /dev/null 2>&1
echo -e "${GREEN}✓ PostgreSQL installed${NC}"

echo "Step 3: Setting up database..."
sudo -u postgres psql << EOF > /dev/null 2>&1
CREATE USER IF NOT EXISTS vastai_user WITH PASSWORD 'vastai_secure_2024';
CREATE DATABASE IF NOT EXISTS vastai_optimizer OWNER vastai_user;
ALTER USER vastai_user CREATEDB;
EOF
echo -e "${GREEN}✓ Database created${NC}"

echo "Step 4: Creating .env file..."
cat > .env << EOF
DATABASE_URL=postgresql://vastai_user:vastai_secure_2024@localhost:5432/vastai_optimizer
NODE_ENV=production
PORT=5000
EOF
echo -e "${GREEN}✓ .env created${NC}"

echo "Step 5: Installing dependencies..."
npm install > /dev/null 2>&1
echo -e "${GREEN}✓ Dependencies installed${NC}"

echo "Step 6: Setting up database schema..."
npm run db:push > /dev/null 2>&1
echo -e "${GREEN}✓ Database schema created${NC}"

echo "Step 7: Creating systemd service..."
PROJ_DIR=$(pwd)
sudo tee /etc/systemd/system/vast-optimizer.service > /dev/null << EOF
[Unit]
Description=Vast.AI Optimizer Dashboard
After=network.target postgresql.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$PROJ_DIR
Environment="NODE_ENV=production"
EnvironmentFile=$PROJ_DIR/.env
ExecStart=$(which node) --loader tsx server/index.ts
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
echo -e "${GREEN}✓ Systemd service created${NC}"

echo "Step 8: Starting service..."
sudo systemctl daemon-reload > /dev/null 2>&1
sudo systemctl enable vast-optimizer > /dev/null 2>&1
sudo systemctl start vast-optimizer > /dev/null 2>&1
sleep 2
echo -e "${GREEN}✓ Service started${NC}"

echo ""
echo "===================================="
echo -e "${GREEN}Setup Complete!${NC}"
echo "===================================="
echo ""
echo "Dashboard: http://$(hostname -I | awk '{print $1}'):5000"
echo ""
echo "Check status:"
echo "  sudo systemctl status vast-optimizer"
echo ""
echo "View logs:"
echo "  sudo journalctl -u vast-optimizer -f"
echo ""
