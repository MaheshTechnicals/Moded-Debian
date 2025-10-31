#!/bin/bash
# ────────────────────────────────
# 💻 Debian GUI Setup Script by Mahesh Technicals
# Version: 5.0
# Description: Auto-installs Debian GUI + XFCE + Browsers + IDEs + Custom Terminal Style
# ────────────────────────────────

# ────────────────────────────────
# 🎨 COLOR DEFINITIONS
# ────────────────────────────────
R="$(printf '\033[1;31m')" # Red
G="$(printf '\033[1;32m')" # Green
Y="$(printf '\033[1;33m')" # Yellow
W="$(printf '\033[1;37m')" # White
C="$(printf '\033[1;36m')" # Cyan
B="$(printf '\033[1;34m')" # Blue
arch=$(uname -m)
username=$(getent group sudo | awk -F ':' '{print $4}' | cut -d ',' -f1)

# ────────────────────────────────
# ⚙️ BASIC CHECKS
# ────────────────────────────────
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

# ────────────────────────────────
# 💫 BANNER
# ────────────────────────────────
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
	echo -e "${G}💻 Debian GUI Setup Script by Mahesh Technicals${W}\n"
}

# ────────────────────────────────
# 📦 PACKAGE INSTALLATION
# ────────────────────────────────
package() {
	banner
	echo -e "${R} [${W}-${R}]${C} Checking required packages...${W}"
	apt-get update -y
	apt install udisks2 -y
	rm /var/lib/dpkg/info/udisks2.postinst
	echo "" > /var/lib/dpkg/info/udisks2.postinst
	dpkg --configure -a
	apt-mark hold udisks2

	packs=(sudo gnupg2 curl nano git xz-utils at-spi2-core xfce4 xfce4-goodies xfce4-terminal librsvg2-common menu inetutils-tools dialog exo-utils tigervnc-standalone-server tigervnc-common tigervnc-tools dbus-x11 fonts-beng fonts-beng-extra gtk2-engines-murrine gtk2-engines-pixbuf apt-transport-https)
	for hulu in "${packs[@]}"; do
		type -p "$hulu" &>/dev/null || {
			echo -e "\n${R} [${W}-${R}]${G} Installing package : ${Y}$hulu${W}"
			apt-get install "$hulu" -y --no-install-recommends
		}
	done
	
	apt-get update -y
	apt-get upgrade -y
}

# ────────────────────────────────
# 📦 SMALL HELPER INSTALLER
# ────────────────────────────────
install_apt() {
	for apt in "$@"; do
		[[ $(command -v $apt) ]] && echo -e "${Y}${apt} is already Installed!${W}" || {
			echo -e "${G}Installing ${Y}${apt}${W}"
			apt install -y ${apt}
		}
	done
}

# ────────────────────────────────
# 💻 SOFTWARE INSTALLERS
# ────────────────────────────────
install_vscode() {
	[[ $(command -v code) ]] && echo -e "${Y}VSCode is already Installed!${W}" || {
		echo -e "${G}Installing ${Y}VSCode via external installer${W}"
		downloader "/tmp/code.sh" "https://raw.githubusercontent.com/MaheshTechnicals/Kali-Nethunter/refs/heads/main/vscode"
		chmod +x /tmp/code.sh
		bash /tmp/code.sh -i
		echo -e "${C} Visual Studio Code Installed Successfully\n${W}"
	}
}

install_sublime() {
	[[ $(command -v subl) ]] && echo -e "${Y}Sublime is already Installed!${W}" || {
		apt install gnupg2 software-properties-common --no-install-recommends -y
		echo "deb https://download.sublimetext.com/ apt/stable/" | tee /etc/apt/sources.list.d/sublime-text.list
		curl -fsSL https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor > /etc/apt/trusted.gpg.d/sublime.gpg 2>/dev/null
		apt update -y
		apt install sublime-text -y
		echo -e "${C} Sublime Text Editor Installed Successfully\n${W}"
	}
}

install_chromium() {
	[[ $(command -v chromium) ]] && echo -e "${Y}Chromium is already Installed!${W}\n" || {
		echo -e "${G}Installing ${Y}Chromium${W}"
		apt purge chromium* chromium-browser* snapd -y
		apt install gnupg2 software-properties-common --no-install-recommends -y
		echo -e "deb http://ftp.debian.org/debian buster main\ndeb http://ftp.debian.org/debian buster-updates main" >> /etc/apt/sources.list
		apt-key adv --keyserver keyserver.ubuntu.com --recv-keys DCC9EFBF77E11517
		apt update -y
		apt install chromium -y
		sed -i 's/chromium %U/chromium --no-sandbox %U/g' /usr/share/applications/chromium.desktop
		echo -e "${G} Chromium Installed Successfully\n${W}"
	}
}

