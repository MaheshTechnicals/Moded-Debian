#!/bin/bash
# Firefox Deb Installer Script with Colorful UI + Auto Root
# Author: Mahesh Technicals

#============================#
#     COLOR DEFINITIONS      #
#============================#
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
CYAN='\e[1;36m'
NC='\e[0m' # No Color

#============================#
#     ROOT PRIVILEGE CHECK   #
#============================#
if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}⚠ Root privileges required!${NC}"
  echo -e "${YELLOW}→ Re-running this script with sudo...${NC}"
  sudo bash "$0" "$@"
  exit $?
fi

#============================#
#         HEADER UI          #
#============================#
echo -e "${CYAN}"
echo "==========================================="
echo "     🦊 Firefox (Deb) Installer Script     "
echo "        by Mahesh Technicals (2025)        "
echo "==========================================="
echo -e "${NC}"

#============================#
#    REMOVE FIREFOX SNAP     #
#============================#
echo -e "${YELLOW}→ Checking for Firefox Snap installation...${NC}"
if command -v snap >/dev/null 2>&1 && snap list firefox &>/dev/null; then
    echo -e "${RED}⚠ Found Firefox Snap! Removing...${NC}"
    snap remove --purge firefox && echo -e "${GREEN}✔ Firefox Snap removed successfully.${NC}"
else
    echo -e "${GREEN}✔ No Firefox Snap installation found.${NC}"
fi

#============================#
#     REPO CONFIGURATION     #
#============================#
KEYRING_DIR="/etc/apt/keyrings"
KEYFILE="${KEYRING_DIR}/packages.mozilla.org.gpg"
SOURCES_FILE="/etc/apt/sources.list.d/mozilla.list"
PREF_FILE="/etc/apt/preferences.d/mozilla-firefox"
UNATTENDED_FILE="/etc/apt/apt.conf.d/51unattended-upgrades-firefox"

echo -e "${YELLOW}→ Creating keyring directory...${NC}"
mkdir -p "$KEYRING_DIR"

#============================#
#   IMPORT MOZILLA KEY       #
#============================#
echo -e "${YELLOW}→ Importing Mozilla APT repository key...${NC}"
wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | gpg --dearmor -o "$KEYFILE" \
    && echo -e "${GREEN}✔ Key imported successfully.${NC}" \
    || { echo -e "${RED}✖ Failed to import key. Exiting.${NC}"; exit 1; }

#============================#
#     ADD MOZILLA REPO       #
#============================#
echo -e "${YELLOW}→ Adding Mozilla APT repository...${NC}"
echo "deb [signed-by=${KEYFILE}] https://packages.mozilla.org/apt mozilla main" | tee "$SOURCES_FILE" >/dev/null

#============================#
#       SET APT PINNING      #
#============================#
echo -e "${YELLOW}→ Configuring APT pinning...${NC}"
cat > "$PREF_FILE" <<EOF
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1001

Package: firefox*
Pin: origin packages.mozilla.org
Pin-Priority: 1001
EOF

#============================#
#    UNATTENDED UPGRADES     #
#============================#
echo -e "${YELLOW}→ Setting unattended upgrade preferences...${NC}"
cat > "$UNATTENDED_FILE" <<EOF
Unattended-Upgrade::Origins-Pattern {
  "origin=packages.mozilla.org";
};
EOF

#============================#
#       UPDATE & INSTALL     #
#============================#
echo -e "${YELLOW}→ Updating package lists...${NC}"
apt-get update -y && echo -e "${GREEN}✔ Package list updated.${NC}"

echo -e "${YELLOW}→ Installing Firefox (Deb version)...${NC}"
if apt-get install -y firefox; then
    echo -e "${GREEN}✔ Firefox installed successfully from Mozilla repository.${NC}"
else
    echo -e "${RED}✖ Firefox installation failed.${NC}"
    exit 1
fi

#============================#
#         COMPLETION         #
#============================#
echo -e "${CYAN}"
echo "==========================================="
echo -e "${GREEN}🎉 Firefox (Deb) setup completed successfully!${NC}"
echo -e "${CYAN}👉 Launch it using: ${YELLOW}firefox${NC}"
echo "==========================================="
echo -e "${NC}"
