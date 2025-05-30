#!/bin/bash

set -euo pipefail

VERSION="2.52.0"
USER="prometheus"
INSTALL_DIR="/opt/prometheus"
BIN_DIR="/usr/local/bin"
CONFIG_DIR="/etc/prometheus"
SERVICE_FILE="/etc/systemd/system/prometheus.service"

# Создание пользователя
if ! id "$USER" &>/dev/null; then
    sudo useradd --no-create-home --shell /usr/sbin/nologin "$USER"
fi

# Скачивание и установка
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v$VERSION/prometheus-$VERSION.linux-amd64.tar.gz
tar -xzf prometheus-$VERSION.linux-amd64.tar.gz
cd prometheus-$VERSION.linux-amd64

sudo mkdir -p $INSTALL_DIR $CONFIG_DIR

# Копирование бинарников
sudo mv prometheus promtool $BIN_DIR/
sudo chown $USER:$USER $BIN_DIR/prometheus $BIN_DIR/promtool

# Копирование конфигов и файлов
sudo cp -r consoles console_libraries $INSTALL_DIR/
sudo cp prometheus.yml $CONFIG_DIR/
sudo chown -R $USER:$USER $INSTALL_DIR $CONFIG_DIR

# Systemd сервис
sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=$USER
ExecStart=$BIN_DIR/prometheus \\
  --config.file=$CONFIG_DIR/prometheus.yml \\
  --storage.tsdb.path=$INSTALL_DIR \\
  --web.console.templates=$INSTALL_DIR/consoles \\
  --web.console.libraries=$INSTALL_DIR/console_libraries

[Install]
WantedBy=multi-user.target
EOF

# Запуск
sudo systemctl daemon-reload
sudo systemctl enable --now prometheus

echo "✅ Prometheus установлен и запущен на порту 9090"
