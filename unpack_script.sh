    #!/bin/bash

# Установка необходимых зависимостей
echo "Проверка и установка необходимых зависимостей..."

# Проверка наличия wget
if ! command -v wget &> /dev/null; then
    echo "wget не установлен. Установка wget..."
    sudo apt update && sudo apt install -y wget
fi

# Проверка наличия unzip
if ! command -v unzip &> /dev/null; then
    echo "unzip не установлен. Установка unzip..."
    sudo apt update && sudo apt install -y unzip
fi

# Папка для установки скриптов
SCRIPTS_DIR="/root/scripts"

# Создание директории для скриптов, если она не существует
mkdir -p "$SCRIPTS_DIR"

# Скачивание zip-архива с скриптами
echo "Скачивание архива с скриптами..."
wget -O /root/scripts.zip https://github.com/Ardgellan/deployment_scripts/archive/refs/heads/main.zip

# Распаковка архива
echo "Распаковка архива..."
unzip /root/scripts.zip -d /root/

# Установка прав на исполнение для всех скриптов в папке scripts и её подкаталогах
echo "Установка прав на исполнение для всех скриптов в папке scripts и её подкаталогах..."
find /root/deployment_scripts-main/scripts -type f -name "*.sh" -exec chmod +x {} \;

# Перемещение папки с скриптами
mv /root/deployment_scripts-main/scripts/* "$SCRIPTS_DIR/"

# Удаление временных файлов
rm -rf /root/scripts.zip
rm -rf /root/deployment_scripts-main

# Удаление самого скрипта
echo "Удаление скрипта unpack_script.sh..."
rm -- "$0"

echo "Скрипт успешно выполнен. Скрипты установлены в $SCRIPTS_DIR."
