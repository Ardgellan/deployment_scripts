#!/bin/bash

cd ~

cp VPNizator/source/data/.env /root/

rm -rf VPNizator

git clone https://github.com/Ardgellan/VPNizator.git
cd VPNizator
git switch develop
cd ~

mv .env VPNizator/source/data/

sudo systemctl restart vpnizator.service