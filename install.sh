#!/bin/bash
# VLESS + Reality VPN Installer v1.0
# Автоматическая установка и настройка Xray с протоколом Reality
# GitHub: https://github.com/vless-reality-installer/vless-reality-installer
set -e
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
print_status(){ echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning(){ echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error(){ echo -e "${RED}[ERROR]${NC} $1"; }
print_success(){ echo -e "${GREEN}[SUCCESS]${NC} $1"; }
check_root(){ if [[ $EUID -ne 0 ]]; then print_error "Этот скрипт должен запускаться с правами root!"; exit 1; fi; }
detect_os(){ print_status "Определяем операционную систему..."; if [[ -f /etc/os-release ]]; then . /etc/os-release; case $ID in ubuntu) OS="ubuntu"; PM="apt";; debian) OS="debian"; PM="apt-get";; centos|rhel|rocky|almalinux) OS="centos"; if command -v dnf &> /dev/null; then PM="dnf"; else PM="yum"; fi;; fedora) OS="fedora"; PM="dnf";; *) if [[ ${ID_LIKE:-} == *"debian"* ]]; then OS="debian"; PM="apt-get"; elif [[ ${ID_LIKE:-} == *"rhel"* ]] || [[ ${ID_LIKE:-} == *"fedora"* ]]; then OS="centos"; PM="yum"; else print_warning "Неизвестный дистрибутив: ${ID:-unknown}, пытаемся определить автоматически..."; fi;; esac; fi; if [[ -z "$OS" ]]; then if [[ -f /etc/redhat-release ]]; then OS="centos"; PM="yum"; elif grep -Eqi "debian" /etc/issue 2>/dev/null; then OS="debian"; PM="apt-get"; elif grep -Eqi "ubuntu" /etc/issue 2>/dev/null; then OS="ubuntu"; PM="apt"; elif grep -Eqi "debian" /proc/version 2>/dev/null; then OS="debian"; PM="apt-get"; elif grep -Eqi "ubuntu" /proc/version 2>/dev/null; then OS="ubuntu"; PM="apt"; elif grep -Eqi "centos|red hat|redhat" /proc/version 2>/dev/null; then OS="centos"; PM="yum"; else print_error "Неподдерживаемая операционная система!"; print_error "Поддерживаются: Ubuntu, Debian, CentOS, RHEL, Rocky Linux, AlmaLinux"; exit 1; fi; fi; if ! command -v "$PM" &> /dev/null; then if [[ "$PM" == "apt" ]] && command -v apt-get &> /dev/null; then PM="apt-get"; elif [[ "$PM" == "dnf" ]] && command -v yum &> /dev/null; then PM="yum"; else print_error "Пакетный менеджер $PM не найден!"; exit 1; fi; fi; print_success "Обнаружена ОС: $OS, пакетный менеджер: $PM"; }
