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
red_alert "распаковывает дамп базы данных и ЗАТИРАЕТ ПРИ ЭТО СТАРУЮ!."
# Далее идет код скрипта...


BACKUP_DIR="/root/backup_dir/"  # Директория бэкапов

# Пути к старому и новому конфигурационным файлам
OLD_CONFIG="/root/backup_dir/config.json"  # Старая конфигурация из бэкапа
NEW_CONFIG="/usr/local/etc/xray/config.json"  # Новый конфиг на новом сервере


# Распаковка бэкапа
echo "Распаковка бэкапа..."
tar -xzf "$BACKUP_DIR/backup.tar.gz" -C "$BACKUP_DIR"

# Загрузка дампа базы данных
echo "Восстановление базы данных из дампа..."
sudo -u postgres psql vpnizator_database < "$BACKUP_DIR/vpnizator_database.sql"

# Проверка, что операция была успешной
if [ $? -eq 0 ]; then
    echo "База данных успешно восстановлена."
else
    echo "Ошибка при восстановлении базы данных."
    exit 1
fi

# Проверка, установлен ли jq, и установка, если он отсутствует
if ! command -v jq &> /dev/null; then
    echo "jq не установлен. Установка jq..."
    sudo apt update
    sudo apt install -y jq

    if [ $? -ne 0 ]; then
        echo "Ошибка при установке jq. Проверьте наличие прав на установку и доступ к интернету."
        exit 1
    fi
    echo "jq успешно установлен."
fi

# Извлечение блока "clients" из старого конфига
echo "Извлечение клиентов из старого конфига..."
clients_block=$(jq '.inbounds[0].settings.clients' "$OLD_CONFIG")

# Проверка, был ли извлечен блок клиентов
if [ -z "$clients_block" ]; then
    echo "Ошибка: не удалось найти блок клиентов в старом конфиге."
    exit 1
fi

# Вставка блока клиентов в новый конфиг, заменяя существующий блок "clients"
echo "Добавление клиентов в новый конфиг..."
jq --argjson clients "$clients_block" '.inbounds[0].settings.clients = $clients' "$NEW_CONFIG" > "/tmp/new_config.json" && mv /tmp/new_config.json "$NEW_CONFIG"

# Проверка, что операция была успешной
if [ $? -eq 0 ]; then
    echo "Клиенты успешно перенесены в новый конфиг."
else
    echo "Ошибка при добавлении клиентов в новый конфиг."
    exit 1
fi

# Перезапуск XRAY для применения нового конфига
echo "Перезапуск XRAY и VPNIZATOR..."
sudo systemctl restart xray.service
sudo systemctl restart vpnizator.service