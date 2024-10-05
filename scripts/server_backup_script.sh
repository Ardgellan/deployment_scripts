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
red_alert "запускает процесс миграции сервера."
# Далее идет код скрипта...


sudo systemctl stop vpnizator.service

sudo systemctl stop xray.service

# Установка переменной для пути к директории бэкапов
BACKUP_DIR="/root/backup_dir/"

# Очистка директории бэкапов
echo "Очистка директории $BACKUP_DIR..."
rm -rf $BACKUP_DIR/*

# Создание дампа базы данных PostgreSQL прямо в директории бэкапов
echo "Создаём дамп базы данных vpnizator_database в $BACKUP_DIR..."
sudo -u postgres pg_dump vpnizator_database > $BACKUP_DIR/vpnizator_database.sql

# Бэкап конфигурационного файла XRAY
cp /usr/local/etc/xray/config.json $BACKUP_DIR/config.json

# Сжатие бэкапа в архив
tar -czf $BACKUP_DIR/backup.tar.gz -C $BACKUP_DIR vpnizator_database.sql config.json
echo "Бэкап создан: $BACKUP_DIR/backup.tar.gz"

# Показ SSH-ключа
echo "Ваш SSH-ключ для доступа к новому серверу:"
cat ~/.ssh/id_ed25519.pub

# Ожидание ввода команды
echo "Пожалуйста, скопируйте этот ключ на новый сервер и добавьте его в ~/.ssh/authorized_keys. Нажмите Enter, когда будете готовы продолжить."
read -r

# Ввод данных для копирования на новый сервер
echo "Введите адрес нового сервера (например, root@192.168.0.1):"
read server_address

# Хардкодированный путь для сохранения бэкапа на новом сервере
server_path="/root/backup_dir/"

# Копирование архива на новый сервер
scp $BACKUP_DIR/backup.tar.gz $server_address:$server_path

echo "Бэкап перенесён на новый сервер"

echo "Скрипт завершен."