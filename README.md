# SteamOS NordVPN Helper Scripts

> An automated, beginner-friendly way to install, update, and manage the official NordVPN Linux client on SteamOS (Steam Deck) without breaking your read-only system.

---

## 🚀 Features

* **Automated File Unlocking:** Temporarily disables the SteamOS read-only lock to safely install/remove packages and re-locks it immediately when finished.
* **Keyring Configuration:** Automatically sets up your system security keys (`pacman-key`) to avoid signature or package errors during installation.
* **Desktop Mode Integration:** Configures system security contexts so the `deck` user can instantly manage NordVPN from the terminal.
* **Service Automation:** Installs and configures the background daemon (`nordvpnd.service`) so it's always active and ready to connect.

---

## 🛠️ Prerequisites

Before running the script, you **must set a terminal (sudo) password** on your Steam Deck if you haven't already:
1. Switch to **Desktop Mode** (Press the Steam Button → Power → Switch to Desktop).
2. Open the **Konsole** app (found in your applications menu under system utilities).
3. Type `passwd` and press **Enter**.
4. Type a secure password of your choice (characters won't show up on screen as you type for security), press **Enter**, and confirm it. **Remember this password!**

---

## 📦 How to Install NordVPN

Follow these simple steps to download and execute the installer:

### Step 1: Open the Terminal
Make sure you are in **Desktop Mode** and open the **Konsole** app.

### Step 2: Download and Run the Installer
Copy and paste the following commands into Konsole and press **Enter**:

```bash
# Clone this helper scripts repository
git clone [https://github.com/cwtechshiz/nordvpn-steamos-scripts.git](https://github.com/cwtechshiz/nordvpn-steamos-scripts.git)

# Enter the scripts directory
cd nordvpn-steamos-scripts

# Make the installer script executable
chmod +x install_nord.sh

# Run the installer
./install_nord.sh
```

### Step 3: Enter Your Password
The script will prompt you for your terminal password (the one you created in the prerequisites). Type it in and press **Enter**. 

The installation will take a minute or two to safely unpack, build, and configure the system targets. Once it finishes and displays **"SUCCESS: NordVPN is installed and ready!"**, you can proceed.

---

## 🔑 Logging In to Your NordVPN Account

Before jumping back to Gaming Mode, you must authenticate your NordVPN account once via the terminal:

1. In the same Konsole window, type:
```bash
   nordvpn login
   ```
2. NordVPN will generate a secure web link. Right-click the link and select **Open Link**, or copy and paste it into your web browser.
3. Log in to your account on the official NordVPN webpage.
4. Your browser will prompt you to link back to the application. Once accepted, the terminal will confirm you are logged in.

You now have nordvpn installed on steamos and it can be used as a command in terminal. 
See ```man nordvpn``` or ```nordvpn --help``` if you need help running it from command line.

---

## 🎮 Managing NordVPN in Gaming Mode

Now that the system configurations are complete, you can safely return to **Gaming Mode**!

To avoid ever using Desktop Mode or a terminal again, install the companion **[NordVPN Decky Plugin](https://github.com/cwtechshiz/nordvpn-decky)**. It adds a beautiful status card inside your `···` overlay where you can select a country, connect/disconnect, and toggle **Meshnet** with a tap.

---


## ⚠️ IMPORTANT: SteamOS Updates & Reinstalling
**SteamOS is designed to completely reset its core system files during major system updates.** This means NordVPN will likely disappear whenever you update your Steam Deck. 

**Don't panic!** You do not need to repeat the entire setup or look up complex terminal commands again. If NordVPN stops working after a SteamOS update, just do this to quickly reinstall it:
1. Open the **Konsole** app in Desktop Mode.
2. Type `cd nordvpn-steamos-scripts` and press **Enter**.
3. Type `./install_nord.sh` and press **Enter**.

This script was designed specifically to make re-adding NordVPN a simple, one-step process for you and your friends!

---


## 🗑️ How to Uninstall NordVPN

If you ever want to completely remove NordVPN and clean up all system files, the uninstallation process is fully automated:

1. Open **Konsole** in Desktop Mode.
2. Navigate back to this scripts folder:
```bash
   cd ~/nordvpn-steamos-scripts
   ```
3. Run the uninstaller script:
```bash
   chmod +x uninstall_nord.sh
   ./uninstall_nord.sh
   ```
4. The script safely stops active daemons, deletes the application packages, wipes custom user groups, and leaves your SteamOS locked down exactly as it found it.

