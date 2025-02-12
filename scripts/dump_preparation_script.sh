#!/bin/bash

rm /root/backup_dir/vpnizator_database.sql.gz

sudo -u postgres pg_dump vpnizator_database > backup_dir/vpnizator_database.sql

gzip /root/backup_dir/vpnizator_database.sql