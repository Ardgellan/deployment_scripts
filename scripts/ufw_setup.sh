# #!/bin/bash

# # Красная тревога в начале
# echo -e "\033[31mВНИМАНИЕ! Этот скрипт настроит брандмауэр UFW для вашего сервера."
# echo -e "Будут разрешены соединения с указанных IP-адресов, а все остальные соединения на эти порты будут заблокированы."
# echo -e "Вы уверены, что хотите продолжить? (yes/no)\033[0m"
# read confirm
# if [[ "$confirm" != "yes" ]]; then
#     echo "Процесс отменен."
#     exit 1
# fi

# # Проверка, установлен ли ufw
# if ! command -v ufw &> /dev/null; then
#     echo "UFW не установлен. Устанавливаю..."
#     sudo apt-get update
#     sudo apt-get install -y ufw
# else
#     echo "UFW уже установлен."
# fi

# sudo ufw reset

# sudo ufw default deny incoming
# sudo ufw default allow outgoing

# sudo ufw allow ssh

# sudo ufw allow 443/tcp   # Разрешаем доступ по TCP на порт 443
# sudo ufw allow 443/udp   # Разрешаем доступ по UDP на порт 443


# sudo ufw allow from 46.138.13.154 # Личный Компьютер

# sudo ufw allow from 217.197.107.34; #aeza_backend
# sudo ufw allow from 178.236.244.106 #aeza_proxynode
# sudo ufw allow from 46.138.4.211;   # Мой PC
# sudo ufw allow from 85.192.37.53    # VPN новый aeza

# sudo ufw enable

# sudo ufw status verbose

#!/bin/bash

# echo -e "\033[31m
# ВНИМАНИЕ! Этот скрипт:
# - Полностью сбросит UFW
# - Запретит весь входящий и исходящий трафик по умолчанию
# - Разрешит только нужные порты и IP-адреса
# - Заблокирует исходящие соединения на приватные сети
# \033[0m"

# read -p "Вы уверены, что хотите продолжить? (yes/no): " confirm
# if [[ "$confirm" != "yes" ]]; then
#     echo "Процесс отменён."
#     exit 1
# fi

# # Установка UFW при необходимости
# if ! command -v ufw &> /dev/null; then
#     echo "UFW не установлен. Устанавливаю..."
#     sudo apt-get update
#     sudo apt-get install -y ufw
# fi

# # Сброс текущих правил
# sudo ufw --force reset

# # Базовая политика
# sudo ufw default deny incoming
# sudo ufw default deny outgoing

# # Разрешаем входящие подключения
# sudo ufw allow in 22/tcp               # SSH
# sudo ufw allow in 443/tcp              # HTTPS TCP
# sudo ufw allow in 443/udp              # HTTPS UDP (QUIC)
# sudo ufw allow in 80/tcp               # HTTP TCP

# # Белый список IP-адресов (входящий трафик)
# sudo ufw allow from 46.138.13.154
# sudo ufw allow from 217.197.107.34
# sudo ufw allow from 178.236.244.106
# sudo ufw allow from 46.138.4.211
# sudo ufw allow from 85.192.37.53

# # Запрет входящего трафика из некоторых подсетей
# sudo ufw deny in 10.0.0.0/8
# sudo ufw deny in 172.0.0.0/8
# sudo ufw deny in 185.232.0.0/14
# sudo ufw deny in 192.0.0.0/8
# sudo ufw deny in 102.0.0.0/8
# sudo ufw deny in 198.0.0.0/8

# # Разрешаем исходящие подключения по нужным портам
# sudo ufw allow out 53                  # DNS (udp и tcp)
# sudo ufw allow out 80                  # HTTP
# sudo ufw allow out 443                 # HTTPS
# sudo ufw allow out 22                  # SSH

# # Запрет исходящего трафика в приватные и определённые сети
# for net in \
#   10.0.0.0/8 \
#   172.16.0.0/12 \
#   192.168.0.0/16 \
#   100.64.0.0/10 \
#   198.18.0.0/15 \
#   169.254.0.0/16 \
#   185.234.0.0/14 \
#   102.0.0.0/8 \
#   172.0.0.0/8 \
#   192.0.0.0/8 \
#   198.0.0.0/8
# do
#   sudo ufw deny out from any to $net
# done

# # Включаем UFW
# sudo ufw --force enable

# echo -e "\n🎯 Текущие правила:"
# sudo ufw status verbose

# echo -e "\n\n\n\n\n"

# sudo iptables-save


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
  185.234.0.0/14 \
  102.0.0.0/8 \
  172.0.0.0/8 \
  192.0.0.0/8 \
  198.0.0.0/8
do
  sudo ufw deny out from any to $net
done

# 1. Определяем основной интерфейс
MAIN_IFACE=$(ip -o -4 route show to default | awk '{print $5}' | head -1)
if [ -z "$MAIN_IFACE" ]; then
    echo "Ошибка: не удалось определить основной интерфейс!"
    exit 1
fi

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