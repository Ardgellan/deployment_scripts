#!/bin/bash

# Красная тревога в начале
echo -e "\033[31mВНИМАНИЕ! Этот скрипт настроит брандмауэр UFW для вашего сервера."
echo -e "Будут разрешены соединения с указанного IP-адреса (Nginx-сервер) на порты 80 и 443, а все остальные соединения на эти порты будут заблокированы."
echo -e "Вы уверены, что хотите продолжить? (yes/no)"
read confirm
if [[ "$confirm" != "yes" ]]; then
    echo "Процесс отменен."
    exit 1
fi

# Проверяем, установлен ли ufw
if ! command -v ufw &> /dev/null; then
    echo -e "\033[31mUFW не установлен. Устанавливаю UFW...\033[0m"
    sudo apt update && sudo apt install ufw -y
    if ! command -v ufw &> /dev/null; then
        echo -e "\033[31mОшибка! Не удалось установить UFW.\033[0m"
        exit 1
    fi
    echo -e "\033[32mUFW успешно установлен.\033[0m"
else
    echo -e "\033[32mUFW уже установлен.\033[0m"
fi

# IP-адрес Nginx-сервера (укажите свой)
NGINX_IP="45.12.137.116"

# Разрешить доступ с IP Nginx-сервера
echo "Разрешаем доступ с IP Nginx-сервера: $NGINX_IP"
sudo ufw allow from "$NGINX_IP" to any port 80
sudo ufw allow from "$NGINX_IP" to any port 443

# Заблокировать доступ ко всем остальным
echo "Блокируем доступ ко всем остальным IP-адресам на порты 80 и 443"
sudo ufw deny 80
sudo ufw deny 443

# Включаем ufw, если он еще не включен
echo "Включаем UFW..."
sudo ufw enable

# Проверка статуса UFW
echo "Статус UFW:"
sudo ufw status verbose
