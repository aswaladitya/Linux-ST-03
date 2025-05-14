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

- Linux system with `systemd`
- `dialog` installed  
  Install with:

  ```bash
  sudo apt install dialog    # Debian/Ubuntu
  sudo dnf install dialog    # Fedora/RHEL
