#!/bin/bash
# HACKOMATIC - Script de ejemplo para escaneo de red básico
echo "🚀 HACKOMATIC - Iniciando escaneo de red básico..."
echo "=================================="

# Obtener información de la interfaz de red
echo "📡 Información de red:"
ip addr show | grep "inet " | grep -v 127.0.0.1

echo ""
echo "🔍 Escaneando red local..."
nmap -sn $(ip route | grep wlan0 | head -1 | awk '{print $1}' | grep -v default) 2>/dev/null || {
    echo "❌ Nmap no está instalado o no hay permisos"
    echo "💡 Instalación sugerida: sudo apt install nmap"
}

echo ""
echo "📊 Estadísticas básicas:"
echo "- Fecha: $(date)"
echo "- Usuario: $(whoami)"
echo "- Sistema: $(uname -a)"

echo ""
echo "✅ Escaneo completado - HACKOMATIC"
