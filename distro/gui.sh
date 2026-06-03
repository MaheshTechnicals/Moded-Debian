#!/bin/bash

R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
W="$(printf '\033[1;37m')"
C="$(printf '\033[1;36m')"
arch=$(uname -m)
username=$(getent group sudo | awk -F ':' '{print $4}' | cut -d ',' -f1)

# Use $PREFIX for portability instead of hardcoded Termux path
TERMUX_BIN="${PREFIX:-/data/data/com.termux/files/usr}/bin"

check_root(){
	if [ "$(id -u)" -ne 0 ]; then
		echo -ne " ${R}Run this program as root!\n\n${W}"
		exit 1
	fi
}

# 🧩 Fix D-Bus machine-id to prevent VNC startup error
fix_machineid() {
    echo -e "${C}Checking D-Bus machine-id...${W}"
    if [ ! -s /etc/machine-id ]; then
        echo -e "${Y}Machine-id missing or empty. Generating new one...${W}"
        rm -f /var/lib/dbus/machine-id /etc/machine-id
        dbus-uuidgen --ensure=/etc/machine-id
        dbus-uuidgen --ensure
        ln -sf /etc/machine-id /var/lib/dbus/machine-id
        echo -e "${G}Machine-id successfully created.${W}"
    else
        echo -e "${G}Machine-id already exists.${W}"
    fi
}

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

note() {
	banner
	echo -e " ${G} [-] Successfully Installed !\n${W}"
	sleep 1
	cat <<- EOF
		 ${G}[-] Type ${C}vncstart${G} to run Vncserver.
		 ${G}[-] Type ${C}vncstop${G} to stop Vncserver.

		 ${C}Install VNC VIEWER Apk on your Device.

		 ${C}Open VNC VIEWER & Click on + Button.

		 ${C}Enter the Address localhost:1 & Name anything you like.

		 ${C}Set the Picture Quality to High for better Quality.

		 ${C}Click on Connect & Input the Password.

		 ${C}Enjoy :D${W}
	EOF
}

package() {
	banner
	echo -e "${R} [${W}-${R}]${C} Checking required packages...${W}"
	apt-get update -y
	apt install udisks2 -y
	rm /var/lib/dpkg/info/udisks2.postinst
	echo "" > /var/lib/dpkg/info/udisks2.postinst
	dpkg --configure -a
	apt-mark hold udisks2

	# These packages are all available in Debian
	packs=(sudo gnupg2 curl nano git xz-utils at-spi2-core xfce4 xfce4-goodies xfce4-terminal librsvg2-common menu inetutils-tools dialog exo-utils tigervnc-standalone-server tigervnc-common tigervnc-tools dbus-x11 fonts-beng fonts-beng-extra gtk2-engines-murrine gtk2-engines-pixbuf apt-transport-https gh)
	for hulu in "${packs[@]}"; do
		type -p "$hulu" &>/dev/null || {
			echo -e "\n${R} [${W}-${R}]${G} Installing package : ${Y}$hulu${W}"
			apt-get install "$hulu" -y --no-install-recommends
		}
	done

	apt-get update -y
	apt-get upgrade -y
}

install_apt() {
	for apt in "$@"; do
		[[ `command -v $apt` ]] && echo "${Y}${apt} is already Installed!${W}" || {
			echo -e "${G}Installing ${Y}${apt}${W}"
			apt install -y ${apt}
		}
	done
}

install_vscode() {
    [[ $(command -v code) ]] && echo "${Y}VSCode is already Installed!${W}" || {
        echo -e "${G}Installing ${Y}VSCode via external installer${W}"
        echo -e "${G}Installing ${Y}binutils${G} (required for VSCode installer)${W}"
        apt-get install -y binutils
        downloader "/tmp/code.sh" "https://raw.githubusercontent.com/MaheshTechnicals/Kali-Nethunter/refs/heads/main/vscode"
        chmod +x /tmp/code.sh
        bash /tmp/code.sh -i
        echo -e "${C} Visual Studio Code Installed Successfully\n${W}"
    }
}

