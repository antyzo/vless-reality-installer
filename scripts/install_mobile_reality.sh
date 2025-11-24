#!/usr/bin/env bash
set -Eeuo pipefail

# Mobile-friendly VLESS Reality preset (VK userapi on TCP:8443)
# - runs as separate systemd unit: xray-reality-8443.service
# - does NOT touch existing xray.service
# - mirrors paid-provider pattern: SNI sunN.userapi.com, shortId=ffffffffff, spiderX="/", flow=vision

info()  { echo -e "\e[32m[INFO]\e[0m $*"; }
warn()  { echo -e "\e[33m[WARN]\e[0m $*"; }
err()   { echo -e "\e[31m[ERR ]\e[0m $*"; }

require_root() { [[ $EUID -eq 0 ]] || { err "Run as root"; exit 1; }; }

install_xray() {
  if command -v xray >/dev/null 2>&1; then
    info "xray already installed"
    return
  fi
  info "Installing xray-core"
  bash -c "$(curl -fsSL https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
}

pick_port() {
  local def=${1:-8443}
  read -rp "Port for Reality [${def}]: " p || true
  echo "${p:-$def}"
}

pick_sni() {
  local def=${1:-sun6-21.userapi.com}
  read -rp "SNI (VK userapi shard) [${def}]: " s || true
  echo "${s:-$def}"
}

main() {
  require_root
  install_xray

  local PORT SNI UUID PRIV PUB SID XRAY_BIN
  XRAY_BIN=$(command -v xray || echo /usr/local/bin/xray)
  PORT=$(pick_port 8443)
  SNI=$(pick_sni sun6-21.userapi.com)

  info "Generating keys and UUID"
  local tmp=/tmp/reality-$$.txt
  $XRAY_BIN x25519 > "$tmp"
  PRIV=$(awk '/Private key/{print $3}' "$tmp")
  PUB=$(awk   '/Public key/{print $3}' "$tmp")
  UUID=$(cat /proc/sys/kernel/random/uuid)
  SID=ffffffffff

  info "Writing /etc/xray/xray-reality-${PORT}.json"
  install -d -m 0755 /etc/xray /var/log/xray
  cat > "/etc/xray/xray-reality-${PORT}.json" <<JSON
{
  "log": {"loglevel": "warning", "access": "/var/log/xray/reality-${PORT}-access.log", "error": "/var/log/xray/reality-${PORT}-error.log"},
  "inbounds": [
    {
      "port": ${PORT},
      "protocol": "vless",
      "settings": {
        "clients": [ { "id": "${UUID}", "flow": "xtls-rprx-vision" } ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "${SNI}:443",
          "serverNames": ["${SNI}", "userapi.com", "vk.com", "cdn.vk.com"],
          "privateKey": "${PRIV}",
          "shortIds": ["${SID}"],
          "spiderX": "/",
          "xver": 0
        }
      }
    }
  ],
  "outbounds": [ { "protocol": "freedom", "tag": "direct" } ]
}
JSON

  info "Creating systemd unit xray-reality-${PORT}.service"
  cat > "/etc/systemd/system/xray-reality-${PORT}.service" <<UNIT
[Unit]
Description=Xray Reality (VLESS Vision) on ${PORT}
After=network.target

[Service]
Type=simple
ExecStart=${XRAY_BIN} run -config /etc/xray/xray-reality-${PORT}.json
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
UNIT

  systemctl daemon-reload
  systemctl enable --now "xray-reality-${PORT}.service"

  local IP
  IP=$(curl -fsS ifconfig.me || curl -fsS icanhazip.com || curl -fsS ipinfo.io/ip || echo "YOUR_IP")

  local LINK="vless://${UUID}@${IP}:${PORT}?type=tcp&security=reality&fp=random&pbk=${PUB}&sni=${SNI}&flow=xtls-rprx-vision&sid=${SID}&spx=%2F#Reality-${PORT}-userapi"

  echo
  info "DONE. Import link:"
  echo "$LINK"
  echo
  echo "Params:";
  echo "  UUID:  ${UUID}"
  echo "  PBK:   ${PUB}"
  echo "  SNI:   ${SNI}"
  echo "  Port:  ${PORT} (TCP)"
}

main "$@"
