# 📋 Команды для работы с GitHub

## 🔐 Авторизация через токен
```bash
echo 'ВАШ_ТОКЕН' | gh auth login --with-token
```

## 📊 Проверка авторизации
```bash
gh auth status
```

## 🚀 Создание репозитория
```bash
./deploy.sh
```

## 📋 Альтернативные команды

### Создание репозитория вручную:
```bash
gh repo create vless-reality-installer --public --description "🚀 VLESS + Reality VPN Installer"
```

### Добавление remote:
```bash
git remote add origin https://github.com/Triplooker/vless-reality-installer.git
```

### Загрузка кода:
```bash
git push -u origin master
```

### Проверка репозитория:
```bash
gh repo view Triplooker/vless-reality-installer
```

## 🔗 Финальные ссылки

- **Репозиторий**: https://github.com/Triplooker/vless-reality-installer  
- **Установка**: `bash <(curl -Ls https://raw.githubusercontent.com/Triplooker/vless-reality-installer/master/install.sh)`
- **Raw install.sh**: https://raw.githubusercontent.com/Triplooker/vless-reality-installer/master/install.sh

