#!/bin/bash

#########################################
## ClickHouse Installer
## 
## Simple Installation Script for ClickHouse Database
## Version: 1.1.0
## 
## Supported Systems:
## - Ubuntu 22.04/24.04
## - Debian 11/12
## 
## Usage: sudo ./clickhouse_installer.sh [OPTIONS]
## Options:
##   -v, --version VERSION   Specify ClickHouse version (default: latest)
##   -p, --port PORT         Specify HTTP port (default: 8123)
##   -t, --tcp-port PORT     Specify TCP port (default: 9000)
##   -a, --admin-pass PASS   Set admin password (default: root)
##   -h, --help              Show this help message
##
#########################################

# Set error handling
set -e

# Load variables from .env file if it exists
if [ -f "/tmp/.env" ]; then
  export $(grep -v '^#' /tmp/.env | xargs)
fi


# Default variables
CLICKHOUSE_VERSION="latest"
CLICKHOUSE_HTTP_PORT="8123"
CLICKHOUSE_TCP_PORT="9000"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-why}"
LOG_FILE="/var/log/clickhouse_install.log"
TEMP_DIR="/tmp/clickhouse_install_$(date +%s)"

echo "Using admin password: $ADMIN_PASSWORD"

# Function for logging
log() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] [$1] $2" | tee -a "$LOG_FILE"
}

# Function for showing help
show_help() {
    grep "^##" "$0" | sed -e "s/^##//" -e "s/^ //"
    exit 0
}

# Parse command line arguments
while [ $# -gt 0 ]; do
    case "$1" in
        -v|--version)
            CLICKHOUSE_VERSION="$2"
            shift 2
            ;;
        -p|--port)
            CLICKHOUSE_HTTP_PORT="$2"
            shift 2
            ;;
        -t|--tcp-port)
            CLICKHOUSE_TCP_PORT="$2"
            shift 2
            ;;
        -a|--admin-pass)
            ADMIN_PASSWORD="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        *)
            log "ERROR" "Unknown option: $1"
            show_help
            ;;
    esac
done

# Setup
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"
mkdir -p "$TEMP_DIR"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    log "ERROR" "This script must be run as root or with sudo privileges"
    exit 1
fi

# Install dependencies
log "INFO" "Installing required dependencies"
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add ClickHouse repository
log "INFO" "Adding ClickHouse repository"
curl -fsSL 'https://packages.clickhouse.com/rpm/lts/repodata/repomd.xml.key' | gpg --dearmor --yes -o /usr/share/keyrings/clickhouse-keyring.gpg
ARCH=$(dpkg --print-architecture)
echo "deb [signed-by=/usr/share/keyrings/clickhouse-keyring.gpg arch=${ARCH}] https://packages.clickhouse.com/deb stable main" > /etc/apt/sources.list.d/clickhouse.list
apt-get update -y

# Install ClickHouse
log "INFO" "Installing ClickHouse packages"
cat > "$TEMP_DIR/clickhouse.debconf" << EOF
clickhouse-server clickhouse-server/default-password string ${ADMIN_PASSWORD}
clickhouse-server clickhouse-server/default-password-confirmation string ${ADMIN_PASSWORD}
EOF

# Pre-seed debconf with the password
DEBIAN_FRONTEND=noninteractive debconf-set-selections "$TEMP_DIR/clickhouse.debconf"

# Install packages
if [ "$CLICKHOUSE_VERSION" = "latest" ]; then
    DEBIAN_FRONTEND=noninteractive apt-get install -y clickhouse-server clickhouse-client
else
    DEBIAN_FRONTEND=noninteractive apt-get install -y "clickhouse-server=$CLICKHOUSE_VERSION" "clickhouse-client=$CLICKHOUSE_VERSION" || {
        log "WARNING" "Failed to install version $CLICKHOUSE_VERSION, installing latest instead"
        DEBIAN_FRONTEND=noninteractive apt-get install -y clickhouse-server clickhouse-client
    }
fi

# Start ClickHouse service
log "INFO" "Starting ClickHouse service"
systemctl daemon-reload
systemctl enable clickhouse-server
systemctl restart clickhouse-server

# Wait for service to start
log "INFO" "Waiting for ClickHouse service to start"
for i in {1..10}; do
    if systemctl is-active --quiet clickhouse-server; then
        break
    fi
    log "INFO" "Waiting... ($i/10)"
    sleep 2
done

# Check installation
if systemctl is-active --quiet clickhouse-server; then
    CH_VERSION=$(echo "SELECT version()" | clickhouse-client --password "$ADMIN_PASSWORD" --port "$CLICKHOUSE_TCP_PORT" 2>/dev/null || echo "Unknown")
    log "INFO" "ClickHouse $CH_VERSION installed successfully"
else
    log "ERROR" "Failed to start ClickHouse service"
    log "INFO" "Check service status with: systemctl status clickhouse-server"
    exit 1
fi

# Configure firewall if UFW is present
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "active"; then
    log "INFO" "Configuring firewall for ClickHouse"
    ufw allow "$CLICKHOUSE_HTTP_PORT/tcp" comment "ClickHouse HTTP"
    ufw allow "$CLICKHOUSE_TCP_PORT/tcp" comment "ClickHouse Native Protocol"
fi

# Clean up
rm -rf "$TEMP_DIR"

# Print success message
cat << EOT

====== CLICKHOUSE INSTALLATION COMPLETE ======

ClickHouse has been installed and is running.

Connection Info:
- HTTP: http://localhost:$CLICKHOUSE_HTTP_PORT
- TCP: localhost:$CLICKHOUSE_TCP_PORT
- Username: default
- Password: $ADMIN_PASSWORD

To connect using the CLI client:
$ clickhouse-client --password '$ADMIN_PASSWORD' --port $CLICKHOUSE_TCP_PORT

Service commands:
- Status:  systemctl status clickhouse-server
- Restart: systemctl restart clickhouse-server
- Stop:    systemctl stop clickhouse-server
- Logs:    journalctl -u clickhouse-server

EOT

exit 0