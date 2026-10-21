#!/bin/bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# Configure hyprpolkitagent to start in user sessions (default.target)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "Failed to change directory to $PARENT_DIR"; exit 1; }

# Source the global functions script (for colored output)
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi

LOG="Install-Logs/install-$(date +%d-%H%M%S)_polkit-setup.log"

if ! systemctl --user list-unit-files 2>/dev/null | grep -q '^hyprpolkitagent\.service'; then
  echo "${WARN} hyprpolkitagent.service not found in user units. Skipping polkit setup." | tee -a "$LOG"
  exit 0
fi
# Skip if another polkit agent is already running
if pgrep -u "$UID" -f 'xfce-polkit|polkit-gnome-authentication-agent-1|polkit-kde-authentication-agent-1|hyprpolkitagent' >/dev/null 2>&1; then
  echo "${NOTE} Polkit agent already running. Skipping hyprpolkitagent setup." | tee -a "$LOG"
  exit 0
fi

OVERRIDE_DIR="$HOME/.config/systemd/user/hyprpolkitagent.service.d"
OVERRIDE_FILE="$OVERRIDE_DIR/override.conf"

mkdir -p "$OVERRIDE_DIR"
cat >"$OVERRIDE_FILE" <<'EOF'
[Unit]
After=
After=dbus.service
PartOf=

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload 2>&1 | tee -a "$LOG" || true
systemctl --user enable hyprpolkitagent 2>&1 | tee -a "$LOG" || true
systemctl --user start hyprpolkitagent 2>&1 | tee -a "$LOG" || true

echo "${OK} hyprpolkitagent override configured and service started." | tee -a "$LOG"
