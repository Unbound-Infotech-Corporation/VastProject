#!/usr/bin/env bash
# Build and install the Vast Host Setup dashboard as a systemd service.
# Idempotent. Generates a random DB password. Uses the production build
# (node dist/index.cjs), not tsx.

set -euo pipefail
# shellcheck disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

ROOT="$(repo_root)"
cd "$ROOT"

PORT="${PORT:-5000}"
DB_NAME="${DB_NAME:-vastai_optimizer}"
DB_USER="${DB_USER:-vastai_user}"
SERVICE_NAME="vast-optimizer"
SKIP_DB=0

usage() {
  cat <<EOF
Usage: $0 [--port N] [--skip-db]

Install Node.js 20 (if needed), optional PostgreSQL, build the dashboard,
and enable systemd unit ${SERVICE_NAME}.

  --port N     Listen port (default 5000)
  --skip-db    Do not install PostgreSQL; dashboard uses in-memory logs
  -y, --yes    Assume yes for prompts
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --port) PORT="${2:-5000}"; shift 2 ;;
    --skip-db) SKIP_DB=1; shift ;;
    -y|--yes) ASSUME_YES=1; export ASSUME_YES; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

require_linux
[[ -f "$ROOT/package.json" ]] || die "Run this from a VastProject checkout (package.json missing)."

if is_root; then
  die "Run as a normal user with sudo, not as root. The service will run as ${USER}."
fi

confirm "Install/update the dashboard service on this machine?" || die "Aborted."

if ! have_cmd node || [[ "$(node -v | sed 's/v//' | cut -d. -f1)" -lt 20 ]]; then
  log "Installing Node.js 20 from NodeSource..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo_cmd -E bash -
  sudo_cmd apt-get install -y nodejs
fi
ok "Node $(node -v)"

if [[ "$SKIP_DB" -eq 0 ]]; then
  if ! have_cmd psql; then
    log "Installing PostgreSQL..."
    sudo_cmd apt-get update
    sudo_cmd DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql postgresql-contrib
  fi
  sudo_cmd systemctl enable --now postgresql

  if [[ -f "$ROOT/.env" ]] && grep -q '^DATABASE_URL=' "$ROOT/.env"; then
    log "Keeping existing DATABASE_URL in .env"
    # shellcheck disable=SC1091
    set -a; . "$ROOT/.env"; set +a
  else
    DB_PASS="$(python3 - <<'PY'
import secrets
print(secrets.token_urlsafe(24))
PY
)"
    log "Creating PostgreSQL role/database (idempotent)..."
    sudo_cmd -u postgres psql -v ON_ERROR_STOP=1 <<SQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${DB_USER}') THEN
    CREATE ROLE ${DB_USER} LOGIN PASSWORD '${DB_PASS}';
  ELSE
    ALTER ROLE ${DB_USER} LOGIN PASSWORD '${DB_PASS}';
  END IF;
END
\$\$;
SELECT 'CREATE DATABASE ${DB_NAME} OWNER ${DB_USER}'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${DB_NAME}')\gexec
ALTER ROLE ${DB_USER} CREATEDB;
SQL
    umask 077
    cat > "$ROOT/.env" <<EOF
DATABASE_URL=postgresql://${DB_USER}:${DB_PASS}@127.0.0.1:5432/${DB_NAME}
NODE_ENV=production
PORT=${PORT}
ALLOW_OPTIMIZE=true
EOF
    ok "Wrote ${ROOT}/.env (mode 600)."
  fi
else
  umask 077
  if [[ ! -f "$ROOT/.env" ]]; then
    cat > "$ROOT/.env" <<EOF
NODE_ENV=production
PORT=${PORT}
ALLOW_OPTIMIZE=true
EOF
  fi
  warn "Skipping PostgreSQL. Logs will be stored in memory and reset on restart."
fi

log "Installing npm dependencies..."
npm install

log "Building production bundle..."
npm run build

if [[ "$SKIP_DB" -eq 0 && -n "${DATABASE_URL:-}" ]]; then
  log "Pushing database schema..."
  npm run db:push || warn "db:push failed; dashboard will still start if tables already exist."
fi

node_bin="$(command -v node)"
[[ -x "$node_bin" ]] || die "node binary not found."
[[ -f "$ROOT/dist/index.cjs" ]] || die "Build did not produce dist/index.cjs."

log "Writing systemd unit /etc/systemd/system/${SERVICE_NAME}.service"
sudo_cmd tee "/etc/systemd/system/${SERVICE_NAME}.service" >/dev/null <<EOF
[Unit]
Description=Vast Host Setup dashboard
After=network.target
Wants=postgresql.service

[Service]
Type=simple
User=${USER}
WorkingDirectory=${ROOT}
Environment=NODE_ENV=production
EnvironmentFile=-${ROOT}/.env
ExecStart=${node_bin} ${ROOT}/dist/index.cjs
Restart=always
RestartSec=5
# Do not run optimizations as a more privileged user than the dashboard.

[Install]
WantedBy=multi-user.target
EOF

sudo_cmd systemctl daemon-reload
sudo_cmd systemctl enable "${SERVICE_NAME}"
sudo_cmd systemctl restart "${SERVICE_NAME}"
sleep 1
sudo_cmd systemctl --no-pager --full status "${SERVICE_NAME}" || true

ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
echo
ok "Dashboard service ${SERVICE_NAME} is installed."
echo "  Local:   http://127.0.0.1:${PORT}"
[[ -n "$ip" ]] && echo "  Network: http://${ip}:${PORT}"
echo "  Status:  sudo systemctl status ${SERVICE_NAME}"
echo "  Logs:    sudo journalctl -u ${SERVICE_NAME} -f"
echo
warn "The optimize buttons run safe fixes only. Disk formatting is CLI-only with --confirm-wipe."
