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

echo -e "\033[31m
ВНИМАНИЕ! Этот скрипт:
- Полностью сбросит UFW
- Запретит весь входящий и исходящий трафик по умолчанию
- Разрешит только нужные порты и IP-адреса
- Заблокирует исходящие соединения на приватные сети
\033[0m"

read -p "Вы уверены, что хотите продолжить? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
    echo "Процесс отменён."
    exit 1
fi

# Установка UFW при необходимости
if ! command -v ufw &> /dev/null; then
    echo "UFW не установлен. Устанавливаю..."
    sudo apt-get update
    sudo apt-get install -y ufw
fi

# Сброс текущих правил
sudo ufw --force reset

# Базовая политика
sudo ufw default deny incoming
sudo ufw default deny outgoing

# Разрешаем входящие подключения
sudo ufw allow in 22/tcp               # SSH
sudo ufw allow in 443/tcp              # HTTPS TCP
sudo ufw allow in 443/udp              # HTTPS UDP (QUIC)
sudo ufw allow in 80/tcp               # HTTP TCP

# Белый список IP-адресов (входящий трафик)
sudo ufw allow from 46.138.13.154
sudo ufw allow from 217.197.107.34
sudo ufw allow from 178.236.244.106
sudo ufw allow from 46.138.4.211
sudo ufw allow from 85.192.37.53

# Запрет входящего трафика из некоторых подсетей
sudo ufw deny in 10.0.0.0/8
sudo ufw deny in 172.0.0.0/8
sudo ufw deny in 185.232.0.0/14
sudo ufw deny in 192.0.0.0/8
sudo ufw deny in 102.0.0.0/8
sudo ufw deny in 198.0.0.0/8

# Разрешаем исходящие подключения по нужным портам
sudo ufw allow out 53                  # DNS (udp и tcp)
sudo ufw allow out 80                  # HTTP
sudo ufw allow out 443                 # HTTPS
sudo ufw allow out 22                  # SSH

# Запрет исходящего трафика в приватные и определённые сети
for net in \
  10.0.0.0/8 \
  172.16.0.0/12 \
  192.168.0.0/16 \
  100.64.0.0/10 \
  198.18.0.0/15 \
  169.254.0.0/16 \
  185.232.0.0/14 \
  102.0.0.0/8 \
  172.0.0.0/8 \
  192.0.0.0/8 \
  198.0.0.0/8
do
  sudo ufw deny out from any to $net
done

# Включаем UFW
sudo ufw --force enable

echo -e "\n🎯 Текущие правила:"
sudo ufw status verbose

echo -e "\n\n\n\n\n"

sudo iptables-save