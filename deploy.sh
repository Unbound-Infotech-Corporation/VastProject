#!/bin/bash

# Vast.AI Optimizer - Automated Deployment Script
# Run on Ubuntu 22 server

set -e

echo "================================"
echo "Vast.AI Optimizer Setup"
echo "================================"

# Check if running as root for some operations
if [ "$EUID" -eq 0 ]; then 
   echo "Some steps need sudo, please run as regular user"
   exit 1
fi

# Install Node.js
echo "Installing Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install PostgreSQL
echo "Installing PostgreSQL..."
sudo apt-get install -y postgresql postgresql-contrib

# Start PostgreSQL
echo "Starting PostgreSQL..."
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create database and user
echo "Setting up PostgreSQL database..."
sudo -u postgres psql << EOF
CREATE USER IF NOT EXISTS vastai_user WITH PASSWORD 'vastai_secure_2024';
CREATE DATABASE IF NOT EXISTS vastai_optimizer OWNER vastai_user;
ALTER USER vastai_user CREATEDB;
EOF

# Navigate to project directory
PROJECT_DIR="${PWD}"
echo "Project directory: $PROJECT_DIR"

# Create .env file
echo "Creating .env file..."
cat > "$PROJECT_DIR/.env" << EOF
DATABASE_URL=postgresql://vastai_user:vastai_secure_2024@localhost:5432/vastai_optimizer
NODE_ENV=production
PORT=5000
EOF

# Install dependencies
echo "Installing npm dependencies..."
npm install

# Setup database
echo "Setting up database schema..."
npm run db:push

# Create systemd service
echo "Creating systemd service..."
sudo tee /etc/systemd/system/vast-optimizer.service > /dev/null << EOF
[Unit]
Description=Vast.AI Optimizer Dashboard
After=network.target postgresql.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$PROJECT_DIR
Environment="NODE_ENV=production"
EnvironmentFile=$PROJECT_DIR/.env
ExecStart=$(which node) --loader tsx server/index.ts
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
echo "Enabling systemd service..."
sudo systemctl daemon-reload
sudo systemctl enable vast-optimizer
sudo systemctl start vast-optimizer

echo ""
echo "================================"
echo "Setup Complete!"
echo "================================"
echo "Dashboard available at: http://localhost:5000"
echo "Check status: sudo systemctl status vast-optimizer"
echo "View logs: sudo journalctl -u vast-optimizer -f"
echo "================================"