install_firefox() {
	[[ $(command -v firefox) ]] && echo -e "${Y}Firefox is already Installed!${W}\n" || {
		echo -e "${G}Installing ${Y}Firefox${W}"
		bash <(curl -fsSL "https://raw.githubusercontent.com/MaheshTechnicals/Moded-Debian/refs/heads/main/distro/firefox.sh")
		echo -e "${G} Firefox Installed Successfully\n${W}"
	}
}

# ────────────────────────────────
# 🎛️ INTERACTIVE SOFTWARE SELECTION
# ────────────────────────────────
install_softwares() {
	banner
	cat <<- EOF
		${Y} ---${G} Select Browser ${Y}---

		${C} [${W}1${C}] Firefox (Default)
		${C} [${W}2${C}] Chromium
		${C} [${W}3${C}] Both (Firefox + Chromium)

	EOF
	read -n1 -p "${R} [${G}~${R}]${Y} Select an Option: ${G}" BROWSER_OPTION
	banner

	[[ ("$arch" != 'armhf') || ("$arch" != *'armv7'*) ]] && {
		cat <<- EOF
			${Y} ---${G} Select IDE ${Y}---

			${C} [${W}1${C}] Sublime Text Editor (Recommended)
			${C} [${W}2${C}] Visual Studio Code
			${C} [${W}3${C}] Both (Sublime + VSCode)
			${C} [${W}4${C}] Skip! (Default)

		EOF
		read -n1 -p "${R} [${G}~${R}]${Y} Select an Option: ${G}" IDE_OPTION
		banner
	}
	
	cat <<- EOF
		${Y} ---${G} Media Player ${Y}---

		${C} [${W}1${C}] MPV Media Player (Recommended)
		${C} [${W}2${C}] VLC Media Player
		${C} [${W}3${C}] Both (MPV + VLC)
		${C} [${W}4${C}] Skip! (Default)

	EOF
	read -n1 -p "${R} [${G}~${R}]${Y} Select an Option: ${G}" PLAYER_OPTION
	banner

	if [[ ${BROWSER_OPTION} == 2 ]]; then
		install_chromium
	elif [[ ${BROWSER_OPTION} == 3 ]]; then
		install_firefox
		install_chromium
	else
		install_firefox
	fi

	[[ ("$arch" != 'armhf') || ("$arch" != *'armv7'*) ]] && {
		if [[ ${IDE_OPTION} == 1 ]]; then
			install_sublime
		elif [[ ${IDE_OPTION} == 2 ]]; then
			install_vscode
		elif [[ ${IDE_OPTION} == 3 ]]; then
			install_sublime
			install_vscode
		else
			echo -e "${Y} [!] Skipping IDE Installation\n"
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
	fi
}

# ────────────────────────────────
# 🌐 DOWNLOADER HELPER
# ────────────────────────────────
downloader(){
	path="$1"
	[[ -e "$path" ]] && rm -rf "$path"
	echo "Downloading $(basename $1)..."
	curl --progress-bar --insecure --fail \
		 --retry-connrefused --retry 3 --retry-delay 2 \
		 --location --output ${path} "$2"
}

# ────────────────────────────────
# 🔊 SOUND + DISPLAY FIX
# ────────────────────────────────
sound_fix() {
	echo "$(echo "bash ~/.sound" | cat - /data/data/com.termux/files/usr/bin/debian)" > /data/data/com.termux/files/usr/bin/debian
	echo "export DISPLAY=:1" >> /etc/profile
	echo "export PULSE_SERVER=127.0.0.1" >> /etc/profile
	source /etc/profile
}

# ────────────────────────────────
# 🧹 CLEANUP
# ────────────────────────────────
rem_theme() {
	theme=(Bright Daloa Emacs Moheli Retro Smoke)
	for rmi in "${theme[@]}"; do
		rm -rf /usr/share/themes/"$rmi"
	done
}

rem_icon() {
	fonts=(hicolor LoginIcons ubuntu-mono-light)
	for rmf in "${fonts[@]}"; do
		rm -rf /usr/share/icons/"$rmf"
	done
}

# ────────────────────────────────
# ⚡ ADD ALIAS
# ────────────────────────────────
add_alias_l() {
	cat > /etc/profile.d/alias_l.sh <<'EOF'
# alias l for ls
alias l='ls'
EOF
	chmod 644 /etc/profile.d/alias_l.sh
	grep -qxF "alias l='ls'" /etc/bash.bashrc || echo "alias l='ls'" >> /etc/bash.bashrc
	echo -e "${G}Alias 'l' -> 'ls' installed system-wide.${W}"
}

# ────────────────────────────────
# 🧩 CONFIGURATION & THEMES
# ────────────────────────────────
config() {
	banner
	sound_fix
	add_alias_l

	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3B4FE6ACC0B21F32
	yes | apt upgrade
	yes | apt install gtk2-engines-murrine gtk2-engines-pixbuf sassc optipng inkscape libglib2.0-dev-bin

	mv -vf /usr/share/backgrounds/xfce/xfce-verticals.png /usr/share/backgrounds/xfce/xfceverticals-old.png
	temp_folder=$(mktemp -d -p "$HOME")
	banner
	echo -e "${R} [${W}-${R}]${C} Downloading Required Files..${W}\n"

	downloader "fonts.tar.gz" "https://github.com/MaheshTechnicals/Moded-Debian/releases/download/config/fonts.tar.gz"
	downloader "icons.tar.gz" "https://github.com/MaheshTechnicals/Moded-Debian/releases/download/config/icons.tar.gz"
	downloader "wallpaper.tar.gz" "https://github.com/MaheshTechnicals/Moded-Debian/releases/download/config/wallpaper.tar.gz"
	downloader "gtk-themes.tar.gz" "https://github.com/MaheshTechnicals/Moded-Debian/releases/download/config/gtk-themes.tar.gz"
	downloader "ubuntu-settings.tar.gz" "https://github.com/MaheshTechnicals/Moded-Debian/releases/download/config/ubuntu-settings.tar.gz"

	echo -e "${R} [${W}-${R}]${C} Unpacking Files..${W}\n"
	tar -xvzf fonts.tar.gz -C "/usr/local/share/fonts/"
	tar -xvzf icons.tar.gz -C "/usr/share/icons/"
	tar -xvzf wallpaper.tar.gz -C "/usr/share/backgrounds/xfce/"
	tar -xvzf gtk-themes.tar.gz -C "/usr/share/themes/"
	tar -xvzf ubuntu-settings.tar.gz -C "/home/$username/"
	rm -fr $temp_folder

	echo -e "${R} [${W}-${R}]${C} Purging Unnecessary Files..${W}"
	rem_theme
	rem_icon

	echo -e "${R} [${W}-${R}]${C} Rebuilding Font Cache..${W}\n"
	fc-cache -fv

	echo -e "${R} [${W}-${R}]${C} Upgrading the System..${W}\n"
	apt update
	yes | apt upgrade
	apt clean
	yes | apt autoremove
}

# ────────────────────────────────
# 🌈 TERMINAL STYLE INSTALLER (FIXED)
# ────────────────────────────────
install_terminal_style() {
	banner
	echo -e "${R} [${W}-${R}]${C} Applying Custom Terminal Style...${W}\n"
	temp_dir=$(mktemp -d)
	downloader "${temp_dir}/fansy.sh" "https://raw.githubusercontent.com/MaheshTechnicals/Moded-Debian/refs/heads/main/distro/fansy.sh"
	chmod +x "${temp_dir}/fansy.sh"
	
	# ✅ Run as root (no sudo) to prevent hanging
	bash "${temp_dir}/fansy.sh" || {
		echo -e "${R} [!] Failed to apply terminal style!${W}"
	}
	
	rm -rf "${temp_dir}"
	echo -e "\n${G}✨ Terminal Styling Applied Successfully!${W}\n"
}

# ────────────────────────────────
# 📜 COMPLETION NOTE
# ────────────────────────────────
note() {
	banner
	echo -e " ${G} [-] Successfully Installed !\n${W}"
	sleep 1
	cat <<- EOF
		 ${G}[-] Type ${C}vncstart${G} to run Vncserver.
		 ${G}[-] Type ${C}vncstop${G} to stop Vncserver.

		 ${C}Install VNC VIEWER Apk on your Device.
		 ${C}Open VNC VIEWER & Click on + Button.
		 ${C}Enter Address: localhost:1 & any Name you like.
		 ${C}Set Picture Quality: High for better Quality.
		 ${C}Click on Connect & Input the Password.
		 ${C}Enjoy :D${W}
	EOF
}

# ────────────────────────────────
# 🛠️ MAIN EXECUTION FLOW
# ────────────────────────────────
check_root
fix_machineid
package
install_softwares
config
install_terminal_style
note
