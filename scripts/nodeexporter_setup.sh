#!/bin/bash

set -euo pipefail

VERSION="1.9.1"
BIN_DIR="/usr/local/bin"
SERVICE_FILE="/etc/systemd/system/node_exporter.service"

# Создание system user, если запускаешь не от root
# Создание system user, если он ещё не существует
if ! id "nodeusr" &>/dev/null; then
    sudo useradd --no-create-home --shell /usr/sbin/nologin nodeusr
fi


cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v$VERSION/node_exporter-$VERSION.linux-amd64.tar.gz
tar -xvzf node_exporter-$VERSION.linux-amd64.tar.gz
cd node_exporter-$VERSION.linux-amd64

sudo mv node_exporter $BIN_DIR/
sudo chown root:root $BIN_DIR/node_exporter
sudo chmod 755 $BIN_DIR/node_exporter

sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=nodeusr
ExecStart=$BIN_DIR/node_exporter

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter

cd ~
rm -rf /tmp/node_exporter-$VERSION.linux-amd64*

sudo ufw allow 9100/tcp

sudo systemctl status node_exporter --no-pager
