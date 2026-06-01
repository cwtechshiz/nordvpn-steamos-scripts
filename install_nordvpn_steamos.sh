#!/bin/bash
set -e

# --- COLOR DEFINITIONS ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# --- SAFETY TRAP ---
cleanup() {
    echo -e "\n${YELLOW}--> Finalizing: Locking system and clearing temp files...${NC}"
    sudo steamos-readonly enable
    rm -rf "$HOME/nordvpn_build_temp"
}
trap cleanup EXIT

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}      Steam Deck NordVPN Installer & Updater        ${NC}"
echo -e "${BLUE}====================================================${NC}"

# 1. Disable read-only mode
echo -e "${YELLOW}--> Opening SteamOS for installation...${NC}"
sudo steamos-readonly disable

# 2. Check pacman keys
echo -e "${YELLOW}--> Checking system keys...${NC}"
if [ ! -f /etc/pacman.d/gnupg/pubring.gpg ]; then
    echo "    Keys not found, initializing..."
    sudo pacman-key --init
    sudo pacman-key --populate holo
else
    echo "    Keys already exist. Skipping."
fi

# 3. Prepare a clean build environment
BUILD_DIR="$HOME/nordvpn_build_temp"
mkdir -p "$BUILD_DIR"
rm -rf "$BUILD_DIR/nordvpn-bin"
cd "$BUILD_DIR"

# 4. Grab and build NordVPN from AUR
echo -e "${YELLOW}--> Fetching latest NordVPN package from AUR...${NC}"
git clone https://aur.archlinux.org/nordvpn-bin.git
cd nordvpn-bin
makepkg -si --noconfirm

# 5. Setup nordvpn group for Desktop Mode usage
echo -e "${YELLOW}--> Setting up nordvpn group...${NC}"
if ! getent group nordvpn > /dev/null; then
    sudo groupadd -r nordvpn
    echo "    Created nordvpn group."
fi
sudo gpasswd -a deck nordvpn
echo "    Added deck to nordvpn group."

# 6. Start and enable the NordVPN daemon
echo -e "${YELLOW}--> Enabling NordVPN service...${NC}"
sudo systemctl enable --now nordvpnd.service

echo -e "${GREEN}====================================================${NC}"
echo -e "${GREEN} SUCCESS: NordVPN is installed and ready!           ${NC}"
echo -e "${GREEN}====================================================${NC}"
echo ""
echo "  Next step: log in to NordVPN"
echo "  Run: nordvpn login"
echo ""
echo -e "${BLUE}====================================================${NC}"