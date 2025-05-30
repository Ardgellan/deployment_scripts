#!/bin/bash

set -euo pipefail

# Остановка и отключение сервиса
sudo systemctl stop node_exporter || true
sudo systemctl disable node_exporter || true

# Удаление systemd unit-файла
sudo rm -f /etc/systemd/system/node_exporter.service

# Перезагрузка systemd
sudo systemctl daemon-reload
sudo systemctl reset-failed

# Удаление бинарника
sudo rm -f /usr/local/bin/node_exporter

# Удаление system user, если нужен полный демонтаж
if id "nodeusr" &>/dev/null; then
    sudo userdel nodeusr
fi

# Очистка временных каталогов, если остались
sudo rm -rf /tmp/node_exporter-*.linux-amd64*

echo "Node Exporter полностью удалён."
