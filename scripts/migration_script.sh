#!/bin/bash

echo "Внимание! Текущий скрипт запускает процесс миграции сервера."
read -p "Вы уверены, что хотите продолжить? (yes/no): " confirm

if [[ "$confirm" != "yes" ]]; then
    echo "Процесс миграции отменен."
    exit 1
fi

# Предупреждение перед резервным копированием
echo "Внимание! Запуск скрипта резервного копирования."
read -p "Вы уверены, что хотите продолжить? (yes/no): " confirm_backup

if [[ "$confirm_backup" != "yes" ]]; then
    echo "Процесс резервного копирования отменен."
    exit 1
fi

echo "Запуск скрипта резервного копирования..."
./folder_migration/server_backup_script.sh

# Предупреждение перед очисткой
echo "Внимание! Запуск скрипта очистки."
read -p "Вы уверены, что хотите продолжить? (yes/no): " confirm_clean

if [[ "$confirm_clean" != "yes" ]]; then
    echo "Процесс очистки отменен."
    exit 1
fi

echo "Запуск скрипта очистки..."
./folder_migration/clean_slate_script.sh

# Ожидание завершения обоих скриптов
wait
echo "Процесс миграции завершен."