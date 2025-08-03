#!/bin/bash

# Port Scanner Script for Hackomatic
# Author: Hackomatic Team
# Description: Advanced port scanning with multiple techniques

TARGET="$1"
SCAN_TYPE="${2:--sS}"
PORT_RANGE="${3:-1-1000}"
OUTPUT_FILE="/tmp/port_scan_$(date +%Y%m%d_%H%M%S).txt"

echo "Starting port scan on $TARGET"
echo "Scan type: $SCAN_TYPE"
echo "Port range: $PORT_RANGE"
echo "Output: $OUTPUT_FILE"
echo "=============================="

# Check if nmap is installed
if ! command -v nmap &> /dev/null; then
    echo "ERROR: nmap is not installed"
    exit 1
fi

# Validate target
if [ -z "$TARGET" ]; then
    echo "ERROR: No target specified"
    echo "Usage: $0 <target> [scan_type] [port_range]"
    exit 1
fi

# Basic port scan
echo "Running basic port scan..."
nmap "$SCAN_TYPE" -p "$PORT_RANGE" "$TARGET" | tee "$OUTPUT_FILE"

# Service detection on open ports
OPEN_PORTS=$(grep "open" "$OUTPUT_FILE" | grep -v "Nmap scan report" | awk '{print $1}' | cut -d'/' -f1 | tr '\n' ',' | sed 's/,$//')

if [ -n "$OPEN_PORTS" ]; then
    echo -e "\nRunning service detection on open ports: $OPEN_PORTS"
    nmap -sV -sC -p "$OPEN_PORTS" "$TARGET" | tee -a "$OUTPUT_FILE"
    
    echo -e "\nRunning vulnerability scan..."
    nmap --script vuln -p "$OPEN_PORTS" "$TARGET" | tee -a "$OUTPUT_FILE"
fi

echo -e "\nPort scan completed!"
echo "Results saved to: $OUTPUT_FILE"
echo "Open ports found:"
grep "open" "$OUTPUT_FILE" | grep -v "Nmap scan report"
