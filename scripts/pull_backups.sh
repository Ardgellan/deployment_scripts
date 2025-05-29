#!/bin/bash

MAIN_SERVER_USER="your_main_user"
MAIN_SERVER_IP="your.main.server.ip"
REMOTE_BACKUP_DIR="/opt/pg_dump_archive"
LOCAL_BACKUP_DIR="/opt/remote_backups"
RETENTION_DAYS=7

mkdir -p "$LOCAL_BACKUP_DIR"

echo "[$(date)] Начинаем загрузку бэкапов с $MAIN_SERVER_IP..."

scp "$MAIN_SERVER_USER@$MAIN_SERVER_IP:$REMOTE_BACKUP_DIR/backup_*.tar.gz" "$LOCAL_BACKUP_DIR/"
if [ $? -ne 0 ]; then
    echo "Ошибка загрузки бэкапов с основного сервера"
    exit 1
fi

echo "[$(date)] Загрузка завершена."

find "$LOCAL_BACKUP_DIR" -type f -name "backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete
echo "[$(date)] Удалены локальные бэкапы старше $RETENTION_DAYS дней"