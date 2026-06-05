#!/bin/bash

R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
W="$(printf '\033[1;37m')"
C="$(printf '\033[1;36m')"

# Use $PREFIX for portability instead of hardcoded Termux path
TERMUX_BIN="${PREFIX:-/data/data/com.termux/files/usr}/bin"
TERMUX_HOME="${HOME:-/data/data/com.termux/files/home}"

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

	echo -e "${G}💻 Debian User Setup Script by Mahesh Technicals\n${W}"
}

sudo_setup() {
    echo -e "\n${R} [${W}-${R}]${C} Installing Sudo...${W}"
    apt update -y
    apt install sudo -y
    # locales-all is correct for Debian
    apt install wget apt-utils locales-all dialog tzdata -y
    echo -e "\n${R} [${W}-${R}]${G} Sudo Successfully Installed !${W}"
}

login() {
    banner
    read -p $' \e[1;31m[\e[0m\e[1;77m~\e[0m\e[1;31m]\e[0m\e[1;92m Input Username [Lowercase] : \e[0m\e[1;96m\en' user
    echo -e "${W}"
    read -s -p $' \e[1;31m[\e[0m\e[1;77m~\e[0m\e[1;31m]\e[0m\e[1;92m Input Password : \e[0m\e[1;96m\en' pass
    echo -e "${W}"
    useradd -m -s $(which bash) ${user}
    usermod -aG sudo ${user}
    echo "${user}:${pass}" | chpasswd
    echo "$user ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers

    # Write debian launcher with user login and fix permissions
    echo "clear; proot-distro login --user $user debian --bind /dev/null:/proc/sys/kernel/cap_last_last --shared-tmp --fix-low-ports" > "$TERMUX_BIN/debian"
    chmod +x "$TERMUX_BIN/debian"

    # FIX: corrected project folder name from modded-ubuntu to Moded-Debian
    if [[ -e "$TERMUX_HOME/Moded-Debian/distro/gui.sh" ]]; then
        cp "$TERMUX_HOME/Moded-Debian/distro/gui.sh" /home/$user/gui.sh
        chmod +x /home/$user/gui.sh
    else
        wget -q --show-progress https://raw.githubusercontent.com/MaheshTechnicals/Moded-Debian/refs/heads/main/distro/gui.sh
        mv -vf gui.sh /home/$user/gui.sh
        chmod +x /home/$user/gui.sh
    fi

    clear
    echo
    echo -e "\n${R} [${W}-${R}]${G} Restart your Termux & Type ${C}debian${W}"
    echo -e "\n${R} [${W}-${R}]${G} Then Type ${C}sudo bash gui.sh ${W}"
    echo
}

banner
sudo_setup
login
