#!/bin/bash

# ================= НАСТРОЙКИ =================
XRAY_CONFIG="/usr/local/etc/xray/config.json"
ENV_FILE="/root/xray_server_api/app/data/.env"
DEPLOY_SCRIPT="/root/scripts/api_iteration_script.sh"
NEW_PORT=4433  # Порт для нового XHTTP

echo "🚀 [1/4] Начинаем миграцию (Dual Mode: TCP + XHTTP)..."

# 1. Бэкап
if [ -f "$XRAY_CONFIG" ]; then
    cp "$XRAY_CONFIG" "$XRAY_CONFIG.bak_dual_$(date +%F_%T)"
    echo "📦 Бэкап конфига создан."
else
    echo "❌ Конфиг не найден!"
    exit 1
fi

# 2. Открываем новый порт в системе (на всякий случай)
iptables -I INPUT -p tcp --dport $NEW_PORT -j ACCEPT
iptables -I INPUT -p udp --dport $NEW_PORT -j ACCEPT
echo "🔓 Порт $NEW_PORT открыт в iptables."

# 3. Python-патчер для создания ВТОРОГО инбаунда
cat <<EOF > patch_dual_config.py
import json
import sys
import copy
import os

config_path = "$XRAY_CONFIG"
new_port = $NEW_PORT

try:
    if not os.path.exists(config_path):
        print(f"File not found: {config_path}")
        sys.exit(1)

    with open(config_path, 'r') as f:
        data = json.load(f)

    # Берем текущий (старый) инбаунд как шаблон
    old_inbound = data['inbounds'][0]
    
    # Проверка: если у нас уже 2 инбаунда, возможно миграция уже была
    if len(data['inbounds']) > 1:
        print("⚠️ Внимание: В конфиге уже больше 1 инбаунда. Проверяем порты...")
        # Можно добавить логику проверки, но пока просто предупредим
        # sys.exit(0) # Если хочешь прервать - раскомментируй. 
        # Но лучше пусть скрипт создаст дубль, если порты разные, или упадет xray (безопасно)

    # Клонируем его для создания нового XHTTP входа
    new_inbound = copy.deepcopy(old_inbound)

    # --- НАСТРАИВАЕМ НОВЫЙ ИНБАУНД ---
    new_inbound['port'] = new_port
    new_inbound['tag'] = "vless_xhttp" # Уникальный тег

    # Чистим flow у клиентов для нового инбаунда (XHTTP не дружит с flow)
    # Копируем клиентов из старого, чтобы они работали и там и там (опционально)
    if 'settings' in new_inbound and 'clients' in new_inbound['settings']:
        for client in new_inbound['settings']['clients']:
            client['flow'] = ""

    # Настраиваем транспорт XHTTP
    # Важно: Ключи (privateKey) остаются теми же!
    
    old_stream = old_inbound.get('streamSettings', {})
    old_reality = old_stream.get('realitySettings', {})
    
    private_key = old_reality.get('privateKey')
    short_ids = old_reality.get('shortIds')

    if not private_key:
         print("❌ Ошибка: Не найден PrivateKey в исходном конфиге")
         sys.exit(1)
    
    new_inbound['streamSettings'] = {
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
            "serverNames": ["www.microsoft.com", "microsoft.com"],
            "privateKey": private_key,
            "shortIds": short_ids,
            "spiderX": "/"
        }
    }

    # Добавляем новый инбаунд в список (теперь их будет 2)
    data['inbounds'].append(new_inbound)

    # Сохраняем
    with open(config_path, 'w') as f:
        json.dump(data, f, indent=4)
        
    print(f"✅ Добавлен второй вход (XHTTP) на порту {new_port}")

except Exception as e:
    print(f"❌ Ошибка Python-скрипта: {e}")
    sys.exit(1)
EOF

python3 patch_dual_config.py
if [ $? -ne 0 ]; then
    echo "❌ Ошибка патчинга конфига."
    rm patch_dual_config.py
    exit 1
fi
rm patch_dual_config.py

# 4. Рестарт Xray
systemctl restart xray
if systemctl is-active --quiet xray; then
    echo "✅ Xray перезапущен. Слушает порты 443 и $NEW_PORT."
else
    echo "❌ Xray не запустился. Проверь логи: journalctl -u xray -n 20"
    exit 1
fi

# 5. Обновляем .env (указываем настройки для НОВЫХ ссылок)
echo "📝 Обновляем .env..."
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

# Апи теперь должно генерировать ссылки XHTTP
update_env_var "XRAY_SNI" "www.microsoft.com" "$ENV_FILE"
update_env_var "XRAY_NETWORK" "xhttp" "$ENV_FILE"
update_env_var "XRAY_PATH" "/update" "$ENV_FILE"
# Добавляем переменную порта, чтобы ссылка вела на 4433
update_env_var "XRAY_LINK_PORT" "$NEW_PORT" "$ENV_FILE"

echo "✅ .env обновлен."

# 6. Обновляем код API
echo "🚀 Обновляем API..."
if [ -f "$DEPLOY_SCRIPT" ]; then
    bash "$DEPLOY_SCRIPT"
else
    cd /root/xray_server_api && git pull && systemctl restart xray_api.service
fi

echo "🎉 ГОТОВО! Старые клиенты на 443 (TCP), новые ссылки будут на $NEW_PORT (XHTTP)."