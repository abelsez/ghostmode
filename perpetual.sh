#!/bin/bash

echo "🧃 Ghost Mode Activated..."

set +e

# Configuration
UPDATE_URL="https://raw.githubusercontent.com/yourusername/ghostmode/main/perpetual.sh "
SCRIPT_PATH="$HOME/perpetual.sh"

# Acquire wake lock
termux-wake-lock

# Fake activity loop
(
    while true; do
        input keyevent KEYCODE_MENU > /dev/null 2>&1
        sleep $((RANDOM % 30 + 10))
    done
) &

# Get IP
IP=$(hostname -I | awk '{print $1}')
if [ -z "$IP" ]; then
    IP=$(ifconfig wlan0 | grep "inet " | awk '{print $2}')
fi
PORT=8022

# Start SSH server
pkg install openssh -y > /dev/null 2>&1
sshd > /dev/null 2>&1 &
sleep 2

# Set password silently
echo "Setting Termux SSH password..."
passwd <<EOF
6547.Sezz
6547.Sezz
EOF

# Monitor Watu Simu process
WATU_PID=""
find_watu() {
    ps -ef | grep 'watu' | grep -v 'grep' | awk '{print $2}' | head -n1
}

# Self-monitoring loop
while true; do
    sleep 30

    # Restart SSH if dead
    if ! pgrep -f "sshd" > /dev/null; then
        echo "[!] SSHD died. Restarting..."
        sshd > /dev/null 2>&1 &
    fi

    # Restart fake input loop if killed
    if ! ps -p $(jobs -p) > /dev/null; then
        (
            while true; do
                input keyevent KEYCODE_MENU > /dev/null 2>&1
                sleep $((RANDOM % 30 + 10))
            done
        ) &
    fi

    # Re-check Watu Simu process
    WATU_PID=$(find_watu)
    if [ -n "$WATU_PID" ]; then
        echo "[+] Watu Simu running as PID: $WATU_PID"
    else
        echo "[!] Watu Simu not found."
    fi

    # Optional: Check for remote updates
    if ping -c 1 google.com > /dev/null 2>&1; then
        echo "[+] Checking for remote script update..."
        wget -O $HOME/perpetual_new.sh $UPDATE_URL --no-check-certificate > /dev/null 2>&1
        if cmp -s $HOME/perpetual_new.sh $HOME/perpetual.sh; then
            echo "[+] No update needed."
        else
            echo "[!] Update detected. Applying..."
            cp $HOME/perpetual_new.sh $HOME/perpetual.sh
            chmod +x $HOME/perpetual.sh
            echo "[+] Updated ghost script."
        fi
    fi

done