#!/bin/bash

set -e

# === СБОР ИНФОРМАЦИИ ===
echo "[INFO] Получаем сетевой интерфейс по умолчанию..."
INTERFACE=$(ip route | awk '/default/ {print $5}' | head -n1)

echo "[INFO] Получаем текущий IP адрес интерфейса $INTERFACE..."
STATIC_IP=$(ip -4 addr show "$INTERFACE" | awk '/inet / {print $2}' | grep -v "^127" | head -n1)

echo "[INFO] Получаем шлюз по умолчанию..."
GATEWAY=$(ip route | awk '/default/ {print $3}' | head -n1)

CURRENT_HOSTNAME=$(hostname)
echo "[INFO] Текущий hostname: $CURRENT_HOSTNAME"
read -rp "Введите новый hostname (оставьте пустым, чтобы оставить $CURRENT_HOSTNAME): " HOSTNAME
HOSTNAME=${HOSTNAME:-$CURRENT_HOSTNAME}

# === ОТКЛЮЧАЕМ cloud-init ДЛЯ СЕТИ ===
echo "[STEP] Отключаем cloud-init для сети..."
mkdir -p /etc/cloud/cloud.cfg.d
echo "network: {config: disabled}" > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg

# === НАСТРАИВАЕМ netplan ===
echo "[STEP] Создаем netplan файл с настройками IP..."
NETPLAN_FILE="/etc/netplan/01-static.yaml"
cat > "$NETPLAN_FILE" <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    enp1s0:
      addresses:
        - $STATIC_IP
      nameservers:
        addresses:
          - 8.8.8.8
          - 1.1.1.1
      routes:
        - to: 0.0.0.0/0
          via: $GATEWAY
          on-link: true
EOF

echo "[STEP] Удаляем дефолтный cloud-init netplan файл (если есть)..."
rm -f /etc/netplan/50-cloud-init.yaml

echo "[STEP] Ограничиваем права на netplan файл..."
chmod 600 "$NETPLAN_FILE"

echo "[STEP] Применяем netplan конфигурацию..."
netplan apply

# === ИЗМЕНЯЕМ HOSTNAME ===
echo "[STEP] Устанавливаем hostname..."
hostnamectl set-hostname "$HOSTNAME"

echo "[STEP] Обновляем /etc/hosts..."
if grep -q "127.0.1.1" /etc/hosts; then
    sed -i "s/^127\.0\.1\.1.*/127.0.1.1   $HOSTNAME $HOSTNAME/" /etc/hosts
else
    echo "127.0.1.1   $HOSTNAME" >> /etc/hosts
fi

echo "[STEP] Обновляем cloud.cfg для сохранения hostname..."
if grep -q "preserve_hostname" /etc/cloud/cloud.cfg; then
    sed -i 's/^preserve_hostname:.*/preserve_hostname: true/' /etc/cloud/cloud.cfg
else
    echo "preserve_hostname: true" >> /etc/cloud/cloud.cfg
fi

./scripts/setup_log_rotation.sh

./scripts/ufw_setup.sh


echo "[DONE] Настройка завершена. Перезагружаем сервер..."
reboot