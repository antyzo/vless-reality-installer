#!/bin/bash

# VLESS + Reality VPN Installer v1.0
# Автоматическая установка и настройка Xray с протоколом Reality
# GitHub: https://github.com/vless-reality-installer/vless-reality-installer

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Функции для вывода
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Проверка прав root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Этот скрипт должен запускаться с правами root!"
        exit 1
    fi
}

# Определение операционной системы
detect_os() {
    if [[ -f /etc/redhat-release ]]; then
        OS="centos"
        PM="yum"
    elif cat /etc/issue | grep -Eqi "debian"; then
        OS="debian"
        PM="apt-get"
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        OS="ubuntu"
        PM="apt"
    elif cat /proc/version | grep -Eqi "debian"; then
        OS="debian"
        PM="apt-get"
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        OS="ubuntu"
        PM="apt"
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        OS="centos"
        PM="yum"
    else
        print_error "Неподдерживаемая операционная система!"
        exit 1
    fi
    print_status "Обнаружена ОС: $OS"
}

# Установка зависимостей
install_dependencies() {
    print_status "Устанавливаем зависимости..."
    
    if [[ "$PM" == "apt" || "$PM" == "apt-get" ]]; then
        $PM update -y
        $PM install -y curl wget unzip qrencode ufw netstat-inet
    elif [[ "$PM" == "yum" ]]; then
        $PM update -y
        $PM install -y curl wget unzip qrencode firewalld net-tools
    fi
}

# Поиск свободного порта
find_free_port() {
    print_status "Ищем свободный порт..."
    
    # Список предпочтительных портов для VPN
    preferred_ports=(8443 9443 2053 2083 2087 2096 8080 8880 2052 2082 2086 2095)
    
    for port in "${preferred_ports[@]}"; do
        if ! netstat -tuln 2>/dev/null | grep -q ":$port " && ! ss -tuln 2>/dev/null | grep -q ":$port "; then
            VPN_PORT=$port
            print_success "Найден свободный порт: $port"
            return 0
        fi
    done
    
    # Если предпочтительные порты заняты, ищем случайный свободный
    for i in $(seq 10000 65000); do
        if ! netstat -tuln 2>/dev/null | grep -q ":$i " && ! ss -tuln 2>/dev/null | grep -q ":$i "; then
            VPN_PORT=$i
            print_success "Найден свободный порт: $i"
            return 0
        fi
    done
    
    print_error "Не удалось найти свободный порт!"
    exit 1
}

# Получение внешнего IP
get_external_ip() {
    print_status "Получаем внешний IP адрес..."
    
    SERVER_IP=$(curl -s --connect-timeout 5 ifconfig.co) || \
    SERVER_IP=$(curl -s --connect-timeout 5 ipinfo.io/ip) || \
    SERVER_IP=$(curl -s --connect-timeout 5 icanhazip.com)
    
    if [[ -z "$SERVER_IP" ]]; then
        print_error "Не удалось получить внешний IP адрес!"
        exit 1
    fi
    
    print_success "Внешний IP: $SERVER_IP"
}

# Установка Xray
install_xray() {
    print_status "Устанавливаем Xray-core..."
    
    # Скачиваем установочный скрипт
    wget -O install-release.sh https://github.com/XTLS/Xray-install/raw/main/install-release.sh
    chmod +x install-release.sh
    bash install-release.sh
    
    print_success "Xray-core установлен успешно!"
}

# Генерация ключей и UUID
generate_keys() {
    print_status "Генерируем ключи и UUID..."
    
    # Генерируем x25519 ключи для Reality
    KEYS=$(/usr/local/bin/xray x25519)
    PRIVATE_KEY=$(echo "$KEYS" | grep "PrivateKey:" | awk '{print $2}')
    PUBLIC_KEY=$(echo "$KEYS" | grep "Password:" | awk '{print $2}')
    
    # Генерируем Short ID
    SHORT_ID=$(openssl rand -hex 8)
    
    # Генерируем UUID для пользователя
    USER_UUID=$(/usr/local/bin/xray uuid)
    
    print_success "Ключи сгенерированы успешно!"
}

