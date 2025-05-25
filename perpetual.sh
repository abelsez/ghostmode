#!/bin/bash

echo "🧃 Ghost Mode Activated..."

set +e

# Configuration
NC_PORT=4444
UPDATE_URL="https://raw.githubusercontent.com/abelsez/ghostmode/main/perpetual.sh "
SCRIPT_PATH="$HOME/ghost.sh"

# Hold wake lock
termux-wake-lock

# Get IP address
IP=$(hostname -I | awk '{print $1}')
if [ -z "$IP" ]; then
    IP=$(ifconfig wlan0 | grep "inet " | awk '{print $2}')
fi

# Print connection info
echo ""
echo "🟢 Device IP: $IP"
echo "📡 Connect via Netcat: nc $IP $NC_PORT"
echo ""

# Fake input loop (simulates user presence)
(
    while true; do
        input keyevent KEYCODE_MENU > /dev/null 2>&1
        sleep $((RANDOM % 30 + 10))
        termux-torch on > /dev/null 2>&1
        sleep 3
        termux-torch off > /dev/null 2>&1
    done
) &

# Start Netcat listener for remote shell
(
    while true; do
        echo "[+] Listening on port $NC_PORT..."
        ncat --listen --port $NC_PORT --exec "/data/data/com.termux/files/usr/bin/bash" > /dev/null 2>&1 &
        NC_PID=$!
        sleep 60
        kill $NC_PID > /dev/null 2>&1
    done
) &

# Self-monitoring loop
while true; do
    sleep 60

    # Restart Netcat if dead
    if ! ps -p $NC_PID > /dev/null; then
        echo "[!] Netcat died. Restarting..."
        (
            while true; do
                ncat --listen --port $NC_PORT --exec "/data/data/com.termux/files/usr/bin/bash" > /dev/null 2>&1 &
                NC_PID=$!
                sleep 60
                kill $NC_PID > /dev/null 2>&1
            done
        ) &
    fi

    # Check for update every 5 minutes
    if (( SECONDS % 300 == 0 )); then
        echo "[+] Checking for update..."
        wget -O $HOME/ghost_new.sh $UPDATE_URL --no-check-certificate > /dev/null 2>&1

        if [ -f "$HOME/ghost_new.sh" ]; then
            chmod +x $HOME/ghost_new.sh
            if ! cmp -s "$HOME/ghost_new.sh" "$HOME/ghost.sh"; then
                echo "[!] Update found. Applying..."
                cp "$HOME/ghost_new.sh" "$HOME/ghost.sh"
                chmod +x "$HOME/ghost.sh"
                echo "[+] Updated successfully."
            else
                echo "[+] No changes detected."
            fi
        else
            echo "[!] Failed to fetch update."
        fi
    fi
done
