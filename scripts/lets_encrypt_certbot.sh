#!/bin/bash

# Функция для вывода красного предупреждения
function red_alert() {
    echo -e "\033[31mВНИМАНИЕ! Этот скрипт: $1\033[0m"
    read -p "Вы уверены, что хотите продолжить? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        echo "Процесс отменен."
        exit 1
    fi

    echo -e "\033[31mВЫ ТОЧНО УВЕРЕНЫ?!\033[0m"
    read -p "Введите yes для продолжения: " confirm2
    if [[ "$confirm2" != "yes" ]]; then
        echo "Процесс отменен."
        exit 1
    fi
}

# Пример использования
red_alert "Устанавливает на ваш сервер SSL шифрование с автоматическим продлением!"

# Обновляем список пакетов и обновляем систему
sudo apt update
sudo apt upgrade -y

# Устанавливаем Nginx
sudo apt install nginx -y

# Проверяем, установился ли Nginx
if ! command -v nginx &> /dev/null; then
    echo -e "\033[1;31mОшибка! Nginx не установлен.\033[0m"
    exit 1
fi

# Запускаем Nginx и добавляем в автозагрузку
sudo systemctl start nginx
sudo systemctl enable nginx

# Устанавливаем Certbot и плагин для Nginx
sudo apt install certbot python3-certbot-nginx -y

# Проверяем, установился ли Certbot
if ! command -v certbot &> /dev/null; then
    echo -e "\033[1;31mОшибка! Certbot не установлен.\033[0m"
    exit 1
fi

# Запрашиваем у пользователя доменное имя
echo -e "\033[1;33mВведите доменное имя для сертификата (например, example.com): \033[0m"
read server_domain_name

# Проверяем, что доменное имя не пустое
if [ -z "$server_domain_name" ]; then
    echo -e "\033[1;31mДоменное имя не может быть пустым. Выход из скрипта.\033[0m"
    exit 1
fi

# Запрашиваем сертификат с помощью Certbot
sudo certbot --nginx -d "$server_domain_name"

# Проверяем конфигурацию Nginx
sudo nginx -t

# Перезапускаем Nginx для применения изменений
sudo systemctl restart nginx

# Проверяем возможность автоматического обновления сертификатов
sudo certbot renew --dry-run

# Уведомление об успешной настройке
echo -e "\033[1;32mСертификат успешно установлен и настроен для домена $server_domain_name.\033[0m"
echo -e "\033[1;32mСертификат будет автоматически обновляться.\033[0m"
