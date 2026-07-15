#!/bin/bash
#
# ====================================================================
#  NordVPN Installer & Updater for SteamOS (Steam Deck)
# ====================================================================
#
#  Project home / latest version / issues:
#  https://github.com/cwtechshiz/nordvpn-steamos-scripts
#
#  WHAT THIS DOES
#  Installs NordVPN on your Steam Deck by building the community
#  "nordvpn-bin" package from the Arch User Repository (AUR), then
#  sets it up to work from Desktop Mode. 
#
#  Please see github for help running it. Open an issue if need.
#
#
#  Re-running this script later (e.g. after a SteamOS update) is safe
#  and will just check for/apply any NordVPN updates.
#
#  Optional: run with --clean to wipe the local build cache and force
#  a completely fresh download, e.g.:
#       ./install_nordvpn_steamos.sh --clean
#
# ====================================================================

set -e

# --- COLOR DEFINITIONS ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# --- PERSISTENT BUILD LOCATION ---
# We no longer delete this on exit. Keeping the cloned AUR repo (and the
# sources makepkg downloads into it) around means re-runs only re-download
# things that actually changed, instead of pulling the whole NordVPN
# installer from Nord's CDN every single time.
BUILD_DIR="$HOME/.cache/nordvpn-steamdeck-build"
PKG_DIR="$BUILD_DIR/nordvpn-bin"

# Pass --clean to wipe the cache and force a totally fresh clone/build.
if [ "$1" == "--clean" ]; then
    echo -e "${YELLOW}--> --clean passed, removing cached build dir...${NC}"
    rm -rf "$BUILD_DIR"
fi

# --- ERROR REPORTING ---
# Updated before each major step so a failure can say what it was doing,
# not just which line number blew up.
CURRENT_STEP="Starting up"

handle_error() {
    local line_no="$1"
    local failed_command="$2"

    echo -e "\n${RED}====================================================${NC}"
    echo -e "${RED} ERROR: The script stopped${NC}"
    echo -e "${RED}====================================================${NC}"
    echo -e "  While:   ${CURRENT_STEP}"
    echo -e "  Line:    ${line_no}"
    echo -e "  Command: ${failed_command}"
    echo ""

    case "$CURRENT_STEP" in
        *"key"*)
            echo "  Likely cause: pacman couldn't reach the keyserver."
            echo "  Check your internet/Wi-Fi connection and run this again."
            ;;
        *"build tools"*)
            echo "  Likely cause: SteamOS's package repos were unreachable"
            echo "  (base-devel/git failed to install). Check your"
            echo "  connection and try again."
            ;;
        *"AUR"*)
            echo "  Likely cause: couldn't reach aur.archlinux.org."
            echo "  This is usually a dropped connection, a DNS issue, or"
            echo "  a network/firewall blocking the AUR. Try again once"
            echo "  you're on a stable connection."
            ;;
        *"Building"*)
            echo "  Likely cause: makepkg failed to download or verify"
            echo "  NordVPN's installer from Nord's servers (or a checksum"
            echo "  didn't match). Just run the script again -- it will"
            echo "  reuse whatever was already downloaded successfully."
            ;;
        *"service"*|*"group"*)
            echo "  Likely cause: NordVPN installed, but enabling the"
            echo "  service/group failed. Run the script again; it will"
            echo "  skip the reinstall and just retry this part."
            ;;
        *)
            echo "  See the full output above for details."
            ;;
    esac
    echo -e "${RED}====================================================${NC}"
}
trap 'handle_error $LINENO "$BASH_COMMAND"' ERR

# --- SAFETY TRAP ---
cleanup() {
    local exit_code=$?
    if [ "$exit_code" -ne 0 ]; then
        echo -e "\n${YELLOW}--> Re-locking system after the error above...${NC}"
    else
        echo -e "\n${YELLOW}--> Finalizing: Locking system...${NC}"
    fi
    sudo steamos-readonly enable
}
trap cleanup EXIT

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}      Steam Deck NordVPN Installer & Updater        ${NC}"
echo -e "${BLUE}====================================================${NC}"

# 1. Disable read-only mode
echo -e "${YELLOW}--> Opening SteamOS for installation...${NC}"
sudo steamos-readonly disable

