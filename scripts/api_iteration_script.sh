#!/bin/bash

cd ~

cp xray_server_api/app/data/.env /root/

rm -rf xray_server_api

git clone https://github.com/Ardgellan/xray_server_api.git

mv .env xray_server_api/app/data/

sudo systemctl restart xray_api.service