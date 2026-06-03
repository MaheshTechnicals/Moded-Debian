#!/bin/bash

# ─────────────────────────────────────────────
# 📋 LOGGING INITIALIZATION
# ─────────────────────────────────────────────
LOG_FILE="/var/log/debian_setup.log"

# Create a clean log file or empty existing one
touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/debian_setup.log"
echo "=== Setup Log Started At $(date) ===" >"$LOG_FILE"

# Helper function to write messages cleanly to the log file
log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >>"$LOG_FILE"
}

# Redirect all background installation processes to log without cluttering screen
# Usage: run_silent "Task Description" command args...
run_silent() {
    local task_name="$1"
    shift
    log_msg "STARTING: $task_name"
    echo -e "${C}Running: ${Y}$task_name...${W}"

    # Execute the command, appending stdout and stderr directly to the log file
    if "$@" >>"$LOG_FILE" 2>&1; then
        log_msg "SUCCESS: $task_name"
        echo -e "${G}✓ $task_name completed successfully.${W}"
    else
        log_msg "ERROR: $task_name failed with exit code $?"
        echo -e "${R}✗ ERROR in: $task_name (Check $LOG_FILE for details)${W}"
        sleep 2 # Let the user see that a specific block threw an error
    fi
}

# ─────────────────────────────────────────────
# VARIABLES & STYLES
# ─────────────────────────────────────────────
R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
W="$(printf '\033[1;37m')"
C="$(printf '\033[1;36m')"
arch=$(uname -m)

# Use $PREFIX for portability instead of hardcoded Termux path
TERMUX_BIN="${PREFIX:-/data/data/com.termux/files/usr}/bin"

# Safely get the first sudo user — with fallback if none exists yet
username=$(getent group sudo | awk -F ':' '{print $4}' | cut -d ',' -f1)
if [[ -z "$username" ]]; then
    username=$(ls /home 2>/dev/null | head -n1)
fi

# ─────────────────────────────────────────────
# HELPER: downloader
# ─────────────────────────────────────────────
downloader() {
    path="$1"
    [[ -e "$path" ]] && rm -rf "$path"
    log_msg "Downloading $2 to $path"
    # Added --silent but kept --show-error so failures print to the log
    curl --silent --show-error --insecure --fail \
        --retry-connrefused --retry 3 --retry-delay 2 \
        --location --output "${path}" "$2"
}

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -ne " ${R}Run this program as root!\n\n${W}"
        log_msg "CRITICAL: Script stopped. Script was not run as root user."
        exit 1
    fi
}

# 🧩 Fix D-Bus machine-id to prevent VNC startup error
fix_machineid() {
    echo -e "${C}Checking D-Bus machine-id...${W}"
    if [ ! -s /etc/machine-id ]; then
        echo -e "${Y}Machine-id missing or empty. Generating new one...${W}"
        rm -f /var/lib/dbus/machine-id /etc/machine-id
        dbus-uuidgen --ensure=/etc/machine-id >> "$LOG_FILE" 2>&1
        dbus-uuidgen --ensure >> "$LOG_FILE" 2>&1
        ln -sf /etc/machine-id /var/lib/dbus/machine-id
        echo -e "${G}Machine-id successfully created.${W}"
        log_msg "Machine-id was missing; new one generated successfully."
    else
        echo -e "${G}Machine-id already exists.${W}"
        log_msg "Machine-id verification skipped: file already valid."
    fi
}

banner() {
    clear
    cat << 'EOF'
 ____  __________  _______    _   __
/ __ \/ ____/ __ )/  _/   |  / | / /
/ / / / __/ / __  |/ // /| | /  |/ / 
/ /_/ / /___/ /_/ // // ___ |/ /|  /  
/_____/_____/_____/___/_/  |_/_/ |_/   
EOF
    echo -e "${G}💻 Debian GUI Setup Script by Mahesh Technicals\n${W}"
}

note() {
    banner
    echo -e " ${G} [-] Successfully Installed !\n${W}"
    echo -e " ${Y} [*] You can check all execution logs at: $LOG_FILE\n${W}"
    sleep 1
    cat << 'EOF'
         [-] Type vncstart to run Vncserver.
         [-] Type vncstop to stop Vncserver.

         Install VNC VIEWER Apk on your Device.

         Open VNC VIEWER & Click on + Button.

         Enter the Address localhost:1 & Name anything you like.

         Set the Picture Quality to High for better Quality.

         Click on Connect & Input the Password.

         Enjoy :D
EOF
    log_msg "=== Setup Completed Successfully ==="
}

