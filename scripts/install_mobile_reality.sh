#!/usr/bin/env bash
set -Eeuo pipefail
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

info()  { echo -e "\e[32m[INFO]\e[0m $*"; }
warn()  { echo -e "\e[33m[WARN]\e[0m $*"; }
err()   { echo -e "\e[31m[ERR ]\e[0m $*"; }
req_root(){ [[ $EUID -eq 0 ]] || { err "Run as root"; exit 1; }; }

install_xray(){
  if command -v xray >/dev/null 2>&1; then info "xray already installed"; return; fi
  info "Installing xray-core"; bash -c "$(curl -fsSL https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
  hash -r
}

free_port(){ local p=$1; ss -tuln | awk '{print $5}' | sed 's/.*://g' | awk -F']' '{print $NF}' | grep -qx "$p" && return 1 || return 0; }
select_port(){ local p=${1:-8443}; while ! free_port "$p"; do p=$((p+1)); done; echo "$p"; }

generate_reality_keys(){
  local XRAY_BIN out
  XRAY_BIN=$(command -v xray || echo /usr/local/bin/xray)
  if [[ ! -x "$XRAY_BIN" ]]; then err "xray binary not found"; exit 1; fi
  out="$($XRAY_BIN x25519 2>/dev/null || true)"
  PRIV=$(printf '%s\n' "$out" | sed -n 's/^Private key: \(.*\)$/\1/p')
  PUB=$(printf '%s\n' "$out"  | sed -n 's/^Public key: \(.*\)$/\1/p')
  # compatibility patterns
  [[ -n "${PRIV:-}" && -n "${PUB:-}" ]] || {
    PRIV=$(printf '%s\n' "$out" | sed -n 's/^Private\([Kk]ey\)\?: \(.*\)$/\2/p')
    PUB=$(printf '%s\n' "$out"  | sed -n 's/^Public\([Kk]ey\)\?: \(.*\)$/\2/p')
  }
  # fallback to sing-box if available
  if [[ -z "${PRIV:-}" || -z "${PUB:-}" ]]; then
    if command -v sing-box >/dev/null 2>&1; then
      out="$(sing-box generate reality-keypair 2>/dev/null || true)"
      PRIV=$(printf '%s\n' "$out" | sed -n 's/^PrivateKey: \(.*\)$/\1/p')
      PUB=$(printf '%s\n' "$out"  | sed -n 's/^PublicKey: \(.*\)$/\1/p')
    fi
  fi
  if [[ -z "${PRIV:-}" || -z "${PUB:-}" ]]; then
    err "Failed to generate Reality keypair. Check xray installation."
    exit 1
  fi
}

main(){
  req_root; install_xray
  local XRAY_BIN PORT SNI UUID SID
  XRAY_BIN=$(command -v xray || echo /usr/local/bin/xray)

  read -rp "SNI (default sun6-21.userapi.com): " SNI || true; SNI=${SNI:-sun6-21.userapi.com}
  read -rp "Port (default auto starting at 8443): " PORT || true; PORT=${PORT:-}
  [[ -z "$PORT" ]] && PORT=$(select_port 8443)
  info "Using port $PORT and SNI $SNI"

  generate_reality_keys
  UUID=$(cat /proc/sys/kernel/random/uuid)
  SID=ffffffffff

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
