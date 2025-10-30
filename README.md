# 🐧 Moded Debian Script

![Moded Debian Banner](./distro/image.jpg)

[![GitHub stars](https://img.shields.io/github/stars/MaheshTechnicals/Moded-Debian?style=for-the-badge)](https://github.com/MaheshTechnicals/Moded-Debian/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/MaheshTechnicals/Moded-Debian?style=for-the-badge)](https://github.com/MaheshTechnicals/Moded-Debian/network/members)
[![GitHub issues](https://img.shields.io/github/issues/MaheshTechnicals/Moded-Debian?style=for-the-badge)](https://github.com/MaheshTechnicals/Moded-Debian/issues)
[![GitHub license](https://img.shields.io/github/license/MaheshTechnicals/Moded-Debian?style=for-the-badge)](./LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/MaheshTechnicals/Moded-Debian?style=for-the-badge)](https://github.com/MaheshTechnicals/Moded-Debian/commits/main)

Run **Debian Linux GUI on Termux** with enhanced features, preinstalled tools, and beautiful UI.  
Developed and maintained by **Mahesh Technicals** for Linux lovers who want a full Debian desktop experience on Android.

---

## 🚀 Key Features

✅ **Audio Fixed** – Full sound support in Termux (Proot-Distro)  
✅ **Lightweight RootFS** – Requires only ~4 GB storage  
✅ **Dual Browser Setup** – Chromium + Mozilla Firefox  
✅ **Bangla Font Support** – Perfect for multilingual users  
✅ **Preinstalled Media Players** – VLC & MPV  
✅ **Code Ready** – Visual Studio Code (arm64/aarch64) & Sublime Text  
✅ **User-Friendly Installer** – Designed for beginners  
✅ **Beautiful UI** – Modern icons, wallpapers, and system themes  

---

## 📦 Installation Guide

### Step 1 — Install Termux
Download the latest Termux app from [Termux.com](https://termux.com).

### Step 2 — Clone Repository and Setup
```bash
yes | pkg upgrade
pkg install git wget -y
git clone --depth=1 https://github.com/MaheshTechnicals/Moded-Debian.git
cd Moded-Debian
bash setup.sh
```

### Step 3 — Launch Debian CLI
After installation completes, **restart Termux** and type:
```bash
debian
bash user.sh
```
> Enter your root username (lowercase, no spaces).

### Step 4 — Launch Debian GUI
Restart Termux again and type:
```bash
debian
sudo bash gui.sh
```
> Set and remember your **VNC password**.

### Step 5 — Start and Stop GUI
```bash
vncstart   # Start Debian GUI
vncstop    # Stop Debian GUI
```

### Step 6 — Connect Using VNC Viewer
1. Install **[VNC Viewer](https://play.google.com/store/apps/details?id=com.realvnc.viewer.android&hl=en)** on your phone.  
2. Create a new connection:
   - **Address:** `localhost:1`
   - **Name:** `Debian`
   - **Quality:** High
3. Connect & enjoy Debian Desktop on Android!

---

## 💡 Notes

- Use `debian` command anytime to enter the Debian CLI.  
- To start the GUI session: `vncstart`  
- To stop the GUI session: `vncstop`  
- To **remove Debian completely**, run:
  ```bash
  bash remove.sh
  ```
- You must have **at least 4 GB free storage** before installation.

---

## 🎥 Video Tutorial

Watch the setup tutorial below for a complete walkthrough:  
[![Watch Video](./distro/image1.jpg)](https://mega.nz/embed/QvIC1TLQ#3z27MRNPwANAg6JTtx1Ei8kDouOZsZgk00bg4TsJMNQ!1m)

---

## 🔄 Changelog

See the full list of updates and improvements here:  
👉 [CHANGELOG.md](./CHANGELOG.md)

---

## 🛠️ Technical Info

- **Base Distro:** Debian (Proot-Distro)
- **Architecture:** aarch64 / arm64
- **Display Server:** TightVNC
- **Desktop Environment:** XFCE4
- **Developed For:** Android (Termux)
- **Minimum Storage Required:** 4 GB free

---

## 🧠 Troubleshooting

**Q:** VNC session not connecting?  
**A:** Restart Termux and type:
```bash
debian
vncstart
```
Then reconnect via VNC Viewer.

**Q:** Audio not working?  
**A:** Run `pavucontrol` inside Debian GUI and make sure output device is not muted.

---

## 🧑‍💻 Maintainer

**Mahesh Varma (Mahesh Technicals)**  
📧 [help@maheshtechnicals.com](mailto:help@maheshtechnicals.com)  
🌐 [GitHub Profile](https://github.com/MaheshTechnicals)

---

## 📝 License

This project is licensed under the [Apache License](./LICENSE).

---

## 🙏 Credits

This project uses Debian images provided by **Termux Proot-Distro**.  
All credits to:
- [Termux Team](https://github.com/termux)
- [Proot-Distro Maintainers](https://github.com/termux/proot-distro)

---

## ⭐ Support & Contribution

If you like this project, please:
- 🌟 Star the repository  
- 🪄 Fork it and make improvements  
- 📣 Share it with your friends  

> “Linux isn’t hard — it’s just a new way to explore your Android!”

---

### 🔍 SEO Keywords

`debian termux`, `debian android`, `linux on android`, `termux debian setup`, `vnc viewer termux`, `moded debian`, `maheshthechnicals debian`, `debian xfce termux`, `proot distro debian`, `install debian termux gui`, `debian vnc setup android`

---

**© 2025 Mahesh Technicals — All rights reserved**