# Выбор домена для маскировки
select_domain() {
    echo
    print_status "Выберите домен для маскировки Reality:"
    echo "1) vk.com (рекомендуется для России)"
    echo "2) google.com"
    echo "3) microsoft.com"
    echo "4) amazon.com"
    echo "5) Указать свой домен"
    echo
    
    read -p "Ваш выбор [1]: " choice
    choice=${choice:-1}
    
    case $choice in
        1) REALITY_DOMAIN="vk.com" ;;
        2) REALITY_DOMAIN="google.com" ;;
        3) REALITY_DOMAIN="microsoft.com" ;;
        4) REALITY_DOMAIN="amazon.com" ;;
        5) 
            read -p "Введите домен: " REALITY_DOMAIN
            if [[ -z "$REALITY_DOMAIN" ]]; then
                REALITY_DOMAIN="vk.com"
            fi
            ;;
        *) REALITY_DOMAIN="vk.com" ;;
    esac
    
    print_success "Выбран домен: $REALITY_DOMAIN"
}

# Создание конфигурации сервера
create_server_config() {
    print_status "Создаем конфигурацию сервера..."
    
    cat > /usr/local/etc/xray/config.json << EOF
{
  "log": {
    "loglevel": "info",
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log"
  },
  "inbounds": [
    {
      "port": $VPN_PORT,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$USER_UUID",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "dest": "$REALITY_DOMAIN:443",
          "serverNames": ["$REALITY_DOMAIN"],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": [
            "$SHORT_ID"
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    }
  ]
}
EOF
    
    print_success "Конфигурация сервера создана!"
}

# Настройка файрвола
configure_firewall() {
    print_status "Настраиваем файрвол..."
    
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        # UFW для Ubuntu/Debian
        if command -v ufw >/dev/null 2>&1; then
            ufw allow $VPN_PORT/tcp
            print_success "Порт $VPN_PORT добавлен в UFW"
        fi
    elif [[ "$OS" == "centos" ]]; then
        # FirewallD для CentOS
        if command -v firewall-cmd >/dev/null 2>&1; then
            systemctl start firewalld 2>/dev/null || true
            systemctl enable firewalld 2>/dev/null || true
            firewall-cmd --permanent --add-port=$VPN_PORT/tcp
            firewall-cmd --reload
            print_success "Порт $VPN_PORT добавлен в FirewallD"
        fi
    fi
}

# Запуск и включение сервиса
start_xray_service() {
    print_status "Запускаем Xray сервис..."
    
    # Проверяем конфигурацию
    if /usr/local/bin/xray run -test -config /usr/local/etc/xray/config.json; then
        print_success "Конфигурация корректна!"
    else
        print_error "Ошибка в конфигурации!"
        exit 1
    fi
    
    # Перезапускаем сервис
    systemctl restart xray
    systemctl enable xray
    
    sleep 2
    
    if systemctl is-active --quiet xray; then
        print_success "Xray сервис запущен успешно!"
    else
        print_error "Не удалось запустить Xray сервис!"
        systemctl status xray
        exit 1
    fi
}

# Создание клиентских конфигураций
create_client_configs() {
    print_status "Создаем клиентские конфигурации..."
    
    # Создаем директорию для клиентских файлов
    mkdir -p /root/vpn-configs
    
    # VLESS URI
    VLESS_URI="vless://$USER_UUID@$SERVER_IP:$VPN_PORT?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$REALITY_DOMAIN&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp&headerType=none#VPN%20Server%20Reality"
    
    # Сохраняем VLESS URI
    echo "$VLESS_URI" > /root/vpn-configs/vless-uri.txt
    
    # Создаем QR-код
    if command -v qrencode >/dev/null 2>&1; then
        echo "$VLESS_URI" | qrencode -t ANSIUTF8 > /root/vpn-configs/qrcode.txt
        echo "$VLESS_URI" | qrencode -t PNG -o /root/vpn-configs/qrcode.png
        print_success "QR-код создан!"
    fi
    
    # JSON конфигурация для v2Ray клиентов
    cat > /root/vpn-configs/client-config.json << EOF
{
  "policy": {
    "system": {
      "statsInboundDownlink": true,
      "statsOutboundUplink": true,
      "statsOutboundDownlink": true,
      "statsInboundUplink": true
    }
  },
  "log": {
    "loglevel": "info"
  },
  "inbounds": [
    {
      "listen": "[::1]",
      "protocol": "socks",
      "settings": {
        "udp": true
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls",
          "quic"
        ],
        "routeOnly": false,
        "enabled": true
      },
      "tag": "socks",
      "port": 1080
    }
  ],
  "outbounds": [
    {
      "streamSettings": {
        "realitySettings": {
          "serverName": "$REALITY_DOMAIN",
          "publicKey": "$PUBLIC_KEY",
          "shortId": "$SHORT_ID",
          "spiderX": "",
          "fingerprint": "chrome"
        },
        "network": "tcp",
        "tcpSettings": {
          "header": {
            "type": "none"
          }
        },
        "security": "reality"
      },
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "$SERVER_IP",
            "users": [
              {
                "flow": "xtls-rprx-vision",
                "encryption": "none",
                "id": "$USER_UUID"
              }
            ],
            "port": $VPN_PORT
          }
        ]
      },
      "tag": "proxy"
    },
    {
      "protocol": "blackhole",
      "settings": {
        "response": {
          "type": "none"
        }
      },
      "tag": "block"
    },
    {
      "protocol": "freedom",
      "settings": {},
      "tag": "direct"
    }
  ],
  "id": "$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid)",
  "remarks": "VPN Server Reality 🚀",
  "stats": {}
}
EOF
    
    print_success "Клиентские конфигурации созданы!"
}

