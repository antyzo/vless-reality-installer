#!/bin/bash

echo "🚀 Создание репозитория vless-reality-installer на GitHub..."

# Создаем репозиторий
gh repo create vless-reality-installer \
  --public \
  --description "🚀 Автоматическая установка VLESS + Reality VPN сервера. Современный обход блокировок с протоколом Reality и маскировкой трафика." \
  --clone=false

echo "✅ Репозиторий создан!"

# Добавляем remote
git remote add origin https://github.com/Triplooker/vless-reality-installer.git

# Отправляем код
echo "📤 Загружаем код на GitHub..."
git push -u origin master

echo "🎉 Проект успешно опубликован!"
echo "🔗 URL: https://github.com/Triplooker/vless-reality-installer"
echo
echo "📋 Команда для установки:"
echo "bash <(curl -Ls https://raw.githubusercontent.com/Triplooker/vless-reality-installer/master/install.sh)"
