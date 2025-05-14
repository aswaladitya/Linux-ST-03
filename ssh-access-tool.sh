#!/bin/bash
#
# Simplified SSH Access Setup Tool
#

# Check requirements
if ! command -v dialog &> /dev/null; then
    echo "Please install dialog: sudo apt-get install dialog or sudo dnf install dialog"
    exit 1
fi
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo or as root."
    exit 1
fi

# Variables
TITLE="SSH Access Setup Tool"
SSH_CONFIG="/etc/ssh/sshd_config"
SSH_BACKUP="$SSH_CONFIG.bak.$(date +%Y%m%d%H%M%S)"
TEMP="/tmp/ssh-setup-temp"

# Find SSH service
check_ssh() {
    for SVC in sshd ssh; do
        if systemctl list-unit-files | grep -q "^$SVC.service"; then
            SSH_SERVICE="$SVC"
            if ! systemctl is-active --quiet "$SSH_SERVICE"; then
                systemctl start "$SSH_SERVICE"
                systemctl enable "$SSH_SERVICE"
            fi
            return 0
        fi
    done
    return 1
}

# Restart SSH
restart_ssh() {
    if ! check_ssh; then
        dialog --title "Error" --msgbox "SSH service not found or failed to start." 6 50
        return 1
    fi
    if systemctl restart "$SSH_SERVICE"; then
        dialog --title "Success" --msgbox "SSH service restarted successfully." 6 50
    else
        dialog --title "Error" --msgbox "Failed to restart SSH service." 6 50
        return 1
    fi
}

# Backup config
backup_config() {
    if cp "$SSH_CONFIG" "$SSH_BACKUP"; then
        dialog --title "Backup Created" --msgbox "SSH configuration backed up to:\n$SSH_BACKUP" 8 60
        return 0
    else
        dialog --title "Error" --msgbox "Failed to create backup." 6 50
        return 1
    fi
}

# Generate SSH key
gen_key() {
    # Get username
    dialog --title "Generate SSH Key" --inputbox "Username:" 8 60 "$USER" 2> $TEMP
    [ $? -ne 0 ] && return 1
    USERNAME=$(cat $TEMP)
    
    # Check user exists
    if ! id "$USERNAME" &>/dev/null; then
        dialog --title "Error" --msgbox "User doesn't exist." 6 50
        return 1
    fi
    
    # Get passphrase
    dialog --title "Passphrase" --passwordbox "Enter passphrase (empty for none):" 8 60 2> $TEMP
    [ $? -ne 0 ] && return 1
    PASSPHRASE=$(cat $TEMP)
    
    # Setup directory
    SSH_DIR="/home/$USERNAME/.ssh"
    if [ ! -d "$SSH_DIR" ]; then
        mkdir -p "$SSH_DIR"
        chown "$USERNAME:$USERNAME" "$SSH_DIR"
        chmod 700 "$SSH_DIR"
    fi
    
    # Generate key
    if ! su - $USERNAME -c "ssh-keygen -t rsa -b 4096 -f /home/$USERNAME/.ssh/id_rsa -N '$PASSPHRASE'"; then
        dialog --title "Error" --msgbox "Failed to generate SSH key." 6 50
        return 1
    fi
    
    # Set permissions
    chmod 600 "$SSH_DIR/id_rsa"
    chmod 644 "$SSH_DIR/id_rsa.pub"
    chown "$USERNAME:$USERNAME" "$SSH_DIR/id_rsa" "$SSH_DIR/id_rsa.pub"
    
    # Show result
    PUBLIC_KEY=$(cat "$SSH_DIR/id_rsa.pub")
    dialog --title "Success" --msgbox "SSH key generated!\n\nPublic key:\n$PUBLIC_KEY" 12 70
}

# Install SSH key
install_key() {
    # Get username
    dialog --title "Install SSH Key" --inputbox "Username:" 8 60 "$USER" 2> $TEMP
    [ $? -ne 0 ] && return 1
    USERNAME=$(cat $TEMP)
    
    # Check if user exists
    if ! id "$USERNAME" &>/dev/null; then
        dialog --title "Error" --msgbox "User doesn't exist." 6 50
        return 1
    fi
    
    # Get key
    dialog --title "Public Key" --inputbox "Paste the public key:" 12 70 2> $TEMP
    [ $? -ne 0 ] && return 1
    KEY=$(cat $TEMP)
    
    # Basic validation
    if [[ ! "$KEY" == ssh-* ]]; then
        dialog --title "Error" --msgbox "Invalid SSH key format." 6 50
        return 1
    fi
    
    # Setup directory
    SSH_DIR="/home/$USERNAME/.ssh"
    if [ ! -d "$SSH_DIR" ]; then
        mkdir -p "$SSH_DIR"
        chown "$USERNAME:$USERNAME" "$SSH_DIR"
        chmod 700 "$SSH_DIR"
    fi
    
    # Add key
    AUTH_KEYS="$SSH_DIR/authorized_keys"
    echo "$KEY" >> "$AUTH_KEYS"
    chown "$USERNAME:$USERNAME" "$AUTH_KEYS"
    chmod 600 "$AUTH_KEYS"
    
    dialog --title "Success" --msgbox "SSH key installed for user '$USERNAME'." 6 60
}

