# 🚀 VLESS + Reality VPN Installer

**Автоматическая установка и настройка Xray с протоколом Reality**

Универсальный скрипт для быстрого развертывания современного VPN сервера с протоколом VLESS + Reality, который эффективно обходит блокировки и маскируется под обычный HTTPS трафик.

## ✨ Особенности

- 🛡️ **Протокол Reality** - новейшая технология маскировки трафика
- 🔒 **VLESS с XTLS** - высокая производительность и безопасность  
- 🎯 **Автоматическая настройка** - полностью автоматизированная установка
- 🌐 **Поддержка множества ОС** - Ubuntu, Debian, CentOS
- 📱 **QR-коды** - мгновенное подключение через мобильные приложения
- 🔧 **Умное определение портов** - автоматический поиск свободных портов
- 📋 **Готовые конфигурации** - файлы для всех популярных клиентов

## 🎮 Быстрый старт

### Одной командой:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/vless-reality-installer/vless-reality-installer/main/install.sh)
```

### Или загрузить и запустить:

```bash
wget https://raw.githubusercontent.com/vless-reality-installer/vless-reality-installer/main/install.sh
chmod +x install.sh
./install.sh
```

## 📋 Требования

- **ОС**: Ubuntu 18.04+, Debian 9+, CentOS 7+
- **Права**: root доступ
- **Память**: минимум 512MB RAM
- **Сеть**: внешний IP адрес

## 🔧 Что делает скрипт

1. **Проверяет систему** - определяет ОС и архитектуру
2. **Устанавливает зависимости** - curl, wget, qrencode и другие
3. **Ищет свободный порт** - автоматически находит доступный порт
4. **Устанавливает Xray-core** - последняю стабильную версию
5. **Генерирует ключи** - создает уникальные ключи Reality
6. **Настраивает сервер** - создает оптимальную конфигурацию
7. **Настраивает файрвол** - открывает необходимые порты
8. **Создает клиентские файлы** - QR-коды, URI, JSON конфигурации

## 📱 Поддерживаемые клиенты

| Платформа | Приложение | Ссылка |
|-----------|------------|--------|
| **Android** | v2rayNG | [Google Play](https://play.google.com/store/apps/details?id=com.v2ray.ang) |
| **Android** | v2RayTun | [GitHub](https://github.com/2dust/v2rayNG) |
| **iOS** | FairVPN | [App Store](https://apps.apple.com/app/fair-vpn/id1533873488) |
| **Windows** | v2rayN | [GitHub](https://github.com/2dust/v2rayN) |
| **Windows** | Qv2ray | [GitHub](https://github.com/Qv2ray/Qv2ray) |
| **macOS** | Qv2ray | [GitHub](https://github.com/Qv2ray/Qv2ray) |
| **Linux** | Qv2ray | [GitHub](https://github.com/Qv2ray/Qv2ray) |

## 🎯 Выбор домена для маскировки

Скрипт предлагает несколько популярных доменов для маскировки Reality:

1. **vk.com** - рекомендуется для России 🇷🇺
2. **google.com** - универсальный выбор 🌍  
3. **microsoft.com** - для корпоративных сетей 🏢
4. **amazon.com** - альтернативный вариант 📦
5. **Свой домен** - можно указать любой популярный сайт

## 📁 Структура файлов

После установки в `/root/vpn-configs/` будут созданы:

```
vpn-configs/
├── vless-uri.txt          # VLESS URI для импорта
├── qrcode.png             # QR-код в формате PNG  
├── qrcode.txt             # QR-код в текстовом виде
└── client-config.json     # JSON конфигурация для клиентов
```

## 🛠️ Управление сервисом

```bash
# Статус сервиса
systemctl status xray

# Перезапуск сервиса  
systemctl restart xray

# Остановка сервиса
systemctl stop xray

# Запуск сервиса
systemctl start xray

# Просмотр логов
journalctl -u xray -f
```

## 📊 Мониторинг

### Проверка работы сервера:
```bash
# Проверка портов
netstat -tlnp | grep xray

# Проверка конфигурации
/usr/local/bin/xray run -test -config /usr/local/etc/xray/config.json

# Просмотр активных подключений
journalctl -u xray --since "1 hour ago"
```

## 🔒 Безопасность

- ✅ Уникальные ключи для каждой установки
- ✅ Reality маскировка под реальные сайты  
- ✅ XTLS шифрование трафика
- ✅ Автоматическая настройка файрвола
- ✅ Минимальная конфигурация для безопасности

## ❓ FAQ

### **В: Какой порт будет использоваться?**
О: Скрипт автоматически найдет свободный порт из списка: 8443, 9443, 2053, 2083, 2087, 2096, 8080, 8880, 2052, 2082, 2086, 2095

### **В: Можно ли изменить настройки после установки?**
О: Да, отредактируйте файл `/usr/local/etc/xray/config.json` и перезапустите сервис

### **В: Как добавить еще одного пользователя?**
О: Добавьте новый UUID в секцию `clients` конфигурации сервера

### **В: Что делать если не работает?**
О: Проверьте статус сервиса: `systemctl status xray` и логи: `journalctl -u xray`

## 🆘 Поддержка

- 📧 **Issues**: [GitHub Issues](https://github.com/vless-reality-installer/vless-reality-installer/issues)
- 📖 **Wiki**: [GitHub Wiki](https://github.com/vless-reality-installer/vless-reality-installer/wiki)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/vless-reality-installer/vless-reality-installer/discussions)

## 📜 Лицензия

MIT License - см. файл [LICENSE](LICENSE)

## 🤝 Вклад в проект

Мы приветствуем вклад сообщества! Пожалуйста:

1. Сделайте Fork репозитория
2. Создайте ветку для ваших изменений  
3. Внесите изменения и протестируйте
4. Создайте Pull Request

## ⭐ Поддержите проект

Если этот проект оказался полезен, поставьте ⭐ Star на GitHub!

---

**⚠️ Отказ от ответственности:**
Этот инструмент предназначен для образовательных и исследовательских целей. Пользователи несут ответственность за соблюдение местного законодательства при использовании VPN технологий.

## 🏷️ Теги

`vpn` `vless` `reality` `xray` `proxy` `censorship` `privacy` `security` `linux` `ubuntu` `debian` `centos`