# Вывод информации о подключении
show_connection_info() {
    echo
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    🎉 УСТАНОВКА ЗАВЕРШЕНА! 🎉                   ║${NC}"
    echo -e "${GREEN}╠════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║                                                                ║${NC}"
    echo -e "${GREEN}║  📋 Параметры подключения:                                     ║${NC}"
    echo -e "${GREEN}║  ┌─────────────────────────────────────────────────────────┐  ║${NC}"
    echo -e "${GREEN}║  │ Протокол: VLESS + Reality                              │  ║${NC}"
    printf "${GREEN}║  │ Сервер: ${CYAN}%-47s${GREEN} │  ║${NC}\n" "$SERVER_IP:$VPN_PORT"
    printf "${GREEN}║  │ UUID: ${CYAN}%-49s${GREEN} │  ║${NC}\n" "$USER_UUID"
    printf "${GREEN}║  │ Маскировка: ${CYAN}%-43s${GREEN} │  ║${NC}\n" "$REALITY_DOMAIN"
    echo -e "${GREEN}║  └─────────────────────────────────────────────────────────┘  ║${NC}"
    echo -e "${GREEN}║                                                                ║${NC}"
    echo -e "${GREEN}║  📁 Файлы клиентов сохранены в: ${YELLOW}/root/vpn-configs/${GREEN}           ║${NC}"
    echo -e "${GREEN}║                                                                ║${NC}"
    
    if [[ -f /root/vpn-configs/qrcode.txt ]]; then
        echo -e "${GREEN}║  📱 QR-код для подключения:                                   ║${NC}"
        echo -e "${GREEN}║                                                                ║${NC}"
        # Выводим QR-код из файла с отступом
        while IFS= read -r line; do
            printf "${GREEN}║${NC} %-62s ${GREEN}║${NC}\n" "$line"
        done < /root/vpn-configs/qrcode.txt
        echo -e "${GREEN}║                                                                ║${NC}"
    fi
    
    echo -e "${GREEN}║  📱 Приложения для подключения:                               ║${NC}"
    echo -e "${GREEN}║    • v2RayTun (Android)                                       ║${NC}"
    echo -e "${GREEN}║    • v2rayN (Windows)                                         ║${NC}"
    echo -e "${GREEN}║    • Qv2ray (Linux)                                           ║${NC}"
    echo -e "${GREEN}║    • FairVPN (iOS)                                            ║${NC}"
    echo -e "${GREEN}║                                                                ║${NC}"
    echo -e "${GREEN}║  🎯 Управление сервисом:                                      ║${NC}"
    echo -e "${GREEN}║    systemctl start|stop|restart|status xray                  ║${NC}"
    echo -e "${GREEN}║                                                                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${YELLOW}📱 VLESS URI:${NC}"
    echo "$VLESS_URI"
    echo
}

# Основная функция установки
main() {
    clear
    echo -e "${PURPLE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║              VLESS + Reality VPN Installer v1.0                ║${NC}"
    echo -e "${PURPLE}║            Автоматическая установка Xray с Reality            ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    print_status "Начинаем установку..."
    
    check_root
    detect_os
    install_dependencies
    find_free_port
    get_external_ip
    install_xray
    generate_keys
    select_domain
    create_server_config
    configure_firewall
    start_xray_service
    create_client_configs
    show_connection_info
    
    print_success "🎉 VPN сервер успешно установлен и настроен!"
    echo
    echo -e "${YELLOW}💡 Файлы конфигурации сохранены в /root/vpn-configs/${NC}"
    echo -e "${YELLOW}💡 QR-код: /root/vpn-configs/qrcode.png${NC}"
    echo -e "${YELLOW}💡 VLESS URI: /root/vpn-configs/vless-uri.txt${NC}"
}

# Запускаем основную функцию
main "$@"
