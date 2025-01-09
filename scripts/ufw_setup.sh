#!/bin/bash

# Красная тревога в начале
echo -e "\033[31mВНИМАНИЕ! Этот скрипт настроит брандмауэр UFW для вашего сервера."
echo -e "Будут разрешены соединения с указанных IP-адресов, а все остальные соединения на эти порты будут заблокированы."
echo -e "Вы уверены, что хотите продолжить? (yes/no)"
read confirm
if [[ "$confirm" != "yes" ]]; then
    echo "Процесс отменен."
    exit 1
fi

# Проверка, установлен ли ufw
if ! command -v ufw &> /dev/null; then
    echo "UFW не установлен. Устанавливаю..."
    sudo apt-get update
    sudo apt-get install -y ufw
else
    echo "UFW уже установлен."
fi

sudo ufw default deny incoming
sudo ufw default allow outgoing

sudo ufw allow ssh

sudo ufw allow from 46.138.13.154 # Личный Компьютер
sudo ufw allow from 95.164.113.65 # VPN
sudo ufw allow from 45.12.137.116 # Proxynode

sudo ufw enable

sudo ufw status verbose