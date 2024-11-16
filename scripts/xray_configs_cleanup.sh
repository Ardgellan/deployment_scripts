#!/bin/bash

# Не забудь установить jq! sudo apt-get install jq
sudo apt-get install jq

# Путь до конфигурационного файла Xray
CONFIG_FILE="/usr/local/etc/xray/config.json"
LOG_FILE="/root/scripts/xray_cleanup.log"


# Функция для проверки на дубликаты
check_duplicates() {
    # Получаем количество уникальных и всех UUID клиентов
    TOTAL_UUIDS=$(jq '.inbounds[0].settings.clients | length' "$CONFIG_FILE")
    UNIQUE_UUIDS=$(jq '.inbounds[0].settings.clients | unique_by(.id) | length' "$CONFIG_FILE")

    # Если количество уникальных UUID меньше, чем общее количество, значит, есть дубликаты
    if [ "$TOTAL_UUIDS" -ne "$UNIQUE_UUIDS" ]; then
        return 1  # Есть дубликаты
    else
        return 0  # Дубликатов нет
    fi
}

# Проверяем на дубликаты
if check_duplicates; then
    echo "$(date): Дубликатов не найдено. Сервис Xray работает нормально." >> "$LOG_FILE"
    exit 0
else
    echo "$(date): Найдены дубликаты клиентов. Удаляем их и перезапускаем сервис..." >> "$LOG_FILE"

    # Удаляем дубликаты
    jq '.inbounds[0].settings.clients |= unique_by(.id)' "$CONFIG_FILE" > /usr/local/etc/xray/config_cleaned.json

    # Перезаписываем конфигурационный файл
    mv /usr/local/etc/xray/config_cleaned.json "$CONFIG_FILE"

    # Перезапускаем Xray
    systemctl restart xray.service

    echo "$(date): Дубликаты удалены, Xray перезапущен." >> "$LOG_FILE"
fi