#!/usr/bin/env bash
# Optional desktop launcher for a local GUI session (GNOME/KDE).
# Opens a terminal running the CLI installer. SSH-only hosts can ignore this.

set -euo pipefail
# shellcheck disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

ROOT="$(repo_root)"
TARGET="${XDG_DATA_HOME:-$HOME/.local/share}/applications/vast-host-setup.desktop"
mkdir -p "$(dirname "$TARGET")"

term_exec="x-terminal-emulator"
if have_cmd gnome-terminal; then
  term_exec="gnome-terminal --"
elif have_cmd kgx; then
  term_exec="kgx -e"
elif have_cmd konsole; then
  term_exec="konsole -e"
elif have_cmd xfce4-terminal; then
  term_exec="xfce4-terminal -e"
elif have_cmd xterm; then
  term_exec="xterm -e"
fi

cat > "$TARGET" <<EOF
[Desktop Entry]
Type=Application
Name=Vast Host Setup
Comment=Turn this Ubuntu machine into a Vast.ai GPU host
Exec=${term_exec} ${ROOT}/scripts/vast-host-setup
Terminal=false
Categories=System;Settings;
Keywords=vast;gpu;host;nvidia;docker;
EOF
chmod 644 "$TARGET"
ok "Desktop launcher written to ${TARGET}"
echo "If the dashboard is already running, you can also bookmark http://127.0.0.1:5000"