package() {
    banner
    echo -e "${R} [${W}-${R}]${C} Checking required packages...${W}"

    run_silent "Updating apt repositories" apt-get update -y
    run_silent "Installing udisks2 package" apt install udisks2 -y

    rm -f /var/lib/dpkg/info/udisks2.postinst
    echo "" >/var/lib/dpkg/info/udisks2.postinst

    run_silent "Configuring DPKG" dpkg --configure -a
    run_silent "Holding udisks2 package package changes" apt-mark hold udisks2

    packs=(sudo gnupg2 curl nano git xz-utils at-spi2-core xfce4 xfce4-goodies xfce4-terminal librsvg2-common menu inetutils-tools dialog exo-utils tigervnc-standalone-server tigervnc-common tigervnc-tools dbus-x11 fonts-beng fonts-beng-extra gtk2-engines-murrine gtk2-engines-pixbuf apt-transport-https gh)

    for hulu in "${packs[@]}"; do
        if ! dpkg -s "$hulu" &>/dev/null; then
            run_silent "Installing environment dependency: $hulu" apt-get install "$hulu" -y --no-install-recommends
        fi
    done

    run_silent "System repository update" apt-get update -y
    run_silent "System core package upgrade" apt-get upgrade -y
}

install_apt() {
    for pkg in "$@"; do
        if dpkg -s "$pkg" &>/dev/null; then
            echo "${Y}${pkg} is already Installed!${W}"
            log_msg "Apt Installer: $pkg is already matching on system."
        else
            run_silent "Apt tracking package manual installation: $pkg" apt install -y "${pkg}"
        fi
    done
}

install_vscode() {
    [[ $(command -v code) ]] && echo "${Y}VSCode is already Installed!${W}" || {
        run_silent "Installing VSCode binutils requirements" apt-get install -y binutils
        run_silent "Downloading VSCode setup deployment file" downloader "/tmp/code.sh" "https://raw.githubusercontent.com/MaheshTechnicals/Kali-Nethunter/refs/heads/main/vscode"
        chmod +x /tmp/code.sh
        run_silent "Executing VSCode external installation binary script" bash /tmp/code.sh -i
    }
}

install_sublime() {
    [[ $(command -v subl) ]] && echo "${Y}Sublime is already Installed!${W}" || {
        run_silent "Installing common environment dependencies for Sublime" apt install gnupg2 software-properties-common --no-install-recommends -y
        echo "deb https://download.sublimetext.com/ apt/stable/" | tee /etc/apt/sources.list.d/sublime-text.list >>"$LOG_FILE" 2>&1
        curl -fsSL https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor >/etc/apt/trusted.gpg.d/sublime.gpg 2>>"$LOG_FILE"
        run_silent "Updating source indexes for Sublime repository structural layout" apt update -y
        run_silent "Installing custom build Sublime Text editor binary" apt install sublime-text -y
    }
}

install_cursor() {
    [[ $(command -v cursor) ]] && echo "${Y}Cursor is already Installed!${W}" || {
        run_silent "Downloading Cursor setup installer script files" downloader "/tmp/cursor.sh" "https://raw.githubusercontent.com/MaheshTechnicals/cursor-free-vip-termux/refs/heads/main/cursor.sh"
        chmod +x /tmp/cursor.sh
        run_silent "Installing automated expect engine tracking package" apt-get install -y expect

        log_msg "Spawning interactive expect shell container sequence for Cursor configuration"
        expect <<EOF >>"$LOG_FILE" 2>&1
set timeout -1
spawn sudo bash /tmp/cursor.sh -i
expect "Do you want to return to the main menu? (y/n):"
send "\r"
expect eof
EOF
        log_msg "Expect terminal interface engine processing closed safely."
    }
}

install_chromium() {
    dpkg -s chromium &>/dev/null && echo "${Y}Chromium is already Installed!${W}" || {
        run_silent "Updating repository references for Chromium setup" apt-get update -y
        run_silent "Installing standard secure distribution build of Chromium" apt-get install -y chromium
        if [ -f /usr/share/applications/chromium.desktop ]; then
            sed -i 's/chromium %U/chromium --no-sandbox %U/g' /usr/share/applications/chromium.desktop
            log_msg "Applied container safety bypass flag (--no-sandbox) natively inside chromium launcher profiles."
        fi
    }
}

