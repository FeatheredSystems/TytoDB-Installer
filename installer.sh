#!/bin/bash

set -e

echo "== Tyto Database Installer =="
echo "1) Install pre-built binary"
echo "2) Clone source code & compile"

read -p "Enter your choice (default=1): " answer
INSTALLATION_TYPE=1
case "$answer" in
    1) INSTALLATION_TYPE=1 ;;
    2) INSTALLATION_TYPE=2 ;;
    *) INSTALLATION_TYPE=1 ;;
esac

echo "== Daemon =="
echo "Want to create a daemon for the binary (run on system boot)?"
read -p "Enter your choice (default=y) [Y/n]: " answer
INSTALL_AS_DAEMON=1
case "$answer" in
    [nN]*) INSTALL_AS_DAEMON=0 ;;
    *) INSTALL_AS_DAEMON=1 ;;
esac

if [ "$INSTALLATION_TYPE" = "1" ]; then
    REPO="FeatheredSystems/TytoDB"
    ASSET_NAME="tyto-db-x86_64-linux.tar.gz"

    echo "Fetching latest TytoDB release metadata..."
    API_URL="https://api.github.com/repos/$REPO/releases/latest"
    RESPONSE=$(curl -s "$API_URL")

    ASSET_URL=$(echo "$RESPONSE" | grep "browser_download_url" | grep "$ASSET_NAME" | cut -d '"' -f 4)

    if [ -z "$ASSET_URL" ]; then
        echo "❌ Could not find release asset: $ASSET_NAME"
        exit 1
    fi

    echo "Downloading latest release from:"
    echo "$ASSET_URL"
    curl -L "$ASSET_URL" -o "$ASSET_NAME"

    echo "Extracting binary..."
    tar -xzf "$ASSET_NAME"

    if [ ! -f tyto-db ]; then
        echo "❌ Extracted archive does not contain tyto-db binary"
        exit 1
    fi

    chmod +x tyto-db

    read -p "Install tyto-db to /usr/local/bin? [Y/n]: " movebin
    case "$movebin" in
        [nN]*) echo "Skipping move. You can run it with ./tyto-db" ;;
        *) sudo mv tyto-db /usr/local/bin/ && echo "✅ Installed to /usr/local/bin" ;;
    esac
else
    echo "Cloning and compiling the source code..."
    # Placeholder - not yet implemented
    exit 1
fi

if [ "$INSTALL_AS_DAEMON" = "1" ]; then
    echo "Setting up TytoDB as a systemd service..."

    SERVICE_PATH="/etc/systemd/system/tytodb.service"

    sudo tee "$SERVICE_PATH" > /dev/null <<EOF
[Unit]
Description=TytoDB Daemon
After=network.target

[Service]
ExecStart=/usr/local/bin/tyto-db
Restart=always
User=$USER
WorkingDirectory=/etc/tytodb

[Install]
WantedBy=multi-user.target
EOF

    sudo mkdir -p /etc/tytodb
    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload
    sudo systemctl enable tytodb.service
    sudo systemctl start tytodb.service

    echo "✅ TytoDB service installed and running."
    echo "Use 'sudo systemctl status tytodb' to check status."
fi

