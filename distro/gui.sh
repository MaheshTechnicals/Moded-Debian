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

# run_silent: runs a command silently, logging stdout/stderr
# Only use for NON-interactive commands (apt-get, fc-cache, etc.)
# Do NOT use for: interactive scripts, bash sub-scripts, npm n, downloader()
run_silent() {
    local task_name="$1"
    shift
    log_msg "STARTING: $task_name"
    echo -e "${C}Running: ${Y}$task_name...${W}"

    if "$@" >>"$LOG_FILE" 2>&1; then
        log_msg "SUCCESS: $task_name"
        echo -e "${G}✓ $task_name completed successfully.${W}"
    else
        log_msg "ERROR: $task_name failed with exit code $?"
        echo -e "${R}✗ ERROR in: $task_name (Check $LOG_FILE for details)${W}"
        sleep 2
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
# FIX: called directly — never via run_silent (it's a bash function,
#      not an external command; run_silent cannot call bash functions)
# ─────────────────────────────────────────────
downloader() {
    local dl_path="$1"
    local dl_url="$2"
    [[ -e "$dl_path" ]] && rm -rf "$dl_path"
    log_msg "Downloading $dl_url → $dl_path"
    echo -e "${C}Downloading: ${Y}$(basename "$dl_path")...${W}"
    curl --progress-bar --insecure --fail \
        --retry-connrefused --retry 3 --retry-delay 2 \
        --location --output "$dl_path" "$dl_url"
    if [[ $? -eq 0 ]]; then
        echo -e "${G}✓ Downloaded: $(basename "$dl_path")${W}"
        log_msg "SUCCESS: Downloaded $(basename "$dl_path")"
    else
        echo -e "${R}✗ Failed to download: $(basename "$dl_path")${W}"
        log_msg "ERROR: Failed to download $dl_url"
    fi
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
        dbus-uuidgen --ensure=/etc/machine-id >>"$LOG_FILE" 2>&1
        dbus-uuidgen --ensure >>"$LOG_FILE" 2>&1
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
    echo -e "${C}    ____  __________  _______    _   __"
    echo -e "${Y}   / __ \/ ____/ __ )/  _/   |  / | / /"
    echo -e "${G}  / / / / __/ / __  |/ // /| | /  |/ / "
    echo -e "${C} / /_/ / /___/ /_/ // // ___ |/ /|  /  "
    echo -e "${Y}/_____/_____/_____/___/_/  |_/_/ |_/   "
    echo -e "${G}💻 Debian KDE Plasma Setup Script by Mahesh Technicals\n${W}"
}

note() {
    banner
    echo -e " ${G} [-] Successfully Installed !\n${W}"
    echo -e " ${Y} [*] You can check all execution logs at: $LOG_FILE\n${W}"
    sleep 1
    cat <<- EOF
		 ${G}[-] Type ${C}vncstart${G} to start KDE Plasma VNC session.
		 ${G}[-] Type ${C}vncstop${G} to stop KDE Plasma VNC session.

		 ${C}Install VNC VIEWER Apk on your Device.

		 ${C}Open VNC VIEWER & Click on + Button.

		 ${C}Enter the Address localhost:1 & Name anything you like.

		 ${C}Set the Picture Quality to High for the best experience.

		 ${C}Click on Connect & Input the Password.

		 ${C}Enjoy KDE Plasma Desktop on Android! 🚀${W}
	EOF
    log_msg "=== Setup Completed Successfully ==="
}

package() {
    banner
    echo -e "${R} [${W}-${R}]${C} Checking required packages...${W}"

    run_silent "Updating apt repositories" apt-get update -y
    run_silent "Installing udisks2 package" apt-get install udisks2 -y

    rm -f /var/lib/dpkg/info/udisks2.postinst
    echo "" >/var/lib/dpkg/info/udisks2.postinst

    run_silent "Configuring DPKG" dpkg --configure -a
    run_silent "Holding udisks2 package changes" apt-mark hold udisks2

    # ── KDE Plasma desktop packages ──────────────────────────────────────────
    # plasma-desktop   : core Plasma shell + panel + applets
    # kwin-x11         : KDE window manager for X11 (required for VNC)
    # konsole          : KDE terminal emulator
    # dolphin          : KDE file manager
    # plasma-nm        : network manager plasma applet
    # plasma-pa        : PulseAudio plasma applet (volume control)
    # breeze           : Breeze window decoration & widget style
    # breeze-icon-theme: Breeze icon set
    # kde-config-gtk-style : GTK app styling inside KDE
    # ark              : KDE archive manager
    # kate             : KDE text editor
    # gwenview         : KDE image viewer
    # spectacle        : KDE screenshot tool
    # kscreen          : KDE display configuration
    # plasma-widgets-addons : extra Plasma widgets
    # ─────────────────────────────────────────────────────────────────────────
    packs=(sudo gnupg2 curl nano git xz-utils at-spi2-core
           plasma-desktop kwin-x11 konsole dolphin
           plasma-nm plasma-pa
           breeze breeze-icon-theme kde-config-gtk-style
           ark kate gwenview spectacle kscreen plasma-widgets-addons
           librsvg2-common menu inetutils-tools dialog
           tigervnc-standalone-server tigervnc-common tigervnc-tools dbus-x11
           fonts-beng fonts-beng-extra
           gtk2-engines-murrine gtk2-engines-pixbuf
           apt-transport-https gh)

    for hulu in "${packs[@]}"; do
        if ! dpkg -s "$hulu" &>/dev/null; then
            run_silent "Installing: $hulu" apt-get install "$hulu" -y --no-install-recommends
        else
            echo -e "${G}✓ $hulu already installed${W}"
        fi
    done

    run_silent "System repository update" apt-get update -y
    run_silent "System core package upgrade" apt-get upgrade -y
}

install_apt() {
    for pkg in "$@"; do
        if dpkg -s "$pkg" &>/dev/null; then
            echo -e "${Y}${pkg} is already Installed!${W}"
            log_msg "Apt Installer: $pkg is already installed."
        else
            run_silent "Installing: $pkg" apt-get install -y "${pkg}"
        fi
    done
}

install_vscode() {
    if [[ $(command -v code) ]]; then
        echo -e "${Y}VSCode is already Installed!${W}"
        return
    fi
    echo -e "${C}Running: ${Y}Installing VSCode...${W}"
    log_msg "STARTING: Installing VSCode"
    run_silent "Installing binutils (VSCode requirement)" apt-get install -y binutils
    downloader "/tmp/code.sh" "https://raw.githubusercontent.com/MaheshTechnicals/Kali-Nethunter/refs/heads/main/vscode"
    chmod +x /tmp/code.sh
    echo -e "${C}Running VSCode installer (this may take a while)...${W}"
    echo "1" | bash /tmp/code.sh
    log_msg "VSCode installation completed."
    echo -e "${G}✓ VSCode installation finished.${W}"
}

install_sublime() {
    if [[ $(command -v subl) ]]; then
        echo -e "${Y}Sublime is already Installed!${W}"
        return
    fi
    run_silent "Installing Sublime dependencies" apt-get install -y gnupg2 software-properties-common
    echo "deb https://download.sublimetext.com/ apt/stable/" | tee /etc/apt/sources.list.d/sublime-text.list >>"$LOG_FILE" 2>&1
    curl -fsSL https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor >/etc/apt/trusted.gpg.d/sublime.gpg 2>>"$LOG_FILE"
    run_silent "Updating repos for Sublime" apt-get update -y
    run_silent "Installing Sublime Text" apt-get install -y sublime-text
}

install_cursor() {
    if [[ $(command -v cursor) ]]; then
        echo -e "${Y}Cursor is already Installed!${W}"
        return
    fi
    echo -e "${C}Running: ${Y}Installing Cursor AI Editor...${W}"
    log_msg "STARTING: Installing Cursor"
    downloader "/tmp/cursor.sh" "https://raw.githubusercontent.com/MaheshTechnicals/cursor-free-vip-termux/refs/heads/main/cursor.sh"
    chmod +x /tmp/cursor.sh
    run_silent "Installing expect" apt-get install -y expect

    log_msg "Launching Cursor installer via expect"
    expect << 'EOF'
set timeout -1
spawn sudo bash /tmp/cursor.sh -i
expect "Do you want to return to the main menu? (y/n):"
send "\r"
expect eof
EOF
    log_msg "Cursor installation completed."
    echo -e "${G}✓ Cursor installation finished.${W}"
}

install_chromium() {
    if dpkg -s chromium &>/dev/null; then
        echo -e "${Y}Chromium is already Installed!${W}"
        return
    fi
    run_silent "Updating repos for Chromium" apt-get update -y
    run_silent "Installing Chromium" apt-get install -y chromium
    if [ -f /usr/share/applications/chromium.desktop ]; then
        sed -i 's/chromium %U/chromium --no-sandbox %U/g' /usr/share/applications/chromium.desktop
        log_msg "Applied --no-sandbox flag to Chromium desktop entry."
    fi
}

install_firefox() {
    if [[ $(command -v firefox) ]]; then
        echo -e "${Y}Firefox is already Installed!${W}"
        return
    fi
    echo -e "${C}Running: ${Y}Installing Firefox...${W}"
    log_msg "STARTING: Installing Firefox"
    downloader "/tmp/firefox.sh" "https://raw.githubusercontent.com/MaheshTechnicals/Moded-Debian/refs/heads/kde-plasma/distro/firefox.sh"
    chmod +x /tmp/firefox.sh
    echo -e "${C}Running Firefox installer (this may take a while)...${W}"
    bash /tmp/firefox.sh
    log_msg "Firefox installation completed."
    echo -e "${G}✓ Firefox installation finished.${W}"
}

install_brave() {
    if [[ $(command -v brave-browser) ]]; then
        echo -e "${Y}Brave is already Installed!${W}"
    else
        echo -e "${C}Running: ${Y}Installing Brave...${W}"
        log_msg "STARTING: Installing Brave"
        downloader "/tmp/brave.sh" "https://raw.githubusercontent.com/MaheshTechnicals/Moded-Debian/refs/heads/kde-plasma/distro/brave.sh"
        chmod +x /tmp/brave.sh
        echo -e "${C}Running Brave installer (this may take a while)...${W}"
        bash /tmp/brave.sh
        log_msg "Brave installation completed."
        echo -e "${G}✓ Brave installation finished.${W}"
    fi

    # Refresh desktop database so KDE Plasma picks up Brave
    command -v update-desktop-database >/dev/null 2>&1 &&
        update-desktop-database /usr/share/applications >>"$LOG_FILE" 2>&1 &&
        log_msg "Refreshed desktop database."
}

set_default_browser() {
    echo -e "\n${R} [${W}-${R}]${C} Setting Firefox as default browser...${W}"
    log_msg "Setting Firefox as system default browser"

    if command -v xdg-settings >/dev/null 2>&1 && [ -n "${DISPLAY:-}" ]; then
        xdg-settings set default-web-browser firefox.desktop >>"$LOG_FILE" 2>&1 &&
            log_msg "xdg-settings: Firefox set as default."
    fi

    if command -v update-alternatives >/dev/null 2>&1; then
        update-alternatives --set x-www-browser "$(command -v firefox)" >>"$LOG_FILE" 2>&1 &&
            log_msg "update-alternatives: Firefox set as default."
    fi

    cat >/etc/profile.d/default_browser.sh <<'EOF'
export BROWSER=firefox
EOF
    chmod 644 /etc/profile.d/default_browser.sh

    for homedir in /root "/home/$username"; do
        [ -d "$homedir" ] || continue
        mkdir -p "$homedir/.config"

        # Standard XDG mime associations (works for KDE, GTK, CLI)
        cat >"$homedir/.config/mimeapps.list" <<'EOF'
[Default Applications]
text/html=firefox.desktop
x-scheme-handler/http=firefox.desktop
x-scheme-handler/https=firefox.desktop
x-scheme-handler/about=firefox.desktop
x-scheme-handler/unknown=firefox.desktop
EOF
        log_msg "Set mimeapps.list for $homedir"

        # KDE Plasma: register default browser in kdeglobals
        if [ -f "$homedir/.config/kdeglobals" ]; then
            if grep -q "^BrowserApplication=" "$homedir/.config/kdeglobals"; then
                sed -i 's/^BrowserApplication=.*/BrowserApplication=firefox.desktop/' \
                    "$homedir/.config/kdeglobals"
            else
                sed -i '/^\[General\]/a BrowserApplication=firefox.desktop' \
                    "$homedir/.config/kdeglobals"
            fi
        else
            printf '[General]\nBrowserApplication=firefox.desktop\n' \
                >"$homedir/.config/kdeglobals"
        fi
        log_msg "Set KDE Plasma default browser in kdeglobals for $homedir"
    done
    echo -e "${G}✓ Firefox set as default browser.${W}"
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
    banner
    sleep 1

    install_node_latest() {
        run_silent "Updating repos for Node.js" apt-get update -y
        run_silent "Installing Node.js and NPM" apt-get install -y nodejs npm
        echo -e "${C}Installing n (Node version manager)...${W}"
        npm install -g n 2>&1 | tee -a "$LOG_FILE"
        echo -e "${C}Switching to latest Node.js release (this may take a while)...${W}"
        n latest 2>&1 | tee -a "$LOG_FILE"
        echo -e "${C}Upgrading npm to latest...${W}"
        npm install -g npm@latest 2>&1 | tee -a "$LOG_FILE"
        echo -e "${G}✓ Node.js setup complete. Version: $(node -v 2>/dev/null)${W}"
        log_msg "Node.js installed. Version: $(node -v 2>/dev/null)"
    }

    install_python_latest() {
        run_silent "Updating repos for Python" apt-get update -y
        run_silent "Installing Python3, pip and venv" apt-get install -y python3 python3-pip python3-venv
        echo -e "${G}✓ Python setup complete. Version: $(python3 --version 2>/dev/null)${W}"
        log_msg "Python installed. Version: $(python3 --version 2>/dev/null)"
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
        log_msg "User skipped language installation."
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
        cat <<- EOF
			${Y} ---${G} Select IDE ${Y}---

			${C} [${W}1${C}] Cursor AI Editor (Recommended)
			${C} [${W}2${C}] Visual Studio Code
			${C} [${W}3${C}] All (Cursor + VSCode)
			${C} [${W}4${C}] Skip! (Default)

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
            log_msg "User skipped IDE installation."
            sleep 1
        fi
    }

    banner
    cat <<- EOF
		${Y} ---${G} Media Player ${Y}---

		${C} [${W}1${C}] MPV Media Player (Recommended)
		${C} [${W}2${C}] VLC Media Player
		${C} [${W}3${C}] All (MPV + VLC)
		${C} [${W}4${C}] Skip! (Default)

	EOF
    read -n1 -p "${R} [${G}~${R}]${Y} Select an Option: ${G}" PLAYER_OPTION
    banner
    sleep 1

    if [[ ${PLAYER_OPTION} == 1 ]]; then
        install_apt "mpv"
    elif [[ ${PLAYER_OPTION} == 2 ]]; then
        install_apt "vlc"
    elif [[ ${PLAYER_OPTION} == 3 ]]; then
        install_apt "mpv" "vlc"
    else
        echo -e "${Y} [!] Skipping Media Player Installation\n"
        log_msg "User skipped media player installation."
        sleep 1
    fi

    install_languages
}

sound_fix() {
    if ! grep -q "bash ~/.sound" "$TERMUX_BIN/debian" 2>/dev/null; then
        echo "$(echo "bash ~/.sound" | cat - "$TERMUX_BIN/debian")" >"$TERMUX_BIN/debian"
        chmod +x "$TERMUX_BIN/debian"
        log_msg "Sound fix applied to Debian launcher."
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
            log_msg "Removed theme: $rmi"
        fi
    done
}

rem_icon() {
    icons=(LoginIcons)
    for rmf in "${icons[@]}"; do
        if [ -d "/usr/share/icons/$rmf" ]; then
            rm -rf "/usr/share/icons/$rmf"
            log_msg "Removed icon set: $rmf"
        fi
    done
}

add_clear_on_login() {
    cat >/etc/profile.d/clear_on_login.sh <<'EOF'
clear
EOF
    chmod 644 /etc/profile.d/clear_on_login.sh
    log_msg "Auto-clear on login enabled."
}

add_alias_l() {
    cat >/etc/profile.d/alias_l.sh <<'EOF'
alias l='ls'
EOF
    chmod 644 /etc/profile.d/alias_l.sh
    if [ -f /etc/bash.bashrc ]; then
        grep -qxF "alias l='ls'" /etc/bash.bashrc || echo "alias l='ls'" >>/etc/bash.bashrc
    fi
    log_msg "Alias l=ls set."
}

add_alias_cl() {
    cat >/etc/profile.d/alias_cl.sh <<'EOF'
alias cl='clear'
EOF
    chmod 644 /etc/profile.d/alias_cl.sh
    if [ -f /etc/bash.bashrc ]; then
        grep -qxF "alias cl='clear'" /etc/bash.bashrc || echo "alias cl='clear'" >>/etc/bash.bashrc
    fi
    log_msg "Alias cl=clear set."
}

# ─────────────────────────────────────────────
# ZSH SETUP (integrated into gui.sh)
# Installs Zsh + fast config for both root and
# the sudo user. No Oh My Zsh — faster startup.
# ─────────────────────────────────────────────
setup_zsh() {
    banner
    echo -e "${C}[*] Setting up Zsh (fast mode, no Oh My Zsh)...${W}"
    log_msg "STARTING: Zsh fast setup"

    export DEBIAN_FRONTEND=noninteractive

    run_silent "Installing zsh + plugins" \
        apt-get install -y zsh zsh-autosuggestions zsh-syntax-highlighting git curl nano

    command -v zsh &>/dev/null || { echo -e "${R}✗ Zsh install failed${W}"; return 1; }

    _remove_omz() {
        local home_dir="$1"
        if [ -d "$home_dir/.oh-my-zsh" ]; then
            echo -e "${Y}[*] Removing Oh My Zsh (slow on proot)...${W}"
            rm -rf "$home_dir/.oh-my-zsh"
            log_msg "Removed Oh My Zsh from $home_dir"
            echo -e "${G}✓ Oh My Zsh removed${W}"
        fi
    }

    _write_zshrc() {
        local zshrc="$1"
        local owner="$2"

        [ -f "$zshrc" ] && cp "$zshrc" "${zshrc}.bak"

        cat > "$zshrc" << 'ZSHRC'
# ─────────────────────────────────────────────────────────────────
#  .zshrc — Moded-Debian (KDE Plasma) by Mahesh Technicals
#  Optimized for proot/Android — target < 200ms startup
# ─────────────────────────────────────────────────────────────────

# == PROMPT (git branch via built-in vcs_info, zero deps) =========
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' (%b)'
setopt PROMPT_SUBST
PROMPT='%F{cyan}%n%f%F{white}@%f%F{green}%m%f %F{yellow}%~%f%F{magenta}${vcs_info_msg_0_}%f %F{cyan}➜%f  '

# == COMPLETION (cached — rebuilds only once per day) =============
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi
skip_global_compinit=1
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# == HISTORY ======================================================
HISTFILE=~/.zsh_history
HISTSIZE=2000
SAVEHIST=2000
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY

# == OPTIONS ======================================================
setopt AUTO_CD CORRECT NO_BEEP

# == PLUGINS — lazy loaded after first prompt =====================
_load_plugins() {
    [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
        source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
        source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
    ZSH_AUTOSUGGEST_USE_ASYNC=true
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
    precmd_functions=("${(@)precmd_functions:#_load_plugins}")
}
precmd_functions+=(_load_plugins)

# == KEY BINDINGS =================================================
bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
bindkey '^[[3~' delete-char

# == ALIASES ======================================================
alias l='ls --color=auto'
alias cl='clear'
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias ls='ls --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias vs='vncstart'
alias vx='vncstop'
alias plasma-restart='kquitapp5 plasmashell && kstart5 plasmashell &'
alias update='sudo apt-get update && sudo apt-get upgrade -y'
alias install='sudo apt-get install -y'
alias remove='sudo apt-get remove -y'
alias purge='sudo apt-get purge -y'
alias autoremove='sudo apt-get autoremove -y'
alias search='apt-cache search'
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'
alias gb='git branch'
alias myip='curl -s ifconfig.me && echo'
alias ports='ss -tulpn'
alias meminfo='free -h'
alias diskinfo='df -h'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias zshconfig='nano ~/.zshrc'
alias reload='source ~/.zshrc && echo "✓ .zshrc reloaded"'
# ─────────────────────────────────────────────────────────────────
ZSHRC

        [[ "$owner" != "root" ]] && chown "$owner:$owner" "$zshrc"

        if [[ "$owner" == "root" ]]; then
            zsh -c "autoload -Uz compinit && compinit" >>"$LOG_FILE" 2>&1 || true
        else
            sudo -u "$owner" zsh -c "autoload -Uz compinit && compinit" >>"$LOG_FILE" 2>&1 || true
        fi
        log_msg "SUCCESS: .zshrc written for $owner"
    }

    _set_zsh_default() {
        local target_user="$1"
        local zsh_path
        zsh_path=$(which zsh)
        if usermod -s "$zsh_path" "$target_user" >>"$LOG_FILE" 2>&1; then
            echo -e "${G}✓ Default shell -> Zsh ($target_user)${W}"
        else
            sed -i "s|^\($target_user:.*:\)/.*$|\1$zsh_path|" /etc/passwd
            echo -e "${Y}[!] Set via /etc/passwd for $target_user${W}"
        fi
        log_msg "Default shell set to zsh for $target_user"
    }

    # ── Root ─────────────────────────────────────────────────────
    _remove_omz "/root"
    _write_zshrc "/root/.zshrc" "root"
    _set_zsh_default "root"

    # ── Normal user ──────────────────────────────────────────────
    if [[ -n "$username" ]] && [[ "$username" != "root" ]]; then
        _remove_omz "/home/$username"
        _write_zshrc "/home/$username/.zshrc" "$username"
        _set_zsh_default "$username"
    fi

    # ── System-wide shortcuts ─────────────────────────────────────
    cat >/etc/profile.d/mahesh_shortcuts.sh <<'EOF'
alias l='ls --color=auto'
alias cl='clear'
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias ..='cd ..'
alias vs='vncstart'
alias vx='vncstop'
alias plasma-restart='kquitapp5 plasmashell && kstart5 plasmashell &'
alias update='sudo apt-get update && sudo apt-get upgrade -y'
alias install='sudo apt-get install -y'
EOF
    chmod 644 /etc/profile.d/mahesh_shortcuts.sh

    echo -e "${G}✓ Zsh fast setup complete.${W}"
    log_msg "SUCCESS: Zsh fast setup finished"
}

# ─────────────────────────────────────────────
# KDE PLASMA CONFIGURATION
# Applies Breeze Dark theme, disables compositing
# (not supported well in proot/VNC), sets default
# terminal to Konsole, and sets wallpaper path.
# ─────────────────────────────────────────────
setup_kde_config() {
    banner
    echo -e "${C}[*] Applying KDE Plasma configuration...${W}"
    log_msg "STARTING: KDE Plasma configuration"

    for user_home in "/root" "/home/$username"; do
        [ -d "$user_home" ] || continue
        local cfg="$user_home/.config"
        mkdir -p "$cfg"

        # Breeze Dark look-and-feel + Firefox as default browser
        cat > "$cfg/kdeglobals" <<'EOF'
[General]
ColorScheme=BreezeDark
BrowserApplication=firefox.desktop
TerminalApplication=konsole

[KDE]
LookAndFeelPackage=org.kde.breezedark.desktop
widgetStyle=Breeze
SingleClick=false

[Icons]
Theme=breeze-dark
EOF

        # Disable compositing — proot/VNC does not accelerate OpenGL well
        # This prevents a black/unresponsive desktop on first launch
        cat > "$cfg/kwinrc" <<'EOF'
[Compositing]
Backend=XRender
Enabled=false

[Windows]
FocusPolicy=ClickToFocus

[Desktops]
Number=2
Rows=1
EOF

        # Konsole default profile — dark color scheme
        mkdir -p "$user_home/.local/share/konsole"
        cat > "$user_home/.local/share/konsole/Default.profile" <<'EOF'
[Appearance]
ColorScheme=Breeze
Font=Monospace,11,-1,5,50,0,0,0,0,0

[General]
Name=Default
Parent=FALLBACK/
TerminalColumns=120
TerminalRows=35

[Scrolling]
HistorySize=10000
ScrollBarPosition=2
EOF

        # Set KDE default wallpaper (picks the first image in /usr/share/wallpapers/)
        mkdir -p "$cfg/plasma-org.kde.plasma.desktop-appletsrc.d"
        cat > "$cfg/plasma-org.kde.plasma.desktop-appletsrc" <<'EOF'
[Containments][1][Wallpaper][org.kde.image][General]
FillMode=2
Image=file:///usr/share/wallpapers/
EOF

        # Taskbar / panel config — single bottom panel
        cat > "$cfg/plasmashellrc" <<'EOF'
[PlasmaViews][Panel 2][Defaults]
thickness=44

[PlasmaViews][Panel 2][Horizontal1920]
thickness=44
EOF

        [[ "$user_home" != "/root" ]] && \
            chown -R "$username:$username" "$user_home/.config" \
                                          "$user_home/.local" 2>/dev/null || true
        log_msg "KDE Plasma config applied for $user_home"
    done

    echo -e "${G}✓ KDE Plasma configuration applied.${W}"
    log_msg "SUCCESS: KDE Plasma configuration finished"
}

config() {
    banner
    sound_fix

    add_clear_on_login
    add_alias_l
    add_alias_cl
    setup_zsh

    run_silent "Upgrading base packages" apt-get upgrade -y
    # GTK theme engines + Breeze-GTK so GTK apps look native inside KDE Plasma
    run_silent "Installing UI theme toolkits" apt-get install -y \
        gtk2-engines-murrine gtk2-engines-pixbuf sassc optipng inkscape \
        libglib2.0-dev-bin breeze-gtk-theme kde-config-gtk-style

    # KDE Plasma wallpapers live in /usr/share/wallpapers/
    mkdir -p /usr/share/wallpapers/

    # FIX: cd was inside a subshell { } so the parent shell's working directory
    # never changed — all downloader calls wrote files to $HOME not $temp_folder
    # Fixed by cd-ing in the parent shell directly before downloading
    temp_folder=$(mktemp -d -p "$HOME")
    banner
    sleep 1
    cd "$temp_folder" || exit 1

    echo -e "${R} [${W}-${R}]${C} Downloading Required Files..\n${W}"
    downloader "fonts.tar.gz"        "https://github.com/MaheshTechnicals/Moded-Debian/releases/download/config/fonts.tar.gz"
    downloader "icons.tar.gz"        "https://github.com/MaheshTechnicals/Moded-Debian/releases/download/config/icons.tar.gz"
    downloader "wallpaper.tar.gz"    "https://github.com/MaheshTechnicals/Moded-Debian/releases/download/config/wallpaper.tar.gz"
    downloader "gtk-themes.tar.gz"   "https://github.com/MaheshTechnicals/Moded-Debian/releases/download/config/gtk-themes.tar.gz"
    downloader "kde-settings.tar.gz" "https://github.com/MaheshTechnicals/Moded-Debian/releases/download/config/kde-settings.tar.gz"

    echo -e "${R} [${W}-${R}]${C} Unpacking Files..\n${W}"
    log_msg "Extracting config assets to system directories."

    tar -xvzf fonts.tar.gz        -C "/usr/local/share/fonts/"   >>"$LOG_FILE" 2>&1
    tar -xvzf icons.tar.gz        -C "/usr/share/icons/"          >>"$LOG_FILE" 2>&1
    tar -xvzf wallpaper.tar.gz    -C "/usr/share/wallpapers/"     >>"$LOG_FILE" 2>&1
    tar -xvzf gtk-themes.tar.gz   -C "/usr/share/themes/"         >>"$LOG_FILE" 2>&1
    tar -xvzf kde-settings.tar.gz -C "/home/$username/"            >>"$LOG_FILE" 2>&1

    # Return to home before removing temp folder
    cd "$HOME" || true
    rm -fr "$temp_folder"

    echo -e "${R} [${W}-${R}]${C} Purging Unnecessary Files..${W}"
    rem_theme
    rem_icon

    echo -e "${R} [${W}-${R}]${C} Rebuilding Font Cache..\n${W}"
    run_silent "Rebuilding font cache" fc-cache -fv

    # Apply KDE Plasma settings (theme, wallpaper, compositing, Konsole profile)
    setup_kde_config

    echo -e "${R} [${W}-${R}]${C} Upgrading the System..\n${W}"
    run_silent "Final system update" apt-get update -y
    run_silent "Final system upgrade" apt-get upgrade -y
    run_silent "Cleaning package cache" apt-get clean
    run_silent "Removing orphan packages" apt-get autoremove -y
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
