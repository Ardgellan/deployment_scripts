#!/bin/bash

# ================= НАСТРОЙКИ ПУТЕЙ =================
XRAY_CONFIG="/usr/local/etc/xray/config.json"
ENV_FILE="/root/xray_server_api/app/data/.env"
DEPLOY_SCRIPT="/root/scripts/api_iteration_script.sh"

echo "🚀 [1/4] Начинаем миграцию ЖИВОГО сервера на XHTTP..."

# 1. Бэкап конфига (обязательно!)
if [ -f "$XRAY_CONFIG" ]; then
    cp "$XRAY_CONFIG" "$XRAY_CONFIG.bak_$(date +%F_%T)"
    echo "📦 Бэкап конфига создан."
else
    echo "❌ Ошибка: Конфиг Xray не найден по пути $XRAY_CONFIG"
    exit 1
fi

# 2. Python-патчер для config.json
# Мы используем Python, чтобы аккуратно отредактировать JSON, не потеряв ни одного юзера
cat <<EOF > patch_xray_config.py
import json
import sys
import os

config_path = "$XRAY_CONFIG"

try:
    if not os.path.exists(config_path):
        print(f"File not found: {config_path}")
        sys.exit(1)

    with open(config_path, 'r') as f:
        data = json.load(f)

    # Получаем доступ к inbound
    inbound = data['inbounds'][0]
    
    # --- СОХРАНЯЕМ КЛЮЧИ ---
    # Пытаемся найти ключи в текущем конфиге (где бы они ни были)
    old_stream = inbound.get('streamSettings', {})
    old_reality = old_stream.get('realitySettings', {})
    
    private_key = old_reality.get('privateKey')
    short_ids = old_reality.get('shortIds')
    
    # Если ключей нет в realitySettings, попробуем поискать в .env (как fallback), 
    # но лучше рассчитывать на конфиг. Если нет - скрипт упадет, и это правильно (безопасно).
    if not private_key:
        print("❌ Ошибка: Не найден PrivateKey в текущем конфиге!")
        sys.exit(1)

    # --- ЧИСТИМ FLOW У КЛИЕНТОВ ---
    # Для XHTTP flow должен быть пустым. Это критично.
    clients = inbound['settings']['clients']
    count = 0
    for client in clients:
        # Убираем flow, если он есть или если он не пустой
        client['flow'] = ""
        count += 1
            
    print(f"✅ Обработано {count} клиентов (Flow очищен)")

    # --- ПЕРЕПИСЫВАЕМ ТРАНСПОРТ НА XHTTP ---
    inbound['streamSettings'] = {
        "network": "xhttp",
        "security": "reality",
        "xhttpSettings": {
            "path": "/update",
            "mode": "auto"
        },
        "realitySettings": {
            "show": False,
            "dest": "www.microsoft.com:443",
            "xver": 0,
            "serverNames": [
                "www.microsoft.com",
                "microsoft.com"
            ],
            "privateKey": private_key,  # Возвращаем старый ключ
            "shortIds": short_ids,      # Возвращаем старые ID
            "spiderX": "/"
        }
    }
    
    # Сохраняем обратно
    with open(config_path, 'w') as f:
        json.dump(data, f, indent=4)
        
    print("✅ Config.json успешно переведен на XHTTP")

except Exception as e:
    print(f"❌ Ошибка Python-скрипта: {e}")
    sys.exit(1)
EOF

# Запуск патчера
python3 patch_xray_config.py
if [ $? -ne 0 ]; then
    echo "❌ Миграция остановлена из-за ошибки в обновлении конфига."
    rm patch_xray_config.py
    exit 1
fi
rm patch_xray_config.py

# 3. Перезапуск Xray Core
echo "🔄 [2/4] Перезапускаем Xray Core..."
systemctl restart xray
if systemctl is-active --quiet xray; then
    echo "✅ Xray Core работает на новом протоколе."
else
    echo "❌ ОШИБКА: Xray Core не запустился. Проверь логи: journalctl -u xray -n 20"
    exit 1
fi

# 4. Обновление .env файла
echo "📝 [3/4] Обновляем .env файл..."

update_env_var() {
    local key=$1
    local value=$2
    local file=$3
    
    if grep -q "^$key" "$file"; then
        sed -i "s|^$key.*|$key = \"$value\"|" "$file"
    else
        echo "$key = \"$value\"" >> "$file"
    fi
}

update_env_var "XRAY_SNI" "www.microsoft.com" "$ENV_FILE"
update_env_var "XRAY_NETWORK" "xhttp" "$ENV_FILE"
update_env_var "XRAY_PATH" "/update" "$ENV_FILE"

echo "✅ .env обновлен."

# 5. Запуск обновления кода API
echo "🚀 [4/4] Обновляем код API (git pull)..."

if [ -f "$DEPLOY_SCRIPT" ]; then
    # Запускаем твой скрипт обновления, который делает git pull и restart service
    bash "$DEPLOY_SCRIPT"
else
    echo "⚠️ Скрипт $DEPLOY_SCRIPT не найден. Пытаюсь обновить вручную..."
    cd /root/xray_server_api
    git pull
    systemctl restart xray_api.service
fi

echo "🎉 МИГРАЦИЯ ЗАВЕРШЕНА! Сервер обновлен до XHTTP."