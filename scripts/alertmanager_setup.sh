#!/bin/bash

set -euo pipefail

ALERT_VER="0.26.0"
BIN_DIR="/usr/local/bin"
CONFIG_DIR="/etc/alertmanager"
SERVICE_FILE="/etc/systemd/system/alertmanager.service"
CONFIG_FILE="$CONFIG_DIR/config.yml"
RULES_FILE="/etc/prometheus/alert.rules.yml"
PROMETHEUS_CONFIG="/etc/prometheus/prometheus.yml"

read -p "Введите Telegram Bot Token (можно оставить пустым): " BOT_TOKEN
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

# Создаем директорию и конфиг Alertmanager
sudo mkdir -p $CONFIG_DIR
sudo tee $CONFIG_FILE > /dev/null <<EOF
global:
  resolve_timeout: 5m

route:
  receiver: 'telegram'

receivers:
  - name: 'telegram'
EOF

# Добавляем telegram_configs только если указан токен
if [[ -n "$BOT_TOKEN" ]]; then
sudo tee -a $CONFIG_FILE > /dev/null <<EOF
    telegram_configs:
      - bot_token: '${BOT_TOKEN}'
        chat_id: '${CHAT_ID}'
        send_resolved: true
EOF
else
    echo "⚠️  Telegram Bot Token не указан. Уведомления не будут отправляться."
fi

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

echo "✅ Alertmanager установлен и запущен."

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

echo "🔧 Добавляем alert.rules.yml в конфигурацию Prometheus..."

# Добавляем alert.rules.yml если не добавлено
if ! grep -q "alert.rules.yml" $PROMETHEUS_CONFIG; then
    sudo sed -i '/rule_files:/a \  - "/etc/prometheus/alert.rules.yml"' $PROMETHEUS_CONFIG
fi

# Добавляем alertmanager endpoint если не добавлено
if ! grep -q "alertmanagers:" $PROMETHEUS_CONFIG; then
    sudo sed -i '/^alerting:/a \  alertmanagers:\n    - static_configs:\n        - targets:\n          - "localhost:9093"' $PROMETHEUS_CONFIG
fi

echo "🔁 Перезапускаем Prometheus..."
sudo systemctl restart prometheus

echo "🎉 Готово! Alertmanager и Prometheus настроены. Telegram-уведомления ${BOT_TOKEN:+включены}${BOT_TOKEN:+"."}${BOT_TOKEN:-отключены.}"
