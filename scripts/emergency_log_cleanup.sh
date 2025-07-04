#!/bin/bash
# 🧹 emergency_log_cleanup.sh

echo "== Остановка rsyslog и journald =="
systemctl stop rsyslog 2>/dev/null
systemctl stop systemd-journald 2>/dev/null

echo "== Очистка syslog и других логов =="
truncate -s 0 /var/log/syslog 2>/dev/null
rm -f /var/log/syslog.? /var/log/syslog.*.gz 2>/dev/null
rm -f /var/log/*.gz /var/log/*.1 /var/log/*.2 2>/dev/null

echo "== Очистка systemd journal =="
rm -rf /var/log/journal/* 2>/dev/null
journalctl --vacuum-size=50M >/dev/null 2>&1

echo "== Перезапуск лог-сервисов =="
systemctl start systemd-journald 2>/dev/null
systemctl start rsyslog 2>/dev/null

echo "== Проверка занятого места =="
df -h /

echo "✅ Очистка завершена." - объясни подробно вот этот скрипт, чат