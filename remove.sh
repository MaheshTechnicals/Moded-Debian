#!/bin/bash
#
# remove.sh — Script to remove the modded Debian GUI setup from Termux
# Author: Mahesh Technicals

# ─────────────────────────────────────────────
# COLOR CODES
# ─────────────────────────────────────────────
R="$(printf '\033[1;31m')"   # Red
G="$(printf '\033[1;32m')"   # Green
Y="$(printf '\033[1;33m')"   # Yellow
B="$(printf '\033[1;34m')"   # Blue
C="$(printf '\033[1;36m')"   # Cyan
W="$(printf '\033[1;37m')"   # White
RESET="\033[0m"

# ─────────────────────────────────────────────
# BANNER
# ─────────────────────────────────────────────
banner() {
	clear
	cat <<- EOF
${C}    ____  __________  _______    _   __
${Y}   / __ \/ ____/ __ )/  _/   |  / | / /
${G}  / / / / __/ / __  |/ // /| | /  |/ / 
${C} / /_/ / /___/ /_/ // // ___ |/ /|  /  
${Y}/_____/_____/_____/___/_/  |_/_/ |_/   
${W}
	EOF

	echo -e "${G}💻 Debian GUI Setup Script by Mahesh Technicals\n${W}"
}

# ─────────────────────────────────────────────
# REMOVE FUNCTION
# ─────────────────────────────────────────────
package() {
    echo -e "${R}[${W}-${R}]${C} Purging Debian environment and configs...${W}"

    # Remove Debian distro if installed
    if proot-distro list | grep -q "debian"; then
        proot-distro remove debian && echo -e "${G}Debian removed successfully.${W}"
    else
        echo -e "${Y}Debian is not installed. Skipping removal.${W}"
    fi

    # Clear proot-distro cache
    proot-distro clear-cache >/dev/null 2>&1
    echo -e "${G}Proot cache cleared.${W}"

    # Remove Debian launcher (if exists)
    if [ -f "$PREFIX/bin/debian" ]; then
        rm -f "$PREFIX/bin/debian"
        echo -e "${G}Debian launcher removed.${W}"
    fi

    # Clean PulseAudio entries from ~/.sound (if exists)
    if [ -f "$HOME/.sound" ]; then
        sed -i '/pulseaudio --start --exit-idle-time=-1/d' "$HOME/.sound"
        sed -i '/pacmd load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1/d' "$HOME/.sound"
        echo -e "${G}Cleaned PulseAudio entries from ~/.sound.${W}"
    fi

    echo -e "\n${R}[${W}-${R}]${C} Purging completed successfully!${W}\n"
}

# ─────────────────────────────────────────────
# EXECUTION
# ─────────────────────────────────────────────
banner
package
