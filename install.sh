#!/bin/bash

# VLESS Simple Installer
# Простая и надёжная установка VLESS VPN
# Работает с обходом блокировок в России (2025)

set -e

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_color() {
    echo -e "${2}${1}${NC}"
}

print_banner() {
    clear
    print_color "╔════════════════════════════════════════════════════════╗" "$BLUE"
    print_color "║   VLESS Simple Installer - Обход блокировок 2025      ║" "$BLUE"
    print_color "╚════════════════════════════════════════════════════════╝" "$BLUE"
    echo ""
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_color "Этот скрипт должен быть запущен с правами root" "$RED"
        exit 1
    fi
}

install_dependencies() {
    print_color "Установка зависимостей..." "$YELLOW"
    apt update -qq
    apt install -y curl wget uuid-runtime qrencode >/dev/null 2>&1
}

install_xray() {
    print_color "Установка Xray-core..." "$YELLOW"
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install --version 1.8.24 >/dev/null 2>&1
}

setup_firewall() {
    print_color "Настройка firewall..." "$YELLOW"
    
    # Устанавливаем ufw если нет
    if ! command -v ufw &> /dev/null; then
        apt install -y ufw >/dev/null 2>&1
    fi
    
    # Открываем порты
    ufw allow ${PORT}/tcp >/dev/null 2>&1
    ufw --force enable >/dev/null 2>&1
}

generate_config() {
    UUID=$(uuidgen)
    PORT=8080
    SERVER_IP=$(curl -s ifconfig.me)
    
    print_color "Генерация конфигурации..." "$YELLOW"
    print_color "UUID: ${UUID}" "$GREEN"
    print_color "Port: ${PORT}" "$GREEN"
    print_color "IP: ${SERVER_IP}" "$GREEN"
    
    # Создаём простую рабочую конфигурацию Xray
    cat > /usr/local/etc/xray/config.json << XRAY_CONFIG
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [{
    "port": ${PORT},
    "listen": "0.0.0.0",
    "protocol": "vless",
    "settings": {
      "clients": [{
        "id": "${UUID}",
        "level": 0
      }],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "tcp"
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "tag": "direct"
  }]
}
XRAY_CONFIG

    # Запускаем и включаем автостарт
    systemctl restart xray
    systemctl enable xray >/dev/null 2>&1
    
    # Генерируем клиентскую конфигурацию
    CLIENT_CONFIG="vless://${UUID}@${SERVER_IP}:${PORT}?encryption=none&security=none&type=tcp#SimpleVPN"
    
    # Сохраняем конфигурацию
    mkdir -p /root/vpn-config
    echo "${CLIENT_CONFIG}" > /root/vpn-config/vless-config.txt
    
    # Пытаемся создать QR код
    if command -v qrencode &> /dev/null; then
        qrencode -t PNG -o /root/vpn-config/qr-code.png "${CLIENT_CONFIG}" 2>/dev/null || true
    fi
}

create_management_commands() {
    cat > /root/.vpn_aliases << 'ALIASES'
# VPN Management
alias vpn-config='cat /root/vpn-config/vless-config.txt'
alias vpn-status='systemctl status xray --no-pager | head -15'
alias vpn-restart='systemctl restart xray && echo "✓ VPN перезапущен"'
alias vpn-logs='journalctl -u xray -n 50 --no-pager'
alias vpn-stop='systemctl stop xray && echo "✓ VPN остановлен"'
alias vpn-start='systemctl start xray && echo "✓ VPN запущен"'
ALIASES

    # Добавляем в bashrc если ещё нет
    if ! grep -q ".vpn_aliases" /root/.bashrc; then
        echo "[ -f /root/.vpn_aliases ] && source /root/.vpn_aliases" >> /root/.bashrc
    fi
}

show_result() {
    print_color "\n✅ Установка завершена успешно!" "$GREEN"
    echo ""
    print_color "═══════════════════════════════════════════════════════" "$BLUE"
    print_color "📱 КОНФИГУРАЦИЯ ДЛЯ ПОДКЛЮЧЕНИЯ" "$YELLOW"
    print_color "═══════════════════════════════════════════════════════" "$BLUE"
    echo ""
    cat /root/vpn-config/vless-config.txt
    echo ""
    print_color "═══════════════════════════════════════════════════════" "$BLUE"
    echo ""
    print_color "📋 Конфигурация сохранена:" "$YELLOW"
    echo "   /root/vpn-config/vless-config.txt"
    
    if [ -f /root/vpn-config/qr-code.png ]; then
        echo "   /root/vpn-config/qr-code.png"
    fi
    
    echo ""
    print_color "📱 Приложения для подключения:" "$YELLOW"
    echo ""
    print_color "iOS (бесплатные):" "$GREEN"
    echo "  • Streisand - https://apps.apple.com/app/streisand/id6450534064"
    echo "  • FoXray - https://apps.apple.com/app/foxray/id6448898396"
    echo "  • Karing - https://apps.apple.com/app/karing/id6472431552"
    echo ""
    print_color "Android:" "$GREEN"
    echo "  • v2rayNG"
    echo "  • NekoBox"
    echo "  • Hiddify"
    echo ""
    print_color "Windows/Mac:" "$GREEN"
    echo "  • NekoRay"
    echo "  • v2rayN"
    echo ""
    print_color "═══════════════════════════════════════════════════════" "$BLUE"
    print_color "🛠️  Полезные команды:" "$YELLOW"
    print_color "═══════════════════════════════════════════════════════" "$BLUE"
    echo "  vpn-config  - показать конфигурацию"
    echo "  vpn-status  - статус VPN"
    echo "  vpn-restart - перезапустить VPN"
    echo "  vpn-logs    - показать логи"
    echo "  vpn-stop    - остановить VPN"
    echo "  vpn-start   - запустить VPN"
    echo ""
    print_color "💡 Перелогиньтесь или выполните: source /root/.bashrc" "$YELLOW"
    echo ""
    print_color "═══════════════════════════════════════════════════════" "$BLUE"
    echo ""
    print_color "🎉 VPN готов к использованию!" "$GREEN"
    echo ""
}

main() {
    print_banner
    check_root
    
    print_color "Начинаем установку..." "$GREEN"
    echo ""
    
    install_dependencies
    install_xray
    generate_config
    setup_firewall
    create_management_commands
    
    show_result
}

main