install_sublime() {
	[[ $(command -v subl) ]] && echo "${Y}Sublime is already Installed!${W}" || {
		apt install gnupg2 software-properties-common --no-install-recommends -y
		echo "deb https://download.sublimetext.com/ apt/stable/" | tee /etc/apt/sources.list.d/sublime-text.list
		curl -fsSL https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor > /etc/apt/trusted.gpg.d/sublime.gpg 2> /dev/null
		apt update -y
		apt install sublime-text -y
		echo -e "${C} Sublime Text Editor Installed Successfully\n${W}"
	}
}

install_cursor() {
	[[ $(command -v cursor) ]] && echo "${Y}Cursor is already Installed!${W}" || {
		echo -e "${G}Installing ${Y}Cursor${W}"
		downloader "/tmp/cursor.sh" "https://raw.githubusercontent.com/MaheshTechnicals/cursor-free-vip-termux/refs/heads/main/cursor.sh"
		chmod +x /tmp/cursor.sh
		apt-get install -y expect
		expect <<'EOF'
set timeout -1
spawn sudo bash /tmp/cursor.sh -i
expect "Do you want to return to the main menu? (y/n):"
send "\r"
expect eof
EOF
		echo -e "${C} Cursor Editor Installed Successfully\n${W}"
	}
}

install_chromium() {
	# FIX: Debian Buster is EOL. Chromium is available directly in Debian Bookworm/Trixie main repos.
	# No need for extra sources — just install it directly.
	[[ $(command -v chromium) ]] && echo "${Y}Chromium is already Installed!${W}" || {
		echo -e "${G}Installing ${Y}Chromium${W}"
		apt-get update -y
		apt-get install -y chromium
		# Apply --no-sandbox flag for proot environment
		if [ -f /usr/share/applications/chromium.desktop ]; then
			sed -i 's/chromium %U/chromium --no-sandbox %U/g' /usr/share/applications/chromium.desktop
		fi
		echo -e "${G} Chromium Installed Successfully\n${W}"
	}
}

install_firefox() {
	[[ $(command -v firefox) ]] && echo "${Y}Firefox is already Installed!${W}" || {
		echo -e "${G}Installing ${Y}Firefox${W}"
		downloader "/tmp/firefox.sh" "https://raw.githubusercontent.com/MaheshTechnicals/Moded-Debian/refs/heads/main/distro/firefox.sh"
		chmod +x /tmp/firefox.sh
		sudo bash /tmp/firefox.sh
		echo -e "${G} Firefox Installed Successfully\n${W}"
	}
}

install_brave() {
	[[ $(command -v brave-browser) ]] && echo "${Y}Brave is already Installed!${W}" || {
		echo -e "${G}Installing ${Y}Brave${W}"
		downloader "/tmp/brave.sh" "https://raw.githubusercontent.com/MaheshTechnicals/Moded-Debian/refs/heads/main/distro/brave.sh"
		chmod +x /tmp/brave.sh
		sudo bash /tmp/brave.sh
		echo -e "${G} Brave Installed Successfully\n${W}"
	}
}

install_languages() {
	banner
	cat <<- EOF
		${Y} ---${G} Select Coding Languages ${Y}---

		${C} [${W}1${C}] Node.js
		${C} [${W}2${C}] Python
		${C} [${W}3${C}] All (Node.js + Python)
		${C} [${W}4${C}] Skip! (Default)

	EOF
	read -n1 -p "${R} [${G}~${R}]${Y} Select an Option: ${G}" LANG_OPTION
	{ banner; sleep 1; }

	install_node_latest() {
		echo -e "${G}Installing ${Y}Node.js (latest)${W}"
		apt-get update -y
		apt-get install -y nodejs npm
		npm install -g n
		n latest
		npm install -g npm@latest
		command -v node >/dev/null 2>&1 && node -v
	}

	install_python_latest() {
		echo -e "${G}Installing ${Y}Python (latest from repos)${W}"
		apt-get update -y
		apt-get install -y python3 python3-pip python3-venv
		python3 -m pip install --upgrade pip
		command -v python3 >/dev/null 2>&1 && python3 --version
	}

	if [[ ${LANG_OPTION} == 1 ]]; then
		install_node_latest
	elif [[ ${LANG_OPTION} == 2 ]]; then
		install_python_latest
	elif [[ ${LANG_OPTION} == 3 ]]; then
		install_node_latest
		install_python_latest
	else
		echo -e "${Y} [!] Skipping Language Installation\n"
		sleep 1
		return
	fi

	# Refresh shell environment for version checks
	hash -r
	source /etc/profile
}

