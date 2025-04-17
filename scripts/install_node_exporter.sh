#!/bin/bash

set -e

NODE_EXPORTER_VERSION="1.9.1"

echo "[INFO] Installing Node Exporter v$NODE_EXPORTER_VERSION..."

# Create a user
useradd --no-create-home --shell /bin/false node_exporter || true

# Download and install
#!/bin/bash

set -e

# Define Node Exporter version
NODE_EXPORTER_VERSION="1.8.1"

# Create a temporary directory for download and extraction
mkdir -p /tmp/temp
cd /tmp/temp || exit

# Determine CPU architecture using 'uname -m'
arch=$(uname -m)

# Download, extract, and copy Prometheus Node Exporter files
if [ "$arch" == "x86_64" ]; then
    echo "Installing package for x86_64 architecture..."
    NODE_EXPORTER_AMD64="node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64"
    wget "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/${NODE_EXPORTER_AMD64}.tar.gz"
    tar -xvf "${NODE_EXPORTER_AMD64}.tar.gz"
    cp ./${NODE_EXPORTER_AMD64}/node_exporter /usr/local/bin/
elif [ "$arch" == "aarch64" ]; then
    echo "Installing package for ARM64 architecture..."
    NODE_EXPORTER_ARM64="node_exporter-${NODE_EXPORTER_VERSION}.linux-arm64"
    wget "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/${NODE_EXPORTER_ARM64}.tar.gz"
    tar -xvf "${NODE_EXPORTER_ARM64}.tar.gz"
    cp ./${NODE_EXPORTER_ARM64}/node_exporter /usr/local/bin/
else
    echo "Unsupported architecture: $arch"
    printf "Go to https://prometheus.io/download/ to download other binaries.\n"
    exit 1
fi

# Clean up the temp directory
rm -rf /tmp/temp

echo "[INFO] Node Exporter installation completed."


# Create systemd service
cat <<EOF >/etc/systemd/system/node_exporter.service
[Unit]
Description=Prometheus Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Reload and start service
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter

echo "[INFO] Node Exporter installed and running on port 9100"