install_firefox() {
    [[ $(command -v firefox) ]] && echo "${Y}Firefox is already Installed!${W}" || {
        run_silent "Downloading safe native engine tracking files for Firefox deployment" downloader "/tmp/firefox.sh" "https://raw.githubusercontent.com/MaheshTechnicals/Moded-Debian/refs/heads/main/distro/firefox.sh"
        chmod +x /tmp/firefox.sh
        run_silent "Executing custom helper automation for Mozilla components" bash /tmp/firefox.sh
    }
}

install_brave() {
    [[ $(command -v brave-browser) ]] && echo "${Y}Brave is already Installed!${W}" || {
        run_silent "Downloading Brave configuration engine assets" downloader "/tmp/brave.sh" "https://raw.githubusercontent.com/MaheshTechnicals/Moded-Debian/refs/heads/main/distro/brave.sh"
        chmod +x /tmp/brave.sh
        run_silent "Executing third-party layout setup configuration scripts for Brave" bash /tmp/brave.sh
    }

    mkdir -p /usr/share/xfce4/helpers
    if [ ! -f /usr/share/xfce4/helpers/brave-browser.desktop ]; then
        cat >/usr/share/xfce4/helpers/brave-browser.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Type=X-XFCE-Helper
X-XFCE-Category=WebBrowser
X-XFCE-CommandsWithParameter=brave-browser --no-sandbox "%s"
Icon=brave-browser
Name=Brave Web Browser
X-XFCE-Commands=brave-browser --no-sandbox
EOF
        log_msg "Registered XFCE application fallback desktop structures explicitly for Brave Web Browser."
    fi

    command -v update-desktop-database >/dev/null 2>&1 &&
        update-desktop-database /usr/share/applications >>"$LOG_FILE" 2>&1 &&
        log_msg "Refreshed primary desktop app system records cleanly."
}

set_default_browser() {
    echo -e "\n${R} [${W}-${R}]${C} Setting Firefox as default browser...${W}"
    log_msg "Initiating system default browser adjustments to default system mapping entries: Firefox"

    if command -v xdg-settings >/dev/null 2>&1 && [ -n "${DISPLAY:-}" ]; then
        xdg-settings set default-web-browser firefox.desktop >>"$LOG_FILE" 2>&1 &&
            log_msg "xdg-settings updated context browser pointers safely."
    fi

    if command -v update-alternatives >/dev/null 2>&1; then
        update-alternatives --set x-www-browser "$(command -v firefox)" >>"$LOG_FILE" 2>&1 &&
            log_msg "update-alternatives points web hooks towards Firefox."
    fi

    cat >/etc/profile.d/default_browser.sh <<'EOF'
export BROWSER=firefox
EOF
    chmod 644 /etc/profile.d/default_browser.sh

    for homedir in /root "/home/$username"; do
        [ -d "$homedir" ] || continue
        mkdir -p "$homedir/.config/xfce4"
        mkdir -p "$homedir/.config"

        cat >"$homedir/.config/mimeapps.list" <<'EOF'
[Default Applications]
text/html=firefox.desktop
x-scheme-handler/http=firefox.desktop
x-scheme-handler/https=firefox.desktop
x-scheme-handler/about=firefox.desktop
x-scheme-handler/unknown=firefox.desktop
EOF
        log_msg "Updated localized context applications configuration: $homedir/.config/mimeapps.list"

        if [ -f "$homedir/.config/xfce4/helpers.rc" ]; then
            if grep -q "^WebBrowser=" "$homedir/.config/xfce4/helpers.rc"; then
                sed -i 's/^WebBrowser=.*/WebBrowser=firefox/' "$homedir/.config/xfce4/helpers.rc"
            else
                echo "WebBrowser=firefox" >>"$homedir/.config/xfce4/helpers.rc"
            fi
        else
            echo "WebBrowser=firefox" >"$homedir/.config/xfce4/helpers.rc"
        fi
        log_msg "Modified desktop environment components tracking structure: $homedir/.config/xfce4/helpers.rc"
    done
}

