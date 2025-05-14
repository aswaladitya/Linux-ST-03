---

````markdown
# 🔐 SSH Access Setup Tool (Bash + Dialog GUI)

A terminal-based GUI tool to simplify and secure SSH configuration, key generation, and access management on Linux systems.

This tool uses `dialog` to provide an interactive menu for users and sysadmins to quickly set up and secure SSH access with no manual file editing required.

---

## 📦 Features

- ✅ Generate SSH key pairs for any user
- ✅ Install public SSH keys for passwordless login
- ✅ Modify `sshd_config` to:
  - Disable root login
  - Enable key-only authentication
  - Apply hardened security settings
- ✅ Restart the SSH service safely
- ✅ Backup the current SSH configuration before applying changes
- ✅ View live SSH configuration and debug info

---

## 🖥️ Requirements

- Linux system with `systemd` support
- [WSL (Windows Subsystem for Linux)](https://learn.microsoft.com/en-us/windows/wsl/install) — for Windows users
- `dialog` installed  
  Install with:

  ```bash
  sudo apt install dialog    # Debian/Ubuntu
  sudo dnf install dialog    # Fedora/RHEL
````

* Run as root:

  ```bash
  sudo ./ssh-setup.sh
  ```

📌 **Note for WSL Users**:
This script can run in **WSL**, but features like `systemctl` may not work unless you're using a WSL version that supports `systemd` (e.g., Ubuntu 22.04+ with `wsl.conf` configured). SSH service management might be limited on older WSL setups.

---

## 🚀 Installation & Usage

1. Clone the repository:

   ```bash
   git clone https://github.com/aswaladitya/Linux-ST-03.git
   cd Linux-ST-03
   chmod +x ssh-setup.sh
   sudo ./ssh-setup.sh
   ```

---

## 📁 File Structure

```
Linux-ST-03/
├── ssh-setup.sh       # Main executable script
├── README.md          # Project documentation
```

---

## ⚠️ Disclaimer

* This tool modifies system-level SSH settings.
* Always test changes in a non-critical environment before deploying on production servers.
* Script must be run with **root privileges**.

---

## 📜 License

MIT License — free to use, modify, and distribute.

---

## 🙋‍♂️ Author

Made with ❤️ by [aswaladitya](https://github.com/aswaladitya)

```

---

You can now copy this into your `README.md` file inside your `Linux-ST-03` repository. Let me know if you want badges, screenshots (of the dialog UI), or demo GIFs added too.
```
