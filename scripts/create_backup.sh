#!/bin/bash

BACKUP_DIR="/opt/pg_dump_archive"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M")
RETENTION_DAYS=7
DB_NAME="vpnizator_database"
TMP_DIR="/tmp/backup_$TIMESTAMP"
ARCHIVE_NAME="backup_${TIMESTAMP}.tar.gz"

echo "[$(date)] Начинаем создание бэкапа базы $DB_NAME..."

mkdir -p "$BACKUP_DIR"
mkdir -p "$TMP_DIR"

sudo -u postgres pg_dump "$DB_NAME" > "$TMP_DIR/${DB_NAME}.sql"
if [ $? -ne 0 ]; then
    echo "Ошибка создания дампа базы данных"
    rm -rf "$TMP_DIR"
    exit 1
fi

tar -czf "$BACKUP_DIR/$ARCHIVE_NAME" -C "$TMP_DIR" .
rm -rf "$TMP_DIR"

echo "[$(date)] Архив создан: $BACKUP_DIR/$ARCHIVE_NAME"

find "$BACKUP_DIR" -type f -name "backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete
echo "[$(date)] Удалены бэкапы старше $RETENTION_DAYS дней"