# Modify SSH config
modify_config() {
    # Backup first
    backup_config || return 1
    
    # Menu options
    OPTIONS=(
        "1" "Disable root login" 
        "2" "Enable key-only auth" 
        "3" "Apply all security settings"
        "4" "View SSH config"
    )
    
    CHOICE=$(dialog --title "Modify SSH Configuration" --menu "Select:" 12 60 4 "${OPTIONS[@]}" 2>&1 >/dev/tty)
    
    case $CHOICE in
        1)
            # Disable root login
            if grep -q "^PermitRootLogin" $SSH_CONFIG; then
                sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' $SSH_CONFIG
            else
                echo "PermitRootLogin no" >> $SSH_CONFIG
            fi
            dialog --title "Success" --msgbox "Root login disabled." 6 50
            ;;
        2)
            # Key-only auth
            sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' $SSH_CONFIG 2>/dev/null
            sed -i 's/^ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' $SSH_CONFIG 2>/dev/null
            sed -i 's/^PubkeyAuthentication.*/PubkeyAuthentication yes/' $SSH_CONFIG 2>/dev/null
            
            # Add settings if they don't exist
            grep -q "^PasswordAuthentication" $SSH_CONFIG || echo "PasswordAuthentication no" >> $SSH_CONFIG
            grep -q "^ChallengeResponseAuthentication" $SSH_CONFIG || echo "ChallengeResponseAuthentication no" >> $SSH_CONFIG
            grep -q "^PubkeyAuthentication" $SSH_CONFIG || echo "PubkeyAuthentication yes" >> $SSH_CONFIG
            
            dialog --title "Success" --msgbox "Key-only authentication enabled." 6 60
            ;;
        3)
            # Security settings
            SETTINGS=(
                "Protocol 2"
                "PermitRootLogin no"
                "PasswordAuthentication no"
                "PubkeyAuthentication yes"
                "ChallengeResponseAuthentication no"
                "X11Forwarding no"
                "UsePAM yes"
                "ClientAliveInterval 300"
                "ClientAliveCountMax 2"
                "MaxAuthTries 3"
                "LoginGraceTime 60"
            )
            
            for setting in "${SETTINGS[@]}"; do
                key=$(echo $setting | cut -d' ' -f1)
                
                if grep -q "^$key" $SSH_CONFIG; then
                    sed -i "s/^$key.*/$setting/" $SSH_CONFIG
                else
                    echo "$setting" >> $SSH_CONFIG
                fi
            done
            
            dialog --title "Success" --msgbox "Applied security settings." 6 70
            ;;
        4)
            # View config
            dialog --title "SSH Configuration" --textbox $SSH_CONFIG 20 80
            ;;
        *)
            return 0
            ;;
    esac
    
    # Ask to restart SSH
    dialog --title "Restart SSH" --yesno "Restart SSH service now?" 6 60
    [ $? -eq 0 ] && restart_ssh || dialog --title "Note" --msgbox "Changes apply after SSH restart." 6 60
}

# Debug info
show_debug() {
    check_ssh
    SERVICE_NAME=${SSH_SERVICE:-"Not detected"}
    
    INFO="SSH Service: $SERVICE_NAME\n"
    INFO+="Status: $(systemctl is-active $SERVICE_NAME 2>/dev/null || echo "Not running")\n"
    INFO+="SSH-Keygen: $(which ssh-keygen 2>/dev/null || echo "Not found")\n"
    INFO+="User: $(whoami)\n"
    INFO+="Config exists: $([ -f $SSH_CONFIG ] && echo 'Yes' || echo 'No')"
    
    dialog --title "Debug Info" --msgbox "$INFO" 12 60
}

# Main menu
main_menu() {
    while true; do
        check_ssh
        STATUS="SSH service: $(systemctl is-active $SSH_SERVICE 2>/dev/null || echo "not running")"
        
        MENU=(
            "1" "Generate SSH Key"
            "2" "Install SSH Key"
            "3" "Modify SSH Config"
            "4" "Restart SSH"
            "5" "Debug Info"
            "6" "Exit"
        )
        
        CHOICE=$(dialog --clear --title "$TITLE" \
                 --backtitle "$STATUS" \
                 --menu "Select option:" 15 60 6 \
                 "${MENU[@]}" 2>&1 >/dev/tty)
        
        case $CHOICE in
            1) gen_key ;;
            2) install_key ;;
            3) modify_config ;;
            4) restart_ssh ;;
            5) show_debug ;;
            6) clear; echo "Thanks for using SSH Setup Tool."; exit 0 ;;
            *) clear; echo "Exiting."; exit 0 ;;
        esac
    done
}

# Start program
main_menu