install_softwares() {
	banner
	cat <<- EOF
		${Y} ---${G} Select Browser ${Y}---

		${C} [${W}1${C}] Firefox (Default)
		${C} [${W}2${C}] Chromium
		${C} [${W}3${C}] Brave
		${C} [${W}4${C}] All (Firefox + Chromium + Brave)

	EOF
	read -n1 -p "${R} [${G}~${R}]${Y} Select an Option: ${G}" BROWSER_OPTION
	banner

	[[ ("$arch" != 'armhf') || ("$arch" != *'armv7'*) ]] && {
		cat <<- EOF
			${Y} ---${G} Select IDE ${Y}---

			${C} [${W}1${C}] Cursor AI Editor (Recommended)
			${C} [${W}2${C}] Visual Studio Code
			${C} [${W}3${C}] All (Cursor + VSCode)
			${C} [${W}4${C}] Skip! (Default)

		EOF
		read -n1 -p "${R} [${G}~${R}]${Y} Select an Option: ${G}" IDE_OPTION
		banner
	}

	cat <<- EOF
		${Y} ---${G} Media Player ${Y}---

		${C} [${W}1${C}] MPV Media Player (Recommended)
		${C} [${W}2${C}] VLC Media Player
		${C} [${W}3${C}] All (MPV + VLC)
		${C} [${W}4${C}] Skip! (Default)

	EOF
	read -n1 -p "${R} [${G}~${R}]${Y} Select an Option: ${G}" PLAYER_OPTION
	{ banner; sleep 1; }

	if [[ ${BROWSER_OPTION} == 2 ]]; then
		install_chromium
	elif [[ ${BROWSER_OPTION} == 3 ]]; then
		install_brave
	elif [[ ${BROWSER_OPTION} == 4 ]]; then
		install_firefox
		install_chromium
		install_brave
	else
		install_firefox
	fi

	[[ ("$arch" != 'armhf') || ("$arch" != *'armv7'*) ]] && {
		if [[ ${IDE_OPTION} == 1 ]]; then
			install_cursor
		elif [[ ${IDE_OPTION} == 2 ]]; then
			install_vscode
		elif [[ ${IDE_OPTION} == 3 ]]; then
			install_cursor
			install_vscode
		else
			echo -e "${Y} [!] Skipping IDE Installation\n"
			sleep 1
		fi
	}

	if [[ ${PLAYER_OPTION} == 1 ]]; then
		install_apt "mpv"
	elif [[ ${PLAYER_OPTION} == 2 ]]; then
		install_apt "vlc"
	elif [[ ${PLAYER_OPTION} == 3 ]]; then
		install_apt "mpv" "vlc"
	else
		echo -e "${Y} [!] Skipping Media Player Installation\n"
		sleep 1
	fi

	install_languages
}

downloader(){
	path="$1"
	[[ -e "$path" ]] && rm -rf "$path"
	echo "Downloading $(basename $1)..."
	curl --progress-bar --insecure --fail \
		 --retry-connrefused --retry 3 --retry-delay 2 \
		 --location --output ${path} "$2"
}

sound_fix() {
	# FIX: use $TERMUX_BIN variable instead of hardcoded absolute path
	echo "$(echo "bash ~/.sound" | cat - "$TERMUX_BIN/debian")" > "$TERMUX_BIN/debian"
	echo "export DISPLAY=\":1\"" >> /etc/profile
	echo "export PULSE_SERVER=127.0.0.1" >> /etc/profile
	source /etc/profile
}

rem_theme() {
	theme=(Bright Daloa Emacs Moheli Retro Smoke)
	for rmi in "${theme[@]}"; do
		# Use directory check, not command check, for theme folders
		[ -d "/usr/share/themes/$rmi" ] && rm -rf "/usr/share/themes/$rmi"
	done
}

