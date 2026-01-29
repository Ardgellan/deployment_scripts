#!/bin/bash

# 1. Включаем пересылку пакетов на уровне ядра (нужно для VPN)
sysctl -w net.ipv4.ip_forward=1
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

# 2. Записываем основной скрипт контроля правил
cat << 'EOF' > /usr/local/bin/enforce_ufw_rules.sh
#!/bin/bash

# 1. Сброс и базовая настройка политик
# Разрешаем маршрутизацию (routed), чтобы VPN мог пересылать трафик
ufw default allow outgoing
ufw default deny incoming
ufw default allow routed

# 2. КРИТИЧЕСКИЕ РАЗРЕШЕНИЯ (Вставляем в самый верх списка)
# Разрешаем локальную петлю (исправляет ошибку 61000 в Remnanode)
ufw insert 1 allow in on lo
ufw insert 1 allow out on lo

# Разрешаем интерфейс Docker (чтобы контейнеры могли общаться)
ufw insert 1 allow in on docker0
ufw insert 1 allow out on docker0

# Разрешаем порты Xray и Remnanwave
ufw insert 1 allow 443/tcp
ufw insert 1 allow 443/udp
ufw insert 1 allow 2222/tcp
ufw insert 1 allow 61000:61002/tcp

# 3. СПИСОК ЗАПРЕТОВ (Черный список IP)
# Эти правила будут находиться ниже разрешающих, поэтому не сломают Docker
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

# 4. ЗАЩИТА SSH (Проверка порта и разрешение)
SSH_PORT=$(grep '^Port ' /etc/ssh/sshd_config | sed 's/Port //')
[ -z "$SSH_PORT" ] && SSH_PORT=22
if ! ufw status | grep -q "$SSH_PORT/tcp"; then
  ufw insert 1 allow $SSH_PORT/tcp
fi

# Включаем UFW принудительно
ufw --force enable
EOF

# 3. Делаем скрипт исполняемым
chmod +x /usr/local/bin/enforce_ufw_rules.sh

# 4. Добавляем в Cron, чтобы правила восстанавливались каждые 2 минуты
(crontab -l 2>/dev/null | grep -v "enforce_ufw_rules.sh"; echo "*/2 * * * * /usr/local/bin/enforce_ufw_rules.sh") | crontab -

# 5. Первый запуск для применения настроек
ufw --force reset
bash /usr/local/bin/enforce_ufw_rules.sh

echo "Сервер настроен. Скрипт /usr/local/bin/enforce_ufw_rules.sh создан и запущен."