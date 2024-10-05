#!/bin/bash

# Создание необходимых директорий, если они не существуют
mkdir -p ~/.ssh        # Директория для SSH ключей
mkdir -p ~/backup_dir   # Директория для хранения бэкапов
mkdir -p ~/scripts      # Директория для хранения скриптов

echo "Все необходимые директории успешно созданы."

rm -rf ~/autoinstall.sh

rm -rf ~/get-pip.py

rm -rf ~/VPNizator

rm -rf ~/XTLS-Reality-bot

sudo systemctl stop vpnizator.service

sudo systemctl stop xtls-reality-bot.service

rm -rf /etc/systemd/system/vpnizator.service

rm -rf /etc/systemd/system/xtls-reality-bot.service

sudo vim /etc/sysctl.conf

rm -rf /usr/local/etc #json.config is also included

rm -rf /usr/local/bin

sudo systemctl stop xray.service

rm -rf /etc/systemd/system/xray.service

rm -rf /etc/systemd/system/xray.service.d

rm -rf /etc/systemd/system/xray@.service

rm -rf /etc/systemd/system/xray@.service.d

rm -rf /usr/local/lib

sudo systemctl stop postgresql

sudo apt-get --purge remove postgresql postgresql-client postgresql-client-common postgresql-common

sudo rm -rf /etc/postgresql
sudo rm -rf /var/lib/postgresql
sudo rm -rf /var/log/postgresql
sudo rm -rf /etc/postgresql-common
sudo rm -rf /usr/lib/postgresql

sudo deluser postgres
sudo delgroup postgres

sudo apt-get autoremove
sudo apt-get autoclean


sudo systemctl daemon-reload

# Скачивание и установка autoinstall.sh из корневого каталога
echo "Скачивание и установка autoinstall.sh..."
sudo wget https://raw.githubusercontent.com/Ardgellan/VPNizator/develop/autoinstall.sh -O /root/autoinstall.sh
sudo chmod +x /root/autoinstall.sh
sudo /root/autoinstall.sh

# В конце скрипта добавляем создание SSH-ключа
echo "Создание SSH-ключа..."
if [ ! -f ~/.ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" <<< y
    echo "SSH-ключ успешно создан."
else
    echo "SSH-ключ уже существует, пропускаем создание."
fi

# Создание authorized_keys, если он не существует, и ожидание ввода
AUTH_KEYS_FILE=~/.ssh/authorized_keys

if [ ! -f "$AUTH_KEYS_FILE" ]; then
    touch "$AUTH_KEYS_FILE"
    echo "Файл authorized_keys был создан."
fi

# Ожидание ввода публичного ключа
echo "Пожалуйста, введите ваш публичный ключ для авторизации:"
read -r public_key

# Добавление ключа в authorized_keys, если он отсутствует
if ! grep -qF "$public_key" "$AUTH_KEYS_FILE"; then
    echo "$public_key" >> "$AUTH_KEYS_FILE"
    echo "Публичный ключ успешно добавлен в authorized_keys."
else
    echo "Публичный ключ уже существует в authorized_keys, пропускаем добавление."
fi

# Завершение скрипта
echo "Скрипт завершен. Все ключи установлены."