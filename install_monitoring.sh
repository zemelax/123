#!/bin/bash

# Обновление системы
echo "Обновление системы..."
sudo apt update && sudo apt upgrade -y

# Установка необходимых утилит
echo "Установка необходимых утилит..."
sudo apt install -y wget tar software-properties-common

# Установка Node Exporter
echo "Установка Node Exporter..."
NODE_EXPORTER_VERSION="1.8.2"
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz -P /tmp
tar -zxvf /tmp/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz -C /tmp
sudo mv /tmp/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
sudo useradd --no-create-home --shell /bin/false node_exporter
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Создание unit-файла для Node Exporter
echo "Создание unit-файла для Node Exporter..."
cat <<EOF | sudo tee /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter --web.listen-address=:9100

[Install]
WantedBy=multi-user.target
EOF

# Перезагрузка конфигурации systemd и запуск Node Exporter
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

# Проверка статуса Node Exporter
echo "Проверка статуса Node Exporter..."
sudo systemctl status node_exporter

# Установка Prometheus
echo "Установка Prometheus..."
PROMETHEUS_VERSION="2.54.1"
wget https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz -P /tmp
tar -zxvf /tmp/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz -C /tmp
sudo mv /tmp/prometheus-${PROMETHEUS_VERSION}.linux-amd64/prometheus /usr/local/bin/
sudo mv /tmp/prometheus-${PROMETHEUS_VERSION}.linux-amd64/promtool /usr/local/bin/
sudo mkdir /etc/prometheus
sudo mv /tmp/prometheus-${PROMETHEUS_VERSION}.linux-amd64/prometheus.yml /etc/prometheus/

# Создание пользователя для Prometheus
sudo useradd --no-create-home --shell /bin/false prometheus
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool
sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml

# Создание unit-файла для Prometheus
echo "Создание unit-файла для Prometheus..."
cat <<EOF | sudo tee /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus Monitoring System
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus/ \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF

# Перезагрузка конфигурации systemd и запуск Prometheus
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

# Проверка статуса Prometheus
echo "Проверка статуса Prometheus..."
sudo systemctl status prometheus

# Установка Grafana
echo "Установка Grafana..."
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt update && sudo apt install grafana -y

# Запуск и включение службы Grafana
echo "Запуск и включение службы Grafana..."
sudo systemctl enable grafana-server
sudo systemctl start grafana-server

# Проверка статуса Grafana
echo "Проверка статуса Grafana..."
sudo systemctl status grafana-server

echo "Установка завершена! Вы можете получить доступ к Grafana по адресу http://<IP-адрес вашего сервера>:3000/"
 