rem_icon() {
	# FIX: use directory existence check instead of type -p (which checks commands, not folders)
	# FIX: removed ubuntu-mono-light — it's Ubuntu-specific and won't exist on Debian
	icons=(LoginIcons)
	for rmf in "${icons[@]}"; do
		[ -d "/usr/share/icons/$rmf" ] && rm -rf "/usr/share/icons/$rmf"
	done
}

# ---- Auto-clear terminal on every Debian login ----
add_clear_on_login() {
    cat > /etc/profile.d/clear_on_login.sh <<'EOF'
# Clear terminal on login for a clean session
clear
EOF
    chmod 644 /etc/profile.d/clear_on_login.sh
    echo -e "${G}Auto-clear on login enabled.${W}"
}
# ---------------------------------------------------

add_alias_l() {
    cat > /etc/profile.d/alias_l.sh <<'EOF'
# alias l for ls
alias l='ls'
EOF
    chmod 644 /etc/profile.d/alias_l.sh

    if [ -f /etc/bash.bashrc ]; then
        grep -qxF "alias l='ls'" /etc/bash.bashrc || echo "alias l='ls'" >> /etc/bash.bashrc
    fi

    echo -e "${G}Alias 'l' -> 'ls' installed system-wide.${W}"
}

add_alias_cl() {
	cat > /etc/profile.d/alias_cl.sh <<'EOF'
# alias cl for clear
alias cl='clear'
EOF
	chmod 644 /etc/profile.d/alias_cl.sh

	if [ -f /etc/bash.bashrc ]; then
		grep -qxF "alias cl='clear'" /etc/bash.bashrc || echo "alias cl='clear'" >> /etc/bash.bashrc
	fi

	echo -e "${G}Alias 'cl' -> 'clear' installed system-wide.${W}"
}

config() {
	banner
	sound_fix

	# auto-clear terminal on login
	add_clear_on_login

	# install aliases
	add_alias_l
	add_alias_cl

	yes | apt upgrade
	yes | apt install gtk2-engines-murrine gtk2-engines-pixbuf sassc optipng inkscape libglib2.0-dev-bin
	mv -vf /usr/share/backgrounds/xfce/xfce-verticals.png /usr/share/backgrounds/xfce/xfce-verticals-old.png
	temp_folder=$(mktemp -d -p "$HOME")
	{ banner; sleep 1; cd $temp_folder; }

	echo -e "${R} [${W}-${R}]${C} Downloading Required Files..\n${W}"
	downloader "fonts.tar.gz"         "https://github.com/MaheshTechnicals/Moded-Debian/releases/download/config/fonts.tar.gz"
	downloader "icons.tar.gz"         "https://github.com/MaheshTechnicals/Moded-Debian/releases/download/config/icons.tar.gz"
	downloader "wallpaper.tar.gz"     "https://github.com/MaheshTechnicals/Moded-Debian/releases/download/config/wallpaper.tar.gz"
	downloader "gtk-themes.tar.gz"    "https://github.com/MaheshTechnicals/Moded-Debian/releases/download/config/gtk-themes.tar.gz"
	downloader "ubuntu-settings.tar.gz" "https://github.com/MaheshTechnicals/Moded-Debian/releases/download/config/ubuntu-settings.tar.gz"

	echo -e "${R} [${W}-${R}]${C} Unpacking Files..\n${W}"
	tar -xvzf fonts.tar.gz         -C "/usr/local/share/fonts/"
	tar -xvzf icons.tar.gz         -C "/usr/share/icons/"
	tar -xvzf wallpaper.tar.gz     -C "/usr/share/backgrounds/xfce/"
	tar -xvzf gtk-themes.tar.gz    -C "/usr/share/themes/"
	tar -xvzf ubuntu-settings.tar.gz -C "/home/$username/"
	rm -fr $temp_folder

	echo -e "${R} [${W}-${R}]${C} Purging Unnecessary Files..${W}"
	rem_theme
	rem_icon

	echo -e "${R} [${W}-${R}]${C} Rebuilding Font Cache..\n${W}"
	fc-cache -fv

	echo -e "${R} [${W}-${R}]${C} Upgrading the System..\n${W}"
	apt update
	yes | apt upgrade
	apt clean
	yes | apt autoremove
}

# ----------------------------
# 🛠️ Main Execution Flow
check_root
fix_machineid
package
install_softwares
config
note
