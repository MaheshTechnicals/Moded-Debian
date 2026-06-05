# 📘 Changelog
All notable changes to this project will be documented in this file.  
This project follows [Semantic Versioning](https://semver.org/) and the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.

---

## [v1.3.0] - 2026-06-05

### 🗑️ Removed
- **distro/gui.sh**: Removed `install_chromium()` function and its call from `install_softwares()`. Now only Firefox and Brave are installed. Chromium is no longer part of this project.

### 🚀 Added
- **distro/user.sh**: Added `clear;` prefix to the `debian` launcher command so the Termux terminal auto-clears when user types `debian`.
- **setup.sh**: Added `clear;` prefix to the `debian` shortcut command for CLI mode login (when user has not run `user.sh` yet).

### 🐛 Fixed
- **distro/vncstart**: Added shebang `#!/usr/bin/env bash` — was missing, could cause issues if sourced instead of executed.
- **distro/gui.sh** (`config()`): Added `mkdir -p` calls before every `tar -xvzf` extraction to ensure destination directories exist. Prevents extraction failure when directories are missing.
- **distro/gui.sh** (`config()`): Added safety check — `debian-settings.tar.gz` is only extracted if `$username` is non-empty and `/home/$username/` exists. Prevents silent extraction failure into a non-existent directory.

### 📝 Updated
- **README.md**: Changed "Triple Browser Setup" → "Dual Browser Setup" (Firefox + Brave only).

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
This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.
