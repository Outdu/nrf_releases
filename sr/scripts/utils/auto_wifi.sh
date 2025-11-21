#!/bin/bash

WIFI_SSID="TowerCam1"
WIFI_PASS="TowerCam1"
CHECK_INTERVAL=30        # Seconds between connection checks
RETRY_SLEEP=60           # Sleep time if connection attempt fails

connect_wifi() {
    echo "Attempting to connect to $WIFI_SSID ..."

    # Delete old connection profiles (optional, avoids conflicts)
    nmcli connection delete "$WIFI_SSID" >/dev/null 2>&1

    # Try to connect
    nmcli device wifi connect "$WIFI_SSID" password "$WIFI_PASS"
    
    if [ $? -eq 0 ]; then
        echo "Successfully connected to $WIFI_SSID"
    else
        echo "❌ Failed to connect. Retrying in $RETRY_SLEEP seconds..."
        sleep $RETRY_SLEEP
    fi
}

while true; do

    # Check if currently connected to the correct WiFi
    CURRENT_SSID=$(nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d: -f2)

    if [ "$CURRENT_SSID" == "$WIFI_SSID" ]; then
        echo "🟢 Connection OK: Connected to $WIFI_SSID"
    else
        echo "🔴 Not connected to $WIFI_SSID. Trying to connect..."
        connect_wifi
    fi

    sleep $CHECK_INTERVAL

done

