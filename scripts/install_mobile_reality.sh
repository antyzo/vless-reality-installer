#!/usr/bin/env bash
set -Eeuo pipefail

info()  { echo -e "\e[32m[INFO]\e[0m $*"; }
warn()  { echo -e "\e[33m[WARN]\e[0m $*"; }
err()   { echo -e "\e[31m[ERR ]\e[0m $*"; }
req_root(){ [[ $EUID -eq 0 ]] || { err "Run as root"; exit 1; }; }

install_xray(){
  if command -v xray >/dev/null 2>&1; then info "xray already installed"; return; fi
  info "Installing xray-core"; bash -c "$(curl -fsSL https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
}

free_port(){ local p=$1; ss -tuln | awk '{print $5}' | grep -q ":$p$" && return 1 || return 0; }
select_port(){ local p=8443; while ! free_port "$p"; do p=$((p+1)); done; echo "$p"; }

main(){
  req_root; install_xray
  local XRAY_BIN PORT SNI tmp PRIV PUB UUID SID
  XRAY_BIN=$(command -v xray || echo /usr/local/bin/xray)
  read -rp "SNI (default sun6-21.userapi.com): " SNI || true; SNI=${SNI:-sun6-21.userapi.com}
  read -rp "Port (default auto starting at 8443): " PORT || true; PORT=${PORT:-}
  [[ -z "$PORT" ]] && PORT=$(select_port)
  info "Using port $PORT and SNI $SNI"

  tmp=$(mktemp); $XRAY_BIN x25519 > "$tmp"; PRIV=$(awk '/Private key/{print $3}' "$tmp"); PUB=$(awk '/Public key/{print $3}' "$tmp"); rm -f "$tmp"
  UUID=$(cat /proc/sys/kernel/random/uuid); SID=ffffffffff

  install -d -m0755 /etc/xray /var/log/xray
  cat > "/etc/xray/xray-reality-${PORT}.json" <<JSON
{
  "log": {"loglevel": "warning", "access": "/var/log/xray/reality-${PORT}-access.log", "error": "/var/log/xray/reality-${PORT}-error.log"},
  "inbounds": [
    {"port": ${PORT}, "protocol": "vless",
     "settings": {"clients": [{"id": "${UUID}", "flow": "xtls-rprx-vision"}], "decryption": "none"},
     "streamSettings": {"network": "tcp", "security": "reality",
        "realitySettings": {"show": false, "dest": "${SNI}:443",
          "serverNames": ["${SNI}", "userapi.com", "vk.com", "cdn.vk.com"],
          "privateKey": "${PRIV}", "shortIds": ["${SID}"], "spiderX": "/", "xver": 0}}}
  ],
  "outbounds": [{"protocol": "freedom", "tag": "direct"}]
}
JSON

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
  systemctl enable --now xray-reality-${PORT}.service

  if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
    ufw allow ${PORT}/tcp >/dev/null 2>&1 || true
  fi

  local IP; IP=$(curl -fsS ifconfig.me || curl -fsS icanhazip.com || curl -fsS ipinfo.io/ip || echo YOUR_IP)
  local LINK="vless://${UUID}@${IP}:${PORT}?type=tcp&security=reality&fp=random&pbk=${PUB}&sni=${SNI}&flow=xtls-rprx-vision&sid=${SID}&spx=%2F#Reality-${PORT}-userapi"
  echo; info "Import link:"; echo "$LINK"; echo
  echo "UUID: ${UUID}"; echo "PBK: ${PUB}"; echo "SNI: ${SNI}"; echo "PORT: ${PORT}"
}

main "$@"
