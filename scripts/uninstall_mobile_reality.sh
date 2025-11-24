#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo "Run as root"; exit 1; }
PORT=${1:-8443}
SYSTEMD="/etc/systemd/system/xray-reality-${PORT}.service"
CONF="/etc/xray/xray-reality-${PORT}.json"

systemctl disable --now "xray-reality-${PORT}.service" 2>/dev/null || true
rm -f "$SYSTEMD"
systemctl daemon-reload
rm -f "$CONF"
rm -f "/var/log/xray/reality-${PORT}-access.log" "/var/log/xray/reality-${PORT}-error.log" 2>/dev/null || true
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then ufw delete allow ${PORT}/tcp >/dev/null 2>&1 || true; fi
echo "Removed Reality service on port ${PORT}"
