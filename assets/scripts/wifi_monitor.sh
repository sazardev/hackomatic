#!/bin/bash

# WiFi Monitor Script for Hackomatic
# Author: Hackomatic Team
# Description: Monitor WiFi networks and capture packets

INTERFACE="$1"
CHANNEL="${2:-6}"
CAPTURE_FILE="/tmp/wifi_capture_$(date +%Y%m%d_%H%M%S).cap"

echo "Starting WiFi monitoring on interface $INTERFACE"
echo "Channel: $CHANNEL"
echo "Capture file: $CAPTURE_FILE"
echo "==========================================="

# Check if required tools are installed
if ! command -v aircrack-ng &> /dev/null; then
    echo "ERROR: aircrack-ng suite is not installed"
    echo "Please install: apt-get install aircrack-ng"
    exit 1
fi

if ! command -v iwconfig &> /dev/null; then
    echo "ERROR: wireless-tools is not installed"
    echo "Please install: apt-get install wireless-tools"
    exit 1
fi

# Check if interface exists
if ! iwconfig "$INTERFACE" &> /dev/null; then
    echo "ERROR: Interface $INTERFACE not found"
    echo "Available interfaces:"
    iwconfig 2>/dev/null | grep "IEEE 802.11" | cut -d' ' -f1
    exit 1
fi

# Put interface in monitor mode
echo "Setting $INTERFACE to monitor mode..."
sudo airmon-ng start "$INTERFACE"

# Get the monitor interface name (usually wlan0mon)
MONITOR_INTERFACE=$(iwconfig 2>/dev/null | grep "Mode:Monitor" | cut -d' ' -f1)

if [ -z "$MONITOR_INTERFACE" ]; then
    echo "ERROR: Failed to create monitor interface"
    exit 1
fi

echo "Monitor interface created: $MONITOR_INTERFACE"

# Set channel
echo "Setting channel to $CHANNEL..."
sudo iwconfig "$MONITOR_INTERFACE" channel "$CHANNEL"

# Start monitoring
echo "Starting packet capture... (Press Ctrl+C to stop)"
sudo airodump-ng --write "${CAPTURE_FILE%.*}" --channel "$CHANNEL" "$MONITOR_INTERFACE"

echo "Capture stopped. Files saved:"
ls -la "${CAPTURE_FILE%.*}*"

# Restore managed mode
echo "Restoring interface to managed mode..."
sudo airmon-ng stop "$MONITOR_INTERFACE"

echo "WiFi monitoring completed!"
