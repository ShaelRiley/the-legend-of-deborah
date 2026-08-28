#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="legend-of-deborah.service"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUN_SCRIPT="$REPO_ROOT/tools/server/run_public_server.sh"
SERVICE_USER="${LOD_SERVICE_USER:-$USER}"
SERVICE_HOME="$(getent passwd "$SERVICE_USER" | cut -d: -f6)"

if [[ -z "$SERVICE_HOME" ]]; then
    echo "Could not determine home directory for service user: $SERVICE_USER" >&2
    exit 1
fi

if [[ ! -x "$RUN_SCRIPT" ]]; then
    echo "Server launch script not found or not executable: $RUN_SCRIPT" >&2
    exit 1
fi

TMP_UNIT="$(mktemp)"
trap 'rm -f "$TMP_UNIT"' EXIT

cat > "$TMP_UNIT" <<EOF
[Unit]
Description=The Legend of Deborah Garry's Mod Dedicated Server
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
Environment=HOME=$SERVICE_HOME
WorkingDirectory=$REPO_ROOT
ExecStart=/bin/bash $RUN_SCRIPT
Restart=on-failure
RestartSec=5
KillMode=control-group
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF

sudo install -m 0644 "$TMP_UNIT" "$SERVICE_PATH"
sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"

echo "Installed and enabled $SERVICE_NAME"
echo "It will start automatically on reboot."
echo

echo "The service was not started now, because a foreground server may already own port 27015."
echo "When ready to hand over from the foreground server:"
echo "  1. Stop the current server with Ctrl+C."
echo "  2. Run: sudo systemctl start $SERVICE_NAME"
echo "  3. Check: sudo systemctl status $SERVICE_NAME --no-pager"
echo "  4. Follow logs: journalctl -u $SERVICE_NAME -f"
