#!/bin/bash

set -e

echo "[INFO] Stopping ClickHouse service..."
sudo systemctl stop clickhouse-server || true

echo "[INFO] Disabling ClickHouse service..."
sudo systemctl disable clickhouse-server || true

echo "[INFO] Removing ClickHouse packages..."
sudo apt-get purge -y clickhouse-server clickhouse-client clickhouse-common-static || {
  echo "[WARNING] Failed to purge packages, trying to remove manually..."
}

echo "[INFO] Removing leftover ClickHouse directories and configs..."
sudo rm -rf /etc/clickhouse* /var/lib/clickhouse /var/log/clickhouse* /usr/share/clickhouse /etc/apt/sources.list.d/clickhouse.list /usr/share/keyrings/clickhouse-keyring.gpg

echo "[INFO] Updating package index..."
sudo apt-get update

echo "[INFO] ClickHouse has been uninstalled successfully."
