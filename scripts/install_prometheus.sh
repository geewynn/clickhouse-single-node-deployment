#!/bin/bash
# Simple Prometheus Installer
# Usage: sudo ./simple_prometheus_install.sh [PORT]

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root or with sudo"
    exit 1
fi

# Set port (default 9090)
PROM_PORT=${1:-9090}
PROM_VERSION="v3.2.1"
PROM_USER="prometheus"
PROM_GROUP="prometheus"
PROM_DATA_DIR="/var/lib/prometheus/data"
PROM_CONFIG_DIR="/etc/prometheus"

echo "Starting Prometheus installation on port $PROM_PORT..."

# Create user and groups
if ! getent group "$PROM_GROUP" > /dev/null; then
    groupadd --system "$PROM_GROUP"
fi

if ! id "$PROM_USER" &>/dev/null; then
    useradd -s /sbin/nologin --system -g "$PROM_GROUP" "$PROM_USER"
fi

# Create directories
mkdir -p "$PROM_DATA_DIR"
mkdir -p "$PROM_CONFIG_DIR"

# Determine architecture
VERSION_NUM="${PROM_VERSION#v}"
arch=$(uname -m)
if [ "$arch" == "x86_64" ]; then
    PROM_ARCH="prometheus-${VERSION_NUM}.linux-amd64"
elif [ "$arch" == "aarch64" ]; then
    PROM_ARCH="prometheus-${VERSION_NUM}.linux-arm64"
else
    echo "Error: Unsupported architecture: $arch"
    exit 1
fi

# Download and extract Prometheus
cd /tmp
wget -q --show-progress "https://github.com/prometheus/prometheus/releases/download/$PROM_VERSION/$PROM_ARCH.tar.gz"
tar -xf "$PROM_ARCH.tar.gz"
cd "$PROM_ARCH"

# Copy files
cp {prometheus,promtool} /usr/bin/
cp -r prometheus.yml "$PROM_CONFIG_DIR"

# Set permissions
chown -R "$PROM_USER:$PROM_GROUP" "$PROM_CONFIG_DIR"
chown -R "$PROM_USER:$PROM_GROUP" "$PROM_DATA_DIR"

# Create systemd service
cat > "/etc/systemd/system/prometheus.service" << EOF
[Unit]
Description=Prometheus Monitoring
After=network-online.target

[Service]
User=$PROM_USER
Group=$PROM_GROUP
ExecStart=/usr/bin/prometheus \\
  --config.file=$PROM_CONFIG_DIR/prometheus.yml \\
  --storage.tsdb.path=$PROM_DATA_DIR \\
  --web.listen-address=:$PROM_PORT 
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=5
StartLimitInterval=60s
StartLimitBurst=3
LimitNOFILE=65535
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF

# Start and enable service
systemctl daemon-reload
systemctl enable prometheus
systemctl start prometheus

# Clean up
rm -rf "/tmp/$PROM_ARCH" "/tmp/$PROM_ARCH.tar.gz"

echo "Prometheus installation complete!"
echo "You can access it at: http://localhost:$PROM_PORT"