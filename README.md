# Vast.AI Server Optimization Dashboard

A production-ready web dashboard to monitor and optimize your Ubuntu 22 server settings for Vast.AI verification. Built with React, Node.js, Express, and PostgreSQL.

## Features

✅ **System Status Dashboard** - Real-time status checks for:
- Storage configuration
- GPU driver settings  
- Docker daemon optimization
- Network settings

✅ **One-Click Optimization** - Run optimization scripts for individual components or all at once

✅ **Optimization Logs** - Track all optimization runs with timestamps and results

✅ **Dark Mode Terminal UI** - Professional server admin interface

## Quick Start (PuTTY/SSH)

### Step 1: Copy Files to Your Server
```bash
# On your Ubuntu 22 server via PuTTY
mkdir -p /opt/vast-optimizer
cd /opt/vast-optimizer

# Then copy all project files here (git clone or manual copy)
```

### Step 2: Run Automated Setup
```bash
cd /opt/vast-optimizer
chmod +x deploy.sh
./deploy.sh
```

This automatically installs:
- Node.js 20
- PostgreSQL 14
- Project dependencies
- Database schema
- Systemd service for auto-start

### Step 3: Access Dashboard
```
http://your-server-ip:5000
```

## Manual Setup (Alternative)

See `VAST_AI_SETUP.md` for detailed step-by-step instructions.

## Running the App

### Development
```bash
npm run dev
```
Runs on `http://localhost:5000`

### Production
```bash
npm run build
npm run start
```

### Using Systemd Service
```bash
sudo systemctl status vast-optimizer      # Check status
sudo systemctl restart vast-optimizer     # Restart
sudo journalctl -u vast-optimizer -f      # View logs
```

## Project Structure

```
├── client/                # React frontend (TypeScript + Vite)
│   ├── src/
│   │   ├── pages/         # Dashboard page
│   │   ├── components/    # UI components
│   │   └── App.tsx        # Main app
│   └── index.html
├── server/                # Express backend
│   ├── routes.ts          # API endpoints
│   ├── storage.ts         # Database operations
│   ├── db.ts              # Database connection
│   └── index.ts           # Server entry
├── shared/                # Shared types
│   ├── schema.ts          # Drizzle ORM + Zod types
│   └── routes.ts          # API contracts
├── deploy.sh              # Automated setup script
└── VAST_AI_SETUP.md       # Detailed setup guide
```

## API Endpoints

- `GET /api/status` - Get current system status
- `POST /api/optimize` - Run optimization (body: `{ component: 'Storage'|'GPU'|'Docker'|'Network'|'All' }`)
- `GET /api/logs` - Get optimization history

## Environment Variables

Copy `.env.example` to `.env` and update:

```bash
DATABASE_URL=postgresql://user:password@localhost:5432/vastai_optimizer
NODE_ENV=production
PORT=5000
```

## Troubleshooting

**Port 5000 already in use?**
```bash
sudo lsof -i :5000
sudo kill -9 <PID>
```

**PostgreSQL connection failed?**
```bash
sudo systemctl status postgresql
sudo systemctl restart postgresql
```

**Service won't start?**
```bash
sudo journalctl -u vast-optimizer -n 50 -e
```

## Technology Stack

- **Frontend**: React 18, Vite, TypeScript, Tailwind CSS, shadcn/ui
- **Backend**: Node.js, Express 5, TypeScript
- **Database**: PostgreSQL, Drizzle ORM
- **Validation**: Zod
- **Styling**: Dark mode terminal theme

## License

MIT
