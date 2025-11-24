# VLESS Reality Installer (Mobile-first, 2025)

Минимальный установщик, который поднимает VLESS Reality, устойчивый к блокировкам сотовых операторов РФ.

## Что делает
- Отдельный systemd-сервис `xray-reality-<port>.service` — не трогает существующие установки
- Шаблон, копирующий проверенный у операторов паттерн: `SNI sunN.userapi.com`, `flow=xtls-rprx-vision`, `shortId=ffffffffff`, `spiderX=/`
- Порт по умолчанию 8443 (если занят — возьмёт следующий свободный)

## Быстрый старт
```bash
sudo bash -c "bash <(curl -fsSL https://raw.githubusercontent.com/antyzo/vless-reality-installer/master/scripts/install_mobile_reality.sh)"
```
Либо клон репозитория и:
```bash
sudo ./install.sh
```

## Вывод
Скрипт покажет ссылку для импорта вида:
```
vless://<UUID>@<IP>:<PORT>?type=tcp&security=reality&fp=random&pbk=<PBK>&sni=<SNI>&flow=xtls-rprx-vision&sid=ffffffffff&spx=%2F
```

## Удаление
```bash
sudo bash scripts/uninstall_mobile_reality.sh 8443
```

## Примечания
- Если у оператора не идёт — попробуйте другой шард: `sun8-21.userapi.com`, `cdn.vk.com`
- Популярные альтернативные порты: 4433, 2053, 2087, 2096, 8880
- Репозиторий намеренно минималистичен — без лишних зависимостей и меню