# 2. Check pacman keys
CURRENT_STEP="Checking system keys"
echo -e "${YELLOW}--> Checking system keys...${NC}"
if [ ! -f /etc/pacman.d/gnupg/pubring.gpg ]; then
    echo "    Keys not found, initializing..."
    sudo pacman-key --init
    sudo pacman-key --populate holo
else
    echo "    Keys already exist. Skipping."
fi

# 3. Make sure we can actually build AUR packages
CURRENT_STEP="Installing build tools (base-devel, git)"
echo -e "${YELLOW}--> Ensuring build tools are installed (base-devel, git)...${NC}"
sudo pacman -S --needed --noconfirm base-devel git

# 4. Prepare build environment (reuse cache if present)
mkdir -p "$BUILD_DIR"

NEEDS_BUILD=1

if [ -d "$PKG_DIR/.git" ]; then
    CURRENT_STEP="Checking AUR for updates"
    echo -e "${YELLOW}--> Existing cached build found, checking AUR for updates...${NC}"
    cd "$PKG_DIR"
    git fetch origin --quiet

    LOCAL_REV=$(git rev-parse HEAD)
    REMOTE_REV=$(git rev-parse origin/HEAD 2>/dev/null || git rev-parse origin/master)

    if [ "$LOCAL_REV" == "$REMOTE_REV" ]; then
        echo "    PKGBUILD is already up to date, no re-clone needed."
        NEEDS_BUILD=0
    else
        echo "    Changes found on AUR, pulling..."
        git pull --quiet
        NEEDS_BUILD=1
    fi
else
    CURRENT_STEP="Cloning NordVPN package from the AUR"
    echo -e "${YELLOW}--> No cache found, cloning NordVPN package from AUR...${NC}"
    cd "$BUILD_DIR"
    git clone https://aur.archlinux.org/nordvpn-bin.git
    cd "$PKG_DIR"
    NEEDS_BUILD=1
fi

# 5. Compare AUR version to what's actually installed, skip rebuild if current
source PKGBUILD
AUR_VERSION="${pkgver}-${pkgrel}"
INSTALLED_VERSION=$(pacman -Q nordvpn-bin 2>/dev/null | awk '{print $2}')

if [ "$NEEDS_BUILD" -eq 0 ] && [ "$AUR_VERSION" == "$INSTALLED_VERSION" ]; then
    echo -e "${GREEN}    nordvpn-bin $INSTALLED_VERSION is already installed and up to date. Skipping build.${NC}"
else
    CURRENT_STEP="Building nordvpn-bin"
    echo -e "${YELLOW}--> Building nordvpn-bin ($AUR_VERSION)...${NC}"

    # Build only (no install yet) so we can control the pacman install
    # step ourselves.
    makepkg -sf --noconfirm

    CURRENT_STEP="Installing nordvpn-bin"
    # Figure out the actual built package file(s) makepkg just produced.
    mapfile -t PKG_FILES < <(makepkg --packagelist)

    if [ "${#PKG_FILES[@]}" -eq 0 ]; then
        echo -e "${RED}    Could not find a built package file. Aborting.${NC}"
        exit 1
    fi

    # --overwrite tells pacman it's fine to replace stray leftover files
    # (e.g. from a SteamOS update that partially reset /var/lib) instead of
    # erroring out on "file already exists". This is safer than manually
    # rm -rf'ing NordVPN's data directory, which would also wipe your
    # login token and settings every time you reinstall.

    sudo pacman -U --noconfirm --overwrite='/var/lib/nordvpn/*' "${PKG_FILES[@]}"

fi

# 6. Setup nordvpn group for Desktop Mode usage
CURRENT_STEP="Setting up the nordvpn group"
echo -e "${YELLOW}--> Setting up nordvpn group...${NC}"
if ! getent group nordvpn > /dev/null; then
    sudo groupadd -r nordvpn
    echo "    Created nordvpn group."
fi
sudo gpasswd -a deck nordvpn
echo "    Added deck to nordvpn group."

# 7. Start and enable the NordVPN daemon
CURRENT_STEP="Enabling the NordVPN service"
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