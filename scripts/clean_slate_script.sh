#!/bin/bash

# Функция для вывода красного предупреждения
function red_alert() {
    echo -e "\033[31mВНИМАНИЕ! Этот скрипт: $1\033[0m"
    read -p "Вы уверены, что хотите продолжить? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        echo "Процесс отменен."
        exit 1
    fi

    echo -e "\033[31mВЫ ТОЧНО УВЕРЕНЫ?!\033[0m"
    read -p "Введите yes для продолжения: " confirm2
    if [[ "$confirm2" != "yes" ]]; then
        echo "Процесс отменен."
        exit 1
    fi
}

# Пример использования
red_alert "УДАЛЯЕТ ВСЕ НА ХРЕН С СЕРВЕРА!."
# Далее идет код скрипта...


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

# Удаление созданных директорий
echo "Удаление созданных директорий..."
rm -rf ~/backup_dir   # Удаление директории для хранения бэкапов

sudo systemctl daemon-reload