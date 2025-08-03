#!/bin/bash

# Network Scanner Script for Hackomatic
# Author: Hackomatic Team
# Description: Comprehensive network scanning using nmap

NETWORK="$1"
OUTPUT_FILE="/tmp/network_scan_$(date +%Y%m%d_%H%M%S).txt"

echo "Starting network scan on $NETWORK"
echo "Results will be saved to: $OUTPUT_FILE"
echo "====================================="

# Check if nmap is installed
if ! command -v nmap &> /dev/null; then
    echo "ERROR: nmap is not installed"
    echo "Please install nmap: apt-get install nmap"
    exit 1
fi

# Basic network discovery
echo "Phase 1: Host Discovery"
nmap -sn "$NETWORK" | tee -a "$OUTPUT_FILE"

echo -e "\nPhase 2: Port Scanning"
# Quick scan of common ports on discovered hosts
nmap -F "$NETWORK" | tee -a "$OUTPUT_FILE"

echo -e "\nPhase 3: Service Detection"
# Service and version detection
nmap -sV -A "$NETWORK" | tee -a "$OUTPUT_FILE"

echo -e "\nScan completed! Results saved to: $OUTPUT_FILE"
echo "Found hosts:"
grep "Nmap scan report" "$OUTPUT_FILE" | cut -d' ' -f5
