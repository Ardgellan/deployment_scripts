#!/bin/bash

echo "Внимание! Запуск процесса развертывания."
read -p "Вы хотите начать процесс развертывания? (yes/no): " confirm

if [[ "$confirm" != "yes" ]]; then
    echo "Процесс развертывания отменен."
    exit 1
fi

# Предупреждение перед развертыванием
echo "Внимание! Запуск скрипта развертывания."
read -p "Вы уверены, что хотите продолжить? (yes/no): " confirm_deploy

if [[ "$confirm_deploy" != "yes" ]]; then
    echo "Процесс развертывания отменен."
    exit 1
fi

# Запуск скрипта развертывания
echo "Запуск скрипта развертывания..."
./deployment/initial_deployment_script.sh

# Предупреждение перед распаковкой и развертыванием
echo "Внимание! Запуск скрипта для распаковки и развертывания."
read -p "Вы уверены, что хотите продолжить? (yes/no): " confirm_unpack

if [[ "$confirm_unpack" != "yes" ]]; then
    echo "Процесс распаковки отменен."
    exit 1
fi

echo "Запуск скрипта для распаковки и развертывания..."
./deployment/unpack_and_deploy_script.sh

echo "Процесс развертывания завершен."