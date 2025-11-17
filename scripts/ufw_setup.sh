#!/bin/bash

echo -e "\033[31m
=== НАСТРОЙКА UFW ДЛЯ VPN-СЕРВЕРА ===
• Входящие: только SSH (с защитой), HTTP/HTTPS, Xray
• Исходящие: только VPN + системные порты
• Полная блокировка приватных сетей
• Защита от DDoS/сканирования
\033[0m"

# 1. Установка UFW
if ! command -v ufw &> /dev/null; then
    sudo apt update && sudo apt install -y ufw
fi

# 2. Сброс правил
sudo ufw --force reset

# 3. Базовые политики
sudo ufw default deny incoming
sudo ufw default deny outgoing

# 4. Входящие правила (с защитой)
# SSH - лимит 5 попыток/мин + разрешение всем
sudo ufw limit 22/tcp comment 'SSH bruteforce protection'

# Веб-порты (для сертификатов и перенаправления)
sudo ufw allow in 8000/tcp comment 'Allow xray API port'
sudo ufw allow in 80/tcp comment 'HTTP'
sudo ufw allow in 443/tcp comment 'HTTPS'
sudo ufw allow in 443/udp comment 'QUIC'

# 5. Исходящие правила
# Системные порты (ограниченный набор)
sudo ufw allow out 53/udp comment 'DNS UDP'
sudo ufw allow out 53/tcp comment 'DNS TCP'
sudo ufw allow out 80/tcp comment 'HTTP (certbot)'
sudo ufw allow out 443/tcp comment 'HTTPS'
sudo ufw allow out 443/udp comment 'HTTPS'
sudo ufw allow out 123/udp comment 'NTP'

for net in \
  10.0.0.0/8 \
  172.16.0.0/12 \
  192.168.0.0/16 \
  100.64.0.0/10 \
  198.18.0.0/15 \
  169.254.0.0/16 \
do
  sudo ufw deny out from any to $net
done

"10.0.0.0/8"
  "172.16.0.0/12"
  "192.168.0.0/16"
  "100.64.0.0/10"
  "169.254.0.0/16"
  "198.18.0.0/15"

# 1. Задаём основной интерфейс вручную
MAIN_IFACE="enp1s0"

# 🚫 Запрет опасных портов на основном интерфейсе (VPN)
# SMTP (спам)
sudo ufw deny out on $MAIN_IFACE to any port 25 proto tcp comment 'Block SMTP'
sudo ufw deny out on $MAIN_IFACE to any port 465 proto tcp comment 'Block SMTPS'
sudo ufw deny out on $MAIN_IFACE to any port 587 proto tcp comment 'Block Auth SMTP'

# IRC, Telnet, RDP, NFS, SMB
sudo ufw deny out on $MAIN_IFACE to any port 23 proto tcp comment 'Block Telnet'
sudo ufw deny out on $MAIN_IFACE to any port 445 proto tcp comment 'Block SMB'
sudo ufw deny out on $MAIN_IFACE to any port 2049 proto tcp comment 'Block NFS'
sudo ufw deny out on $MAIN_IFACE to any port 3389 proto tcp comment 'Block RDP'
sudo ufw deny out on $MAIN_IFACE to any port 6660:6670 proto tcp comment 'Block IRC'

# Tor и SOCKS
sudo ufw deny out on $MAIN_IFACE to any port 1080 proto tcp comment 'Block SOCKS'
sudo ufw deny out on $MAIN_IFACE to any port 9001 proto tcp comment 'Block Tor relay'
sudo ufw deny out on $MAIN_IFACE to any port 9050 proto tcp comment 'Block Tor client'

# Майнеры
sudo ufw deny out on $MAIN_IFACE to any port 3333 proto tcp comment 'Block mining port 3333'
sudo ufw deny out on $MAIN_IFACE to any port 4444 proto tcp comment 'Block mining port 4444'
sudo ufw deny out on $MAIN_IFACE to any port 7777 proto tcp comment 'Block mining port 7777'

# BitTorrent и P2P
sudo ufw deny out on $MAIN_IFACE to any port 6881:6889 proto tcp comment 'Block BitTorrent TCP'
sudo ufw deny out on $MAIN_IFACE to any port 6881:6889 proto udp comment 'Block BitTorrent UDP'

# VPN-в-VPN и прокси
sudo ufw deny out on $MAIN_IFACE to any port 500 proto udp comment 'Block IPsec/IKE'
sudo ufw deny out on $MAIN_IFACE to any port 4500 proto udp comment 'Block IPsec NAT-T'
sudo ufw deny out on $MAIN_IFACE to any port 1194 proto udp comment 'Block OpenVPN-in-VPN'

# Winbox, SNMP, LDAP
sudo ufw deny out on $MAIN_IFACE to any port 8291 proto tcp comment 'Block Winbox'
sudo ufw deny out on $MAIN_IFACE to any port 161 proto udp comment 'Block SNMP'
sudo ufw deny out on $MAIN_IFACE to any port 389 proto tcp comment 'Block LDAP'
sudo ufw deny out on $MAIN_IFACE to any port 636 proto tcp comment 'Block LDAPS'

# 9. Защита от сканирования
sudo ufw deny in proto tcp from any to any port 111,2049 comment 'Block NFS'
sudo ufw deny in proto tcp from any to any port 3306,5432 comment 'Block DB'

sudo ufw deny out on $MAIN_IFACE to any port 69 proto udp comment 'Block TFTP'
sudo ufw deny out on $MAIN_IFACE to any port 5938 proto tcp comment 'Block TeamViewer'
sudo ufw deny out on $MAIN_IFACE to any port 6568 proto tcp comment 'Block AnyDesk'
sudo ufw deny out on $MAIN_IFACE to any port 5900:5903 proto tcp comment 'Block VNC'
sudo ufw deny out on $MAIN_IFACE to any port 1900 proto udp comment 'Block UPnP'
sudo ufw deny out on $MAIN_IFACE to any port 5353 proto udp comment 'Block mDNS'
sudo ufw deny out on $MAIN_IFACE to any port 6000:6010 proto tcp comment 'Block X11 display forwarding'
sudo ufw deny out on $MAIN_IFACE to any port 137:139 proto udp comment 'Block NetBIOS'
sudo ufw deny out on $MAIN_IFACE to any port 137:139 proto tcp comment 'Block NetBIOS'

# 8. Контроль интерфейсов
sudo ufw allow out on $MAIN_IFACE comment "Разрешить основной интерфейс"

# 10. Активация
sudo ufw --force enable
echo -e "\n\033[32m=== ПРАВИЛА АКТИВИРОВАНЫ ===\033[0m"


echo -e "\n🎯 Текущие правила:"
sudo ufw status verbose

echo -e "\n\n\n\n\n"

sudo iptables-save