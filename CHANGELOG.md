# 📘 Changelog
All notable changes to this project will be documented in this file.  
This project follows [Semantic Versioning](https://semver.org/) and the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.

---

## [v1.3.0] - 2026-06-04

### 🚀 Major Change — KDE Plasma Desktop Migration

This release replaces the **XFCE4** desktop environment with **KDE Plasma 5**.  
All existing features (browsers, IDEs, media players, Zsh, VNC, sound, etc.) are preserved.

### ✨ Added
- **distro/gui.sh**: Added `setup_kde_config()` — programmatically configures KDE Plasma on first run:
  - Applies **Breeze Dark** look-and-feel, color scheme, and icon theme via `~/.config/kdeglobals`.
  - Disables KWin compositing (`~/.config/kwinrc`) — OpenGL/XRender compositing is unreliable in proot/VNC environments and causes a black or unresponsive desktop.
  - Creates a default **Konsole** terminal profile (`~/.local/share/konsole/Default.profile`) with dark color scheme and 120-column width.
  - Writes a basic `plasmashellrc` for the bottom taskbar panel.
  - Config is applied for both root and the sudo user.
- **distro/gui.sh**: Added `breeze-gtk-theme` and `kde-config-gtk-style` to UI toolkit install so GTK2/GTK3 apps render with the Breeze look inside KDE Plasma.
- **distro/gui.sh**: Added `plasma-restart` alias in Zsh `.zshrc` and system-wide `/etc/profile.d/mahesh_shortcuts.sh`:
  - `plasma-restart` → `kquitapp5 plasmashell && kstart5 plasmashell &`
- **distro/gui.sh**: `set_default_browser()` now sets Firefox as the default browser in **KDE Plasma's `kdeglobals`** (`BrowserApplication=firefox.desktop`) in addition to xdg-settings, update-alternatives and mimeapps.list.
- **README.md**: Added `plasma-restart` usage note, KDE troubleshooting entries, and updated Technical Info table.

### 🔄 Changed
- **distro/vncstart**: Changed `xstartup` from `/usr/bin/xfce4-session` to `/usr/bin/startplasma-x11`. Added `XDG_SESSION_TYPE=x11` and `QT_QPA_PLATFORMTHEME=kde` exports so KDE Plasma launches correctly on X11/VNC.
- **distro/gui.sh** `package()`: Replaced XFCE4 packages with KDE Plasma packages:
  - **Removed:** `xfce4`, `xfce4-goodies`, `xfce4-terminal`, `exo-utils`
  - **Added:** `plasma-desktop`, `kwin-x11`, `konsole`, `dolphin`, `plasma-nm`, `plasma-pa`, `breeze`, `breeze-icon-theme`, `kde-config-gtk-style`, `ark`, `kate`, `gwenview`, `spectacle`, `kscreen`, `plasma-widgets-addons`
- **distro/gui.sh** `config()`: Wallpaper extraction path changed from `/usr/share/backgrounds/xfce/` → `/usr/share/wallpapers/` (KDE Plasma standard location). Removed the `xfce-verticals.png` rename step.
- **distro/gui.sh** `config()`: `debian-settings.tar.gz` renamed to `kde-settings.tar.gz` in both the download URL and tar extraction step. **⚠ Action required:** upload a `kde-settings.tar.gz` release asset to your GitHub repo containing KDE-compatible home-directory config files (e.g. `.config/`, `.local/share/konsole/`).
- **distro/gui.sh** `install_brave()`: Removed XFCE4-specific `/usr/share/xfce4/helpers/brave-browser.desktop` registration. Brave is now registered via the standard desktop database (`update-desktop-database`), which KDE Plasma reads natively.
- **distro/gui.sh** `set_default_browser()`: Removed XFCE4-specific `~/.config/xfce4/helpers.rc` `WebBrowser=` entries. Default browser is now set via xdg, mimeapps.list, and kdeglobals only.
- **distro/gui.sh** `setup_zsh()` `.zshrc`: Added `plasma-restart` alias for quick Plasma shell recovery.
- **README.md**: Updated desktop environment from XFCE4 to KDE Plasma 5 throughout. Minimum storage updated from 4 GB → 6 GB (KDE Plasma has a larger footprint than XFCE4). Added KDE-specific troubleshooting entries.
- **CHANGELOG.md**: Added this entry.

---

## [v1.2.0] - 2026-06-04

### 🐛 Fixed
- **setup.sh**: Updated rootfs path for proot-distro v5.x (`containers/debian/rootfs`).  
  Added `get_debian_dir()` helper with automatic legacy path fallback so the script works on both proot-distro v4.x and v5.x without changes.
- **setup.sh**: Fixed incorrect `exit 1` on success — changed to `exit 0`.
- **setup.sh**: Replaced `exit 0` inside `distro()` with `return 0` so the function no longer terminates the whole script on an already-installed distro.
- **distro/vncstop**: Fixed hardcoded `/username/.vnc/` path — replaced with `$HOME/.vnc/` so PID files are actually cleaned up.
- **distro/user.sh**: Fixed wrong project folder name `modded-ubuntu` → `Moded-Debian` in local `gui.sh` path lookup.
- **distro/user.sh**: Uncommented and fixed `chmod +x` on the Debian launcher — it was commented out, causing "Permission denied" on first run.
- **distro/user.sh**: Replaced all hardcoded `/data/data/com.termux/files/usr/bin` paths with `$TERMUX_BIN` variable for portability.
- **distro/user.sh**: Renamed internal `sudo()` function to `sudo_setup()` — the old name shadowed the system `sudo` command.
- **distro/gui.sh**: Fixed `sound_fix()` — added idempotency guard so `bash ~/.sound` is only prepended once to the Debian launcher. Previously it would duplicate the line on every re-run of `gui.sh`, corrupting the launcher.
- **distro/gui.sh**: Fixed `sound_fix()` — added `grep` guards before appending `DISPLAY` and `PULSE_SERVER` to `/etc/profile` so they are never written twice.
- **distro/gui.sh**: Fixed `sound_fix()` — replaced hardcoded Termux path with `$TERMUX_BIN` variable.
- **distro/gui.sh**: Fixed `install_firefox()` and `install_brave()` — removed unnecessary `sudo bash`; script already runs as root (enforced by `check_root()`). Using `sudo` inside proot when sudo is not yet configured can cause hangs.
- **distro/gui.sh**: Fixed `package()` — replaced `type -p` with `dpkg -s` for package presence checks. `type -p` only finds executables in `$PATH` and silently misses non-binary packages such as `xfce4`, `dbus-x11`, `fonts-beng`, `apt-transport-https`, causing them to be reinstalled on every run.
- **distro/gui.sh**: Fixed `install_apt()` — same `type -p` → `dpkg -s` fix applied for media player installs.
- **distro/gui.sh**: Fixed `rem_icon()` — replaced `type -p` guard (checks executables) with `[ -d ... ]` directory check for icon folders.
- **distro/gui.sh**: Fixed `install_chromium()` — removed EOL Debian Buster repository and 5 `apt-key adv` calls. Chromium is now installed directly from Debian Bookworm/Trixie main repos.
- **distro/gui.sh**: Removed `ubuntu-mono-light` from `rem_icon()` — it is an Ubuntu-specific icon theme that does not exist on Debian.
- **distro/gui.sh**: Renamed `ubuntu-settings.tar.gz` → `debian-settings.tar.gz` in download URL and tar extraction, matching the updated GitHub release asset.
- **distro/gui.sh**: Added `$username` safety fallback — if no sudo group user is found at startup (e.g. `gui.sh` run before `user.sh`), falls back to the first entry in `/home/`.
- **distro/gui.sh**: Moved `downloader()` to the top of the file — it is now defined before all `install_*` functions that depend on it.

### 🚀 Added
- **distro/gui.sh**: Added `set_default_browser()` — sets Firefox as the system default browser using four methods: `xdg-settings`, `update-alternatives`, `/etc/profile.d/default_browser.sh`, and `~/.config/mimeapps.list` for both root and the sudo user.
- **distro/gui.sh**: Browsers (Firefox, Chromium, Brave) are now auto-installed silently — no user prompt required. Firefox is set as default automatically after all three are installed.

### 📝 Updated
- **README.md**: Updated "Dual Browser Setup" → "Triple Browser Setup" (Firefox + Chromium + Brave).
- **README.md**: Fixed "TightVNC" → "TigerVNC" in Technical Info (the project uses `tigervnc-standalone-server`).
- **README.md**: Added proot-distro v5.x compatibility note to Key Features and Technical Info.
- **README.md**: Added troubleshooting entry for proot-distro v5.x "Error Installing Distro" false positive.
- **CHANGELOG.md**: Added this entry documenting all v1.2.0 changes.

---

## [v1.1.0] - 2025-10-30
### 🚀 Added
- **remove.sh** script to easily uninstall the Modded Debian environment and clean related configurations.
- **Images** in the `distro/` folder for visual reference and improved documentation.

### 📝 Updated
- **README.md** with detailed setup instructions, accurate information about the Modded Debian GUI setup, and usage guidance.

### 🔧 Improvements
- Enhanced overall documentation clarity and structure.
- Added better color formatting and safe cleanup logic in `remove.sh`.

---

## [v1.0.0] - 2025-09-15
### 🎉 Initial Release
- First public release of the **Modded Debian GUI for Termux**.
- Includes:
  - Installation script for Debian environment.
  - Desktop GUI setup and configuration files.
  - Audio and display support for Termux integration.

---

## 🧑‍💻 Maintainer
**Mahesh Varma**  
📧 help@maheshtechnicals.com  
🌐 [https://maheshtechnicals.com](https://maheshtechnicals.com)

---

## 📜 License
This project is licensed under the **Apache License** — see the [LICENSE](LICENSE) file for details.
