#!/bin/bash

set -euo pipefail

ALERT_VER="0.26.0"
BIN_DIR="/usr/local/bin"
CONFIG_DIR="/etc/alertmanager"
SERVICE_FILE="/etc/systemd/system/alertmanager.service"
CONFIG_FILE="$CONFIG_DIR/config.yml"
RULES_FILE="/etc/prometheus/alert.rules.yml"
PROMETHEUS_CONFIG="/etc/prometheus/prometheus.yml"

# read -p "Введите Telegram Bot Token: " BOT_TOKEN
read -p "Введите Telegram Chat ID (личный аккаунт): " CHAT_ID

echo "Устанавливаем Alertmanager..."

# Создаем пользователя alertmanager если не существует
if ! id "alertmanager" &>/dev/null; then
    sudo useradd --no-create-home --shell /usr/sbin/nologin alertmanager
fi

# Скачиваем и распаковываем Alertmanager
cd /tmp
wget https://github.com/prometheus/alertmanager/releases/download/v${ALERT_VER}/alertmanager-${ALERT_VER}.linux-amd64.tar.gz
tar -xvzf alertmanager-${ALERT_VER}.linux-amd64.tar.gz
sudo mv alertmanager-${ALERT_VER}.linux-amd64/alertmanager $BIN_DIR/
sudo mv alertmanager-${ALERT_VER}.linux-amd64/amtool $BIN_DIR/
rm -rf alertmanager-${ALERT_VER}.linux-amd64*

# Создаем директорию и конфиг Alertmanager с уведомлениями только в личный чат Telegram
sudo mkdir -p $CONFIG_DIR
sudo tee $CONFIG_FILE > /dev/null <<EOF
global:
  resolve_timeout: 5m

route:
  receiver: 'telegram'

receivers:
  - name: 'telegram'
    telegram_configs:
      - bot_token: '${BOT_TOKEN}'
        chat_id: '${CHAT_ID}'
        send_resolved: true
      # Канал пока закомментирован, раскомментируй для использования
      # - bot_token: '${BOT_TOKEN}'
      #   chat_id: '@your_channel_name'
      #   send_resolved: true
EOF

sudo chown -R alertmanager:alertmanager $CONFIG_DIR

# Создаем systemd сервис
sudo tee $SERVICE_FILE > /dev/null <<EOF
[Unit]
Description=Prometheus Alertmanager
Wants=network-online.target
After=network-online.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
ExecStart=$BIN_DIR/alertmanager --config.file=$CONFIG_FILE

[Install]
WantedBy=multi-user.target
EOF

# Запускаем сервис
sudo systemctl daemon-reload
sudo systemctl enable --now alertmanager

echo "Alertmanager установлен и запущен."

# Создаем правила алертов
sudo tee $RULES_FILE > /dev/null <<EOF
groups:
  - name: node_exporter_alerts
    rules:
      - alert: NodeExporterDown
        expr: up{job="node_exporters"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Node Exporter down on {{ \$labels.instance }}"
          description: "Node Exporter on {{ \$labels.instance }} has been down for more than 1 minute."
EOF

echo "Добавляем alert.rules.yml в конфигурацию Prometheus..."

# Проверяем и добавляем правило в prometheus.yml, если еще нет
if ! grep -q "alert.rules.yml" $PROMETHEUS_CONFIG; then
    sudo sed -i '/rule_files:/a \  - "/etc/prometheus/alert.rules.yml"' $PROMETHEUS_CONFIG
fi

# Добавляем alertmanager endpoint в prometheus.yml, если нет
if ! grep -q "alertmanagers:" $PROMETHEUS_CONFIG; then
    sudo sed -i '/^alerting:/a \  alertmanagers:\n    - static_configs:\n        - targets:\n          - "localhost:9093"' $PROMETHEUS_CONFIG
fi

echo "Перезапускаем Prometheus..."
sudo systemctl restart prometheus

echo "Готово! Alertmanager и Prometheus настроены с уведомлениями в личный Telegram."