install_languages() {
    banner
    cat << 'EOF'
         --- Select Coding Languages ---

         [1] Node.js
         [2] Python
         [3] All (Node.js + Python)
         [4] Skip! (Default)
EOF
    read -n1 -p "${R} [${G}~${R}]${Y} Select an Option: ${G}" LANG_OPTION
    {
        banner
        sleep 1
    }

    install_node_latest() {
        run_silent "Updating dependencies for JS environments" apt-get update -y
        run_silent "Installing initial distribution packages for Node.js and NPM modules" apt-get install -y nodejs npm
        run_silent "Installing runtime global manager utility module (n)" npm install -g n
        run_silent "Switching Node engine to absolute stable production release" n latest
        run_silent "Upgrading global node package manager execution client layer" npm install -g npm@latest
    }

    install_python_latest() {
        run_silent "Updating repository tracking flags for python dependencies" apt-get update -y
        run_silent "Installing Python core runtime environment modules and safe sandbox setups" apt-get install -y python3 python3-pip python3-venv
        log_msg "Python environment installed. Note: Use 'python3 -m venv <env_name>' to safely create environments and manage pip."
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
        log_msg "User skipped manual backend language interpreter tasks selection."
        sleep 1
        return
    fi

    hash -r
    source /etc/profile
}

install_softwares() {
    banner

    echo -e "${R} [${W}-${R}]${C} Installing Browsers...${W}"
    install_firefox
    install_chromium
    install_brave
    set_default_browser

    [[ ("$arch" != 'armhf') || ("$arch" != *'armv7'*) ]] && {
        banner
        cat << 'EOF'
             --- Select IDE ---

             [1] Cursor AI Editor (Recommended)
             [2] Visual Studio Code
             [3] All (Cursor + VSCode)
             [4] Skip! (Default)
EOF
        read -n1 -p "${R} [${G}~${R}]${Y} Select an Option: ${G}" IDE_OPTION
        banner

        if [[ ${IDE_OPTION} == 1 ]]; then
            install_cursor
        elif [[ ${IDE_OPTION} == 2 ]]; then
            install_vscode
        elif [[ ${IDE_OPTION} == 3 ]]; then
            install_cursor
            install_vscode
        else
            echo -e "${Y} [!] Skipping IDE Installation\n"
            log_msg "User opted out of IDE profile deployment tools."
            sleep 1
        fi
    }

    banner
    cat << 'EOF'
         --- Media Player ---

         [1] MPV Media Player (Recommended)
         [2] VLC Media Player
         [3] All (MPV + VLC)
         [4] Skip! (Default)
EOF
    read -n1 -p "${R} [${G}~${R}]${Y} Select an Option: ${G}" PLAYER_OPTION
    {
        banner
        sleep 1
    }

    if [[ ${PLAYER_OPTION} == 1 ]]; then
        install_apt "mpv"
    elif [[ ${PLAYER_OPTION} == 2 ]]; then
        install_apt "vlc"
    elif [[ ${PLAYER_OPTION} == 3 ]]; then
        install_apt "mpv" "vlc"
    else
        echo -e "${Y} [!] Skipping Media Player Installation\n"
        log_msg "User configuration selection skipped multimedia packages."
        sleep 1
    fi

    install_languages
}

sound_fix() {
    if ! grep -q "bash ~/.sound" "$TERMUX_BIN/debian" 2>/dev/null; then
        echo "$(echo "bash ~/.sound" | cat - "$TERMUX_BIN/debian")" >"$TERMUX_BIN/debian"
        chmod +x "$TERMUX_BIN/debian"
        log_msg "Sound Fix: Embedded startup processing configurations inside Termux application launch files."
    fi
    grep -qxF 'export DISPLAY=":1"' /etc/profile || echo 'export DISPLAY=":1"' >>/etc/profile
    grep -qxF 'export PULSE_SERVER=127.0.0.1' /etc/profile || echo 'export PULSE_SERVER=127.0.0.1' >>/etc/profile
    source /etc/profile
}

rem_theme() {
    theme=(Bright Daloa Emacs Moheli Retro Smoke)
    for rmi in "${theme[@]}"; do
        if [ -d "/usr/share/themes/$rmi" ]; then
            rm -rf "/usr/share/themes/$rmi"
            log_msg "Purged obsolete desktop theme folder structure: /usr/share/themes/$rmi"
        fi
    done
}

rem_icon() {
    icons=(LoginIcons)
    for rmf in "${icons[@]}"; do
        if [ -d "/usr/share/icons/$rmf" ]; then
            rm -rf "/usr/share/icons/$rmf"
            log_msg "Purged old system interface icons mapping directory: /usr/share/icons/$rmf"
        fi
    done
}

add_clear_on_login() {
    cat >/etc/profile.d/clear_on_login.sh <<'EOF'
clear
EOF
    chmod 644 /etc/profile.d/clear_on_login.sh
    log_msg "Enabled auto terminal screen clear hook inside shell configurations."
}

add_alias_l() {
    cat >/etc/profile.d/alias_l.sh <<'EOF'
alias l='ls'
EOF
    chmod 644 /etc/profile.d/alias_l.sh
    if [ -f /etc/bash.bashrc ]; then
        grep -qxF "alias l='ls'" /etc/bash.bashrc || echo "alias l='ls'" >>/etc/bash.bashrc
    fi
    log_msg "System shortcut macro setup completed (l='ls')."
}

add_alias_cl() {
    cat >/etc/profile.d/alias_cl.sh <<'EOF'
alias cl='clear'
EOF
    chmod 644 /etc/profile.d/alias_cl.sh
    if [ -f /etc/bash.bashrc ]; then
        grep -qxF "alias cl='clear'" /etc/bash.bashrc || echo "alias cl='clear'" >>/etc/bash.bashrc
    fi
    log_msg "System shortcut macro setup completed (cl='clear')."
}

config() {
    banner
    sound_fix

    add_clear_on_login
    add_alias_l
    add_alias_cl

    run_silent "Upgrading base package configurations before styling engine setups" apt upgrade -y
    run_silent "Installing rendering UI engines, theme toolkits and dependency setups" apt install gtk2-engines-murrine gtk2-engines-pixbuf sassc optipng inkscape libglib2.0-dev-bin -y

    mv -vf /usr/share/backgrounds/xfce/xfce-verticals.png /usr/share/backgrounds/xfce/xfce-verticals-old.png >>"$LOG_FILE" 2>&1 || true

    temp_folder=$(mktemp -d -p "$HOME")
    {
        banner
        sleep 1
        cd "$temp_folder" || exit
    }

    echo -e "${R} [${W}-${R}]${C} Downloading Required Files..\n${W}"
    downloader "fonts.tar.gz" "https://github.com/MaheshTechnicals/Moded-Debian/releases/download/config/fonts.tar.gz"
    downloader "icons.tar.gz" "https://github.com/MaheshTechnicals/Moded-Debian/releases/download/config/icons.tar.gz"
    downloader "wallpaper.tar.gz" "https://github.com/MaheshTechnicals/Moded-Debian/releases/download/config/wallpaper.tar.gz"
    downloader "gtk-themes.tar.gz" "https://github.com/MaheshTechnicals/Moded-Debian/releases/download/config/gtk-themes.tar.gz"
    downloader "debian-settings.tar.gz" "https://github.com/MaheshTechnicals/Moded-Debian/releases/download/config/debian-settings.tar.gz"

    echo -e "${R} [${W}-${R}]${C} Unpacking Files..\n${W}"
    log_msg "Extracting runtime style sheets and configuration packages to core system assets."

    tar -xvzf fonts.tar.gz -C "/usr/local/share/fonts/" >>"$LOG_FILE" 2>&1
    tar -xvzf icons.tar.gz -C "/usr/share/icons/" >>"$LOG_FILE" 2>&1
    tar -xvzf wallpaper.tar.gz -C "/usr/share/backgrounds/xfce/" >>"$LOG_FILE" 2>&1
    tar -xvzf gtk-themes.tar.gz -C "/usr/share/themes/" >>"$LOG_FILE" 2>&1
    tar -xvzf debian-settings.tar.gz -C "/home/$username/" >>"$LOG_FILE" 2>&1

    rm -fr "$temp_folder"

    echo -e "${R} [${W}-${R}]${C} Purging Unnecessary Files..${W}"
    rem_theme
    rem_icon

    echo -e "${R} [${W}-${R}]${C} Rebuilding Font Cache..\n${W}"
    run_silent "Refreshing structural runtime OS font caches" fc-cache -fv

    echo -e "${R} [${W}-${R}]${C} Upgrading the System..\n${W}"
    run_silent "Updating system software indices" apt update
    run_silent "Executing ultimate package sync update adjustments" apt upgrade -y
    run_silent "Cleaning localized cache package archives" apt clean
    run_silent "Autoremoving orphan system dependencies" apt autoremove -y
}

# ─────────────────────────────────────────────
# 🛠️ Main Execution Flow
# ─────────────────────────────────────────────
check_root
fix_machineid
package
install_softwares
config
note
