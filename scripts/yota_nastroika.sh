#!/bin/bash

# 1. Сброс и базовая настройка политик
ufw default allow outgoing
ufw default deny incoming
ufw default allow routed

# 2. КРИТИЧЕСКИЕ РАЗРЕШЕНИЯ (Используем allow без insert)
# Так как мы запускаем их первыми после сброса, они займут позиции 1, 2, 3...
ufw allow in on lo
ufw allow out on lo
ufw allow in on docker0
ufw allow out on docker0
ufw allow 443/tcp
ufw allow 443/udp
ufw allow 2222/tcp
ufw allow 61000:61002/tcp

# 3. СПИСОК ЗАПРЕТОВ (Добавляются следом, поэтому будут ниже в списке)
RULES="deny in from 10.0.0.0/8
deny out to 10.0.0.0/8
deny in from 172.0.0.0/8
deny out to 172.0.0.0/8
deny in from 185.234.0.0/14
deny out to 185.234.0.0/14
deny in from 192.0.0.0/8
deny out to 192.0.0.0/8
deny in from 102.0.0.0/8
deny out to 102.0.0.0/8
deny in from 198.0.0.0/8
deny out to 198.0.0.0/8"

echo "$RULES" | while read -r rule; do
  if ! ufw status | grep -q "$rule"; then
    ufw $rule
  fi
done

# 4. ЗАЩИТА SSH
SSH_PORT=$(grep '^Port ' /etc/ssh/sshd_config | sed 's/Port //')
[ -z "$SSH_PORT" ] && SSH_PORT=22
if ! ufw status | grep -q "$SSH_PORT/tcp"; then
  ufw allow $SSH_PORT/tcp
fi

# Включаем UFW
ufw --force enable