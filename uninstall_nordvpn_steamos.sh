#!/bin/bash
set -e

# --- COLOR DEFINITIONS ---
YELLOW='\033[1;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${RED}====================================================${NC}"
echo -e "${RED}            Steam Deck NordVPN Uninstaller          ${NC}"
echo -e "${RED}====================================================${NC}"

# 1. Stop and disable the daemon first
echo -e "${YELLOW}--> Stopping NordVPN service...${NC}"
sudo systemctl disable --now nordvpnd.service || true

# 2. Disable read-only to allow package removal
echo -e "${YELLOW}--> Opening SteamOS for uninstall...${NC}"
sudo steamos-readonly disable

# 3. Remove the NordVPN package
echo -e "${YELLOW}--> Removing NordVPN package...${NC}"
if pacman -Qs nordvpn-bin > /dev/null; then
    sudo pacman -R --noconfirm nordvpn-bin
else
    echo "    NordVPN package not found. Skipping."
fi

# 4. Re-enable read-only immediately
echo -e "${YELLOW}--> Locking SteamOS filesystem...${NC}"
sudo steamos-readonly enable

# 5. Remove the nordvpn group
echo -e "${YELLOW}--> Cleaning up nordvpn group...${NC}"
if getent group nordvpn > /dev/null; then
    sudo gpasswd -d deck nordvpn || true
    sudo groupdel nordvpn || true
    echo "    Done."
else
    echo "    Group not found. Skipping."
fi

echo -e "${GREEN}====================================================${NC}"
echo -e "${GREEN} SUCCESS: NordVPN has been completely removed!      ${NC}"
echo -e "${GREEN}====================================================${NC}"