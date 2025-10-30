#!/bin/bash

R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
B="$(printf '\033[1;34m')"
C="$(printf '\033[1;36m')"
W="$(printf '\033[1;37m')" 

CURR_DIR=$(realpath "$(dirname "$BASH_SOURCE")")
# Changed to Debian
DEBIAN_DIR="$PREFIX/var/lib/proot-distro/installed-rootfs/debian"

banner() {
    clear
    echo -e "${C}"
    cat << "EOF"
                                                                                                
8 888888888o.      8 8888888888   8 888888888o    8 8888          .8.          b.             8 
8 8888    `^888.   8 8888         8 8888    `88.  8 8888         .888.         888o.          8 
8 8888        `88. 8 8888         8 8888     `88  8 8888        :88888.        Y88888o.       8 
8 8888         `88 8 8888         8 8888     ,88  8 8888       . `88888.       .`Y888888o.    8 
8 8888          88 8 888888888888 8 8888.   ,88'  8 8888      .8. `88888.      8o. `Y888888o. 8 
8 8888          88 8 8888         8 8888888888    8 8888     .8`8. `88888.     8`Y8o. `Y88888o8 
8 8888         ,88 8 8888         8 8888    `88.  8 8888    .8' `8. `88888.    8   `Y8o. `Y8888 
8 8888        ,88' 8 8888         8 8888      88  8 8888   .8'   `8. `88888.   8      `Y8o. `Y8 
8 8888    ,o88P'   8 8888         8 8888    ,88'  8 8888  .888888888. `88888.  8         `Y8o.` 
8 888888888P'      8 888888888888 8 888888888P    8 8888 .8'       `8. `88888. 8            `Yo 
EOF
    echo -e "${W}"
    echo "======================================================================================="
    echo -e "${G}                   💻  Debian GUI Setup Script by Mahesh Technicals"
    echo "======================================================================================="
    echo
}


package() {
	banner
	echo -e "${R} [${W}-${R}]${C} Checking required packages..."${W}
	
	[ ! -d '/data/data/com.termux/files/home/storage' ] && echo -e "${R} [${W}-${R}]${C} Setting up Storage.."${W} && termux-setup-storage

	if [[ $(command -v pulseaudio) && $(command -v proot-distro) ]]; then
		echo -e "\n${R} [${W}-${R}]${G} Packages already installed."${W}
	else
		yes | pkg upgrade
		packs=(pulseaudio proot-distro)
		for x in "${packs[@]}"; do
			type -p "$x" &>/dev/null || {
				echo -e "\n${R} [${W}-${R}]${G} Installing package : ${Y}$x${C}"${W}
				yes | pkg install "$x"
			}
		done
	fi
}

distro() {
	echo -e "\n${R} [${W}-${R}]${C} Checking for Distro..."${W}
	termux-reload-settings
	
    # Changed to Debian
	if [[ -d "$DEBIAN_DIR" ]]; then
		echo -e "\n${R} [${W}-${R}]${G} Distro already installed."${W}
		exit 0
	else
        # Changed to Debian
		proot-distro install debian
		termux-reload-settings
	fi
	
    # Changed to Debian
	if [[ -d "$DEBIAN_DIR" ]]; then
		echo -e "\n${R} [${W}-${R}]${G} Installed Successfully !!"${W}
	else
		echo -e "\n${R} [${W}-${R}]${G} Error Installing Distro !\n"${W}
		exit 0
	fi
}

sound() {
	echo -e "\n${R} [${W}-${R}]${C} Fixing Sound Problem..."${W}
	[ ! -e "$HOME/.sound" ] && touch "$HOME/.sound"
	echo "pacmd load-module module-aaudio-sink" >> "$HOME/.sound"
        echo "pulseaudio --start --exit-idle-time=-1" >> "$HOME/.sound"
	echo "pacmd load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" >> "$HOME/.sound"
}

downloader(){
	path="$1"
	[ -e "$path" ] && rm -rf "$path"
	echo "Downloading $(basename $1)..."
	curl --progress-bar --insecure --fail \
		 --retry-connrefused --retry 3 --retry-delay 2 \
		  --location --output ${path} "$2"
	echo
}

setup_vnc() {
    # Changed to Debian
	if [[ -d "$CURR_DIR/distro" ]] && [[ -e "$CURR_DIR/distro/vncstart" ]]; then
		cp -f "$CURR_DIR/distro/vncstart" "$DEBIAN_DIR/usr/local/bin/vncstart"
	else
		downloader "$CURR_DIR/vncstart" "https://raw.githubusercontent.com/MaheshTechnicals/Moded-Debian/refs/heads/main/distro/vncstart"
		mv -f "$CURR_DIR/vncstart" "$DEBIAN_DIR/usr/local/bin/vncstart"
	fi

	if [[ -d "$CURR_DIR/distro" ]] && [[ -e "$CURR_DIR/distro/vncstop" ]]; then
		cp -f "$CURR_DIR/distro/vncstop" "$DEBIAN_DIR/usr/local/bin/vncstop"
	else
		downloader "$CURR_DIR/vncstop" "https://raw.githubusercontent.com/MaheshTechnicals/Moded-Debian/refs/heads/main/distro/vncstop"
		mv -f "$CURR_DIR/vncstop" "$DEBIAN_DIR/usr/local/bin/vncstop"
	fi
	chmod +x "$DEBIAN_DIR/usr/local/bin/vncstart"
	chmod +x "$DEBIAN_DIR/usr/local/bin/vncstop"
}

permission() {
	banner
	echo -e "${R} [${W}-${R}]${C} Setting up Environment..."${W}

    # Changed to Debian
	if [[ -d "$CURR_DIR/distro" ]] && [[ -e "$CURR_DIR/distro/user.sh" ]]; then
		cp -f "$CURR_DIR/distro/user.sh" "$DEBIAN_DIR/root/user.sh"
	else
		downloader "$CURR_DIR/user.sh" "https://raw.githubusercontent.com/MaheshTechnicals/Moded-Debian/refs/heads/main/distro/user.sh"
		mv -f "$CURR_DIR/user.sh" "$DEBIAN_DIR/root/user.sh"
	fi
	chmod +x $DEBIAN_DIR/root/user.sh

	setup_vnc
    # Changed to Debian
	echo "$(getprop persist.sys.timezone)" > $DEBIAN_DIR/etc/timezone
    # Changed to Debian
	echo "proot-distro login debian" > $PREFIX/bin/debian
	chmod +x "$PREFIX/bin/debian"
	termux-reload-settings

    # Changed to Debian
	if [[ -e "$PREFIX/bin/debian" ]]; then
		banner
		cat <<- EOF
			${R} [${W}-${R}]${G} Debian (CLI) is now Installed on your Termux
			${R} [${W}-${R}]${G} Restart your Termux to Prevent Some Issues.
			${R} [${W}-${R}]${G} Type ${C}debian${G} to run Debian CLI.
			${R} [${W}-${R}]${G} If you Want to Use DEBIAN in GUI MODE then ,
			${R} [${W}-${R}]${G} Run ${C}debian${G} first & then type ${C}bash user.sh${W}
		EOF
		{ echo; sleep 2; exit 1; }
	else
		echo -e "\n${R} [${W}-${R}]${G} Error Installing Distro !"${W}
		exit 0
	fi

}

package
distro
sound
permission
