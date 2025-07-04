#!/bin/bash
# 🛠 setup_log_rotation.sh

echo "== Настройка logrotate для rsyslog =="

cat <<EOF > /etc/logrotate.d/rsyslog
/var/log/syslog
/var/log/mail.info
/var/log/mail.warn
/var/log/mail.err
/var/log/mail.log
/var/log/daemon.log
/var/log/kern.log
/var/log/auth.log
/var/log/user.log
/var/log/lpr.log
/var/log/cron.log
/var/log/debug
/var/log/messages
{
    rotate 7
    daily
    size 100M
    missingok
    notifempty
    compress
    delaycompress
    sharedscripts
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate
    endscript
}
EOF

echo "== Настройка ограничения systemd journal =="
mkdir -p /etc/systemd/journald.conf.d
cat <<EOF > /etc/systemd/journald.conf.d/limit.conf
[Journal]
SystemMaxUse=100M
SystemMaxFileSize=20M
MaxRetentionSec=1week
EOF

echo "== Перезапуск journald =="
systemctl restart systemd-journald

echo "== Принудительная ротация логов =="
logrotate -f /etc/logrotate.conf

echo "✅ Настройка логов завершена!"