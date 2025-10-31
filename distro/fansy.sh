#!/bin/bash
# 🌈 MaheshOS Fancy Terminal Auto-Installer (v5.0)
# Author: Mahesh Technicals | help@maheshtechnicals.com

# ────────────────────────────── COLORS ──────────────────────────────
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
MAGENTA="\033[1;35m"
CYAN="\033[1;36m"
RED="\033[1;31m"
BOLD="\033[1m"
RESET="\033[0m"

# ────────────────────────────── HEADER ──────────────────────────────
echo -e "\n${MAGENTA}══════════════════════════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}${CYAN}🚀  MaheshOS Fancy Terminal Auto-Installer (v5.0)${RESET}"
echo -e "${MAGENTA}══════════════════════════════════════════════════════════════════════════${RESET}\n"

sleep 1

# 🧱 Step 1: Update & install dependencies
echo -e "${YELLOW}📦 Step 1: Installing required packages...${RESET}"
sudo apt update -y >/dev/null 2>&1
sudo apt install -y zsh git ruby ruby-dev wget curl build-essential fonts-powerline tar >/dev/null 2>&1
echo -e "${GREEN}✅ Dependencies installed successfully!${RESET}\n"
sleep 0.5

# 🧹 Step 2: Clean old configs
echo -e "${YELLOW}🧹 Step 2: Cleaning old Zsh configurations...${RESET}"
for user_home in /root /home/*; do
  [ -d "$user_home" ] && rm -rf "$user_home/.oh-my-zsh" "$user_home/.p10k.zsh" \
    "$user_home/.zshrc" "$user_home/.zprofile" "$user_home/.zlogin" \
    "$user_home/.zshenv" "$user_home/.cache/starship" 2>/dev/null || true
done
echo -e "${GREEN}✅ Old configurations removed.${RESET}\n"
sleep 0.5

# 💎 Step 3: Install Oh My Zsh globally
echo -e "${YELLOW}💎 Step 3: Installing Oh My Zsh for all users...${RESET}"
for user_home in /root /home/*; do
  if [ -d "$user_home" ]; then
    git clone https://github.com/ohmyzsh/ohmyzsh.git "$user_home/.oh-my-zsh" --depth=1 >/dev/null 2>&1
    chown -R $(stat -c "%U:%G" "$user_home") "$user_home/.oh-my-zsh"
  fi
done
echo -e "${GREEN}✅ Oh My Zsh installed!${RESET}\n"
sleep 0.5

# 🎨 Step 4: Install Powerlevel10k Theme
echo -e "${YELLOW}🎨 Step 4: Installing Powerlevel10k Theme...${RESET}"
for user_home in /root /home/*; do
  if [ -d "$user_home" ]; then
    git clone https://github.com/romkatv/powerlevel10k.git \
      "$user_home/.oh-my-zsh/custom/themes/powerlevel10k" --depth=1 >/dev/null 2>&1
    chown -R $(stat -c "%U:%G" "$user_home") "$user_home/.oh-my-zsh"
  fi
done
echo -e "${GREEN}✅ Powerlevel10k installed successfully!${RESET}\n"
sleep 0.5

# 🔌 Step 5: Define plugins and base zshrc
ZSH_PLUGINS=(git z sudo extract history)
ZSH_PLUGIN_LINE=$(IFS=' '; echo "${ZSH_PLUGINS[*]}")

BASE_ZSHRC=$(cat <<EOF
export ZSH="\$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=($ZSH_PLUGIN_LINE)
source \$ZSH/oh-my-zsh.sh
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
eval "\$(starship init zsh)"
EOF
)

# 🧩 Step 6: Write ~/.zshrc for each user
echo -e "${YELLOW}🧩 Step 6: Writing Zsh config for all users...${RESET}"
for user_home in /root /home/*; do
  if [ -d "$user_home" ]; then
    echo "$BASE_ZSHRC" > "$user_home/.zshrc"
    chown $(stat -c "%U:%G" "$user_home") "$user_home/.zshrc"
  fi
done
echo -e "${GREEN}✅ Zsh configuration applied to all users.${RESET}\n"
sleep 0.5

# 🚀 Step 7: Install Starship prompt globally
echo -e "${YELLOW}🚀 Step 7: Installing Starship Prompt (system-wide)...${RESET}"
curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b /usr/local/bin >/dev/null 2>&1
if [ ! -f /usr/local/bin/starship ]; then
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b /usr/bin >/dev/null 2>&1
fi
chmod +x /usr/local/bin/starship /usr/bin/starship 2>/dev/null || true
ln -sf /usr/local/bin/starship /usr/bin/starship 2>/dev/null || true
echo -e "${GREEN}✅ Starship prompt installed globally!${RESET}\n"
sleep 0.5

# 🐚 Step 8: Set Zsh as default shell for all users
echo -e "${YELLOW}🐚 Step 8: Setting Zsh as default shell for all users...${RESET}"
ZSH_PATH=$(which zsh)
for user_name in $(awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd) root; do
  usermod -s "$ZSH_PATH" "$user_name" >/dev/null 2>&1 || true
done
echo -e "${GREEN}✅ Default shell set to Zsh for all users.${RESET}\n"
sleep 0.5

# 🧩 Step 9: Skip new-user wizard
echo -e "${YELLOW}🧩 Step 9: Skipping Zsh new-user prompts...${RESET}"
for user_home in /root /home/*; do
  [ -d "$user_home" ] && touch "$user_home/.zshrc" "$user_home/.zshenv" "$user_home/.zprofile" "$user_home/.zlogin"
done
echo -e "${GREEN}✅ Wizard skipped successfully.${RESET}\n"

# 🎉 Step 10: Done!
echo -e "\n${MAGENTA}══════════════════════════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}${GREEN}✅ MaheshOS Terminal Setup Complete for ALL Users (root included)!${RESET}"
echo -e "${CYAN}💎 Includes: Oh My Zsh + Powerlevel10k + Starship (No Banner)${RESET}"
echo -e "${YELLOW}✨ Run ${BOLD}zsh${RESET}${YELLOW} or restart terminal to activate.${RESET}"
echo -e "${MAGENTA}══════════════════════════════════════════════════════════════════════════${RESET}\n"
