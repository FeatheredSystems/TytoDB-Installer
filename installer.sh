#!/bin/bash

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

set -e
echo -e ""

INSTALL_AS_DAEMON=1

# Parse flags
for arg in "$@"; do
    case "$arg" in
        --no-daemon|-nd)
            INSTALL_AS_DAEMON=0
            ;;
    esac
done

ARCH=$(uname -m)
OS=$(uname -s)

echo -e "${CYAN}== Tyto Database Installer ==${NC}"

# Automatically select installation type based on OS and architecture
if [ "$OS" != "Linux" ] || [ "$ARCH" != "x86_64" ]; then
    echo -e "${YELLOW}⚠️  Unsupported OS or architecture ($OS / $ARCH). Falling back to source compilation.${NC}"
    INSTALLATION_TYPE=2
else
    echo -e "${GREEN}System check passed. Proceeding with pre-built binary installation.${NC}"
    INSTALLATION_TYPE=1
fi

if [ "$INSTALLATION_TYPE" = "1" ]; then
    REPO="FeatheredSystems/TytoDB"
    ASSET_NAME="tyto-db-x86_64-linux.tar.gz"

    echo -e "${CYAN}Fetching latest TytoDB release metadata...${NC}"
    API_URL="https://api.github.com/repos/$REPO/releases/latest"
    RESPONSE=$(curl -s "$API_URL")

    ASSET_URL=$(echo "$RESPONSE" | grep "browser_download_url" | grep "$ASSET_NAME" | cut -d '"' -f 4)

    if [ -z "$ASSET_URL" ]; then
        echo -e "${RED}❌ Could not find release asset: $ASSET_NAME${NC}"
        exit 1
    fi

    echo -e "${CYAN}Downloading latest release from:${NC}"
    echo -e "$ASSET_URL"
    curl -L "$ASSET_URL" -o "$ASSET_NAME"

    echo -e "${CYAN}Extracting binary...${NC}"
    tar -xzf "$ASSET_NAME"

    if [ ! -f tyto-db ]; then
        echo -e "${RED}❌ Extracted archive does not contain tyto-db binary${NC}"
        exit 1
    fi

    chmod +x tyto-db

    echo -e "${CYAN}Installing tyto-db to /usr/local/bin...${NC}"
    sudo mv tyto-db /usr/local/bin/ && echo -e "${GREEN}✅ Installed to /usr/local/bin${NC}"
else
    echo -e "${CYAN}Cloning and compiling the source code...${NC}"

    if ! command -v git >/dev/null || ! command -v cargo >/dev/null; then
        echo -e "${RED}❌ 'git' and 'cargo' are required to build TytoDB from source.${NC}"
        exit 1
    fi

    git clone https://github.com/FeatheredSystems/TytoDB.git
    cd TytoDB
    cargo build --release

    BIN_PATH=target/release/tyto-db

    if [ ! -f "$BIN_PATH" ]; then
        echo -e "${RED}❌ Build failed or binary not found at $BIN_PATH${NC}"
        exit 1
    fi

    chmod +x "$BIN_PATH"
    sudo mv "$BIN_PATH" /usr/local/bin/tyto-db
    echo -e "${GREEN}✅ Compiled and installed to /usr/local/bin${NC}"
fi

if [ "$INSTALL_AS_DAEMON" = "1" ]; then
    echo -e "${CYAN}Setting up TytoDB as a systemd service...${NC}"

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

    echo -e "${GREEN}✅ TytoDB service installed and running.${NC}"
    echo -e "${CYAN}Use 'sudo systemctl status tytodb' to check status.${NC}"
else
    echo -e "${YELLOW}⚙️  Skipped daemon setup (--no-daemon)${NC}"
fi
