#!/bin/bash
# Simple Grafana Installer
# Usage: sudo ./simple_grafana_install.sh [PORT]

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root or with sudo"
    exit 1
fi

# Set port (default 3000)
GRAFANA_PORT=${1:-3000}

echo "Starting Grafana installation on port $GRAFANA_PORT..."

# Install dependencies
apt-get update
apt-get install -y apt-transport-https software-properties-common wget gnupg2

# Add Grafana repository and key
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list

# Update and install Grafana
apt-get update
apt-get install -y grafana

# Configure port if not default
if [ "$GRAFANA_PORT" != "3000" ]; then
    sed -i "s/^;http_port = 3000/http_port = $GRAFANA_PORT/" "/etc/grafana/grafana.ini"
fi

# Start and enable the service
systemctl daemon-reload
systemctl enable grafana-server
systemctl restart grafana-server

echo "Grafana installation complete!"
echo "You can access it at: http://localhost:$GRAFANA_PORT"
echo "Default username: admin"
echo "Default password: admin (you'll be prompted to change this on first login)"