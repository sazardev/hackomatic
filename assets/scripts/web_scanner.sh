#!/bin/bash

# Web Application Scanner Script for Hackomatic
# Author: Hackomatic Team
# Description: Scan web applications for common vulnerabilities

URL="$1"
WORDLIST="${2:-/usr/share/wordlists/dirb/common.txt}"
OUTPUT_DIR="/tmp/web_scan_$(date +%Y%m%d_%H%M%S)"

echo "Web Application Scanner"
echo "======================"
echo "Target URL: $URL"
echo "Wordlist: $WORDLIST"
echo "Output directory: $OUTPUT_DIR"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Check if required tools are installed
if ! command -v gobuster &> /dev/null; then
    echo "WARNING: gobuster is not installed"
    echo "Install with: apt-get install gobuster"
fi

if ! command -v nikto &> /dev/null; then
    echo "WARNING: nikto is not installed"
    echo "Install with: apt-get install nikto"
fi

if ! command -v curl &> /dev/null; then
    echo "ERROR: curl is not installed"
    exit 1
fi

# Basic connectivity test
echo -e "\nPhase 1: Connectivity Test"
if curl -s --head "$URL" | head -n 1 | grep -q "200 OK"; then
    echo "✓ Target is reachable"
else
    echo "✗ Target may not be reachable or returned error"
fi

# Get server information
echo -e "\nPhase 2: Server Information"
curl -s -I "$URL" | tee "$OUTPUT_DIR/headers.txt"

# Directory enumeration with gobuster
if command -v gobuster &> /dev/null && [ -f "$WORDLIST" ]; then
    echo -e "\nPhase 3: Directory Enumeration"
    gobuster dir -u "$URL" -w "$WORDLIST" -o "$OUTPUT_DIR/directories.txt" --no-error
    
    echo "Found directories:"
    grep "Status: 200" "$OUTPUT_DIR/directories.txt" || echo "No accessible directories found"
fi

# Vulnerability scanning with nikto
if command -v nikto &> /dev/null; then
    echo -e "\nPhase 4: Vulnerability Scanning"
    nikto -h "$URL" -output "$OUTPUT_DIR/nikto.txt"
    
    echo "Nikto scan completed. Check $OUTPUT_DIR/nikto.txt for results"
fi

# Check for common files
echo -e "\nPhase 5: Common Files Check"
COMMON_FILES=("robots.txt" "sitemap.xml" "admin" "login" "wp-admin" ".git" ".env")

for file in "${COMMON_FILES[@]}"; do
    if curl -s -o /dev/null -w "%{http_code}" "$URL/$file" | grep -q "200"; then
        echo "✓ Found: $URL/$file"
    fi
done

echo -e "\nWeb application scan completed!"
echo "Results saved to: $OUTPUT_DIR"
echo "Summary:"
ls -la "$OUTPUT_DIR"
