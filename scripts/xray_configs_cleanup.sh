#!/bin/bash

# Путь к конфигурационному файлу
CONFIG_FILE="/usr/local/etc/xray/config.json"
LOG_FILE="/root/scripts/xray_cleanup.log"

# Убедимся, что jq установлен
if ! command -v jq &> /dev/null
then
    echo "jq не установлен. Пожалуйста, установите jq и попробуйте снова." >> "$LOG_FILE"
    exit 1
fi

# Создаем резервную копию оригинального файла
cp "$CONFIG_FILE" "$CONFIG_FILE.bak"

# Извлекаем список клиентов и удаляем дубликаты
original_clients_count=$(jq '.inbounds[0].settings.clients | length' "$CONFIG_FILE")
jq '.inbounds[0].settings.clients |= (unique_by(.id))' "$CONFIG_FILE" > /tmp/config_cleaned.json

# Проверяем, успешна ли команда jq
if [ $? -eq 0 ]; then
    cleaned_clients_count=$(jq '.inbounds[0].settings.clients | length' /tmp/config_cleaned.json)
    
    if [ "$original_clients_count" -gt "$cleaned_clients_count" ]; then
        echo "$(date): Найдены и удалены дублирующиеся клиенты. Было: $original_clients_count, стало: $cleaned_clients_count" >> "$LOG_FILE"
    else
        echo "$(date): Дублирующихся клиентов не найдено. Всего клиентов: $original_clients_count" >> "$LOG_FILE"
    fi
    
    # Перемещаем очищенный файл обратно на место оригинального
    mv /tmp/config_cleaned.json "$CONFIG_FILE"
    echo "$(date): Конфигурационный файл успешно обновлен." >> "$LOG_FILE"
    
    # Перезапуск Xray
    systemctl restart xray.service
    if [ $? -eq 0 ]; then
        echo "$(date): Xray успешно перезапущен." >> "$LOG_FILE"
    else
        echo "$(date): Ошибка при перезапуске Xray." >> "$LOG_FILE"
    fi
else
    echo "$(date): Ошибка при обработке конфигурационного файла с помощью jq. Восстановление из резервной копии." >> "$LOG_FILE"
    cp "$CONFIG_FILE.bak" "$CONFIG_FILE"
fi
