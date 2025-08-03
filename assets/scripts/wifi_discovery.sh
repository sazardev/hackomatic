#!/bin/bash

# Script de Descubrimiento WiFi Automático
# Auto-detecta interfaz WiFi y escanea redes disponibles

echo "📡 DESCUBRIMIENTO WiFi AUTOMÁTICO"
echo "================================="

# Auto-detectar interfaz WiFi
WIFI_INTERFACE=""

# Buscar interfaces WiFi comunes
for INTERFACE in wlan0 wlan1 wlp2s0 wlp3s0 wlo1; do
    if iwconfig "$INTERFACE" 2>/dev/null | grep -q "IEEE 802.11"; then
        WIFI_INTERFACE="$INTERFACE"
        break
    fi
done

# Si no se encuentra, buscar en todas las interfaces
if [ -z "$WIFI_INTERFACE" ]; then
    WIFI_INTERFACE=$(iwconfig 2>/dev/null | grep "IEEE 802.11" | awk '{print $1}' | head -1)
fi

if [ -z "$WIFI_INTERFACE" ]; then
    echo "❌ No se encontró ninguna interfaz WiFi"
    echo "💡 Asegúrate de que tu dispositivo tiene WiFi habilitado"
    exit 1
fi

echo "📶 Interfaz WiFi detectada: $WIFI_INTERFACE"
echo "🔍 Escaneando redes WiFi disponibles..."
echo ""

# Verificar si la interfaz está activa
if ! ip link show "$WIFI_INTERFACE" | grep -q "state UP"; then
    echo "⚠️  Activando interfaz $WIFI_INTERFACE..."
    sudo ip link set "$WIFI_INTERFACE" up 2>/dev/null
    sleep 2
fi

# Escanear redes WiFi
if command -v iwlist &> /dev/null; then
    echo "📡 Escaneando con iwlist..."
    
    # Realizar escaneo
    SCAN_RESULT=$(sudo iwlist "$WIFI_INTERFACE" scan 2>/dev/null)
    
    if [ -n "$SCAN_RESULT" ]; then
        echo "🔍 Redes WiFi encontradas:"
        echo "=========================="
        
        # Procesar resultados
        echo "$SCAN_RESULT" | awk '
        /Cell / { cell = $1 " " $2; address = $5 }
        /ESSID/ { 
            essid = $1
            gsub(/ESSID:"/, "", essid)
            gsub(/"/, "", essid)
            if (essid != "") print "📶 Red: " essid " - MAC: " address
        }
        /Quality/ {
            quality = $1
            gsub(/Quality=/, "", quality)
            signal = $3
            gsub(/Signal level=/, "", signal)
            print "   └─ Señal: " signal " - Calidad: " quality
        }
        /Encryption/ {
            if ($2 == "key:on") {
                print "   └─ 🔒 Red protegida"
            } else {
                print "   └─ 🔓 Red abierta"
            }
            print ""
        }'
    else
        echo "❌ No se pudieron escanear redes WiFi"
    fi
    
elif command -v nmcli &> /dev/null; then
    echo "📡 Escaneando con nmcli..."
    
    # Rescanear redes
    nmcli device wifi rescan 2>/dev/null
    sleep 3
    
    # Mostrar redes
    echo "🔍 Redes WiFi encontradas:"
    echo "=========================="
    nmcli device wifi list --rescan no | head -20
    
else
    echo "❌ No se encontraron herramientas de escaneo WiFi (iwlist, nmcli)"
    echo "💡 Instala wireless-tools o network-manager"
fi

echo ""
echo "📊 Información de la interfaz WiFi:"
echo "=================================="

# Estado de la interfaz
echo "🔌 Estado de $WIFI_INTERFACE:"
iwconfig "$WIFI_INTERFACE" 2>/dev/null | grep -E "Mode|Access Point|Frequency|Power"

# Red actual conectada
CURRENT_SSID=$(iwconfig "$WIFI_INTERFACE" 2>/dev/null | grep "ESSID" | cut -d'"' -f2)
if [ -n "$CURRENT_SSID" ] && [ "$CURRENT_SSID" != "off/any" ]; then
    echo "📶 Conectado a: $CURRENT_SSID"
else
    echo "❌ No conectado a ninguna red"
fi

# Información adicional
if command -v nmcli &> /dev/null; then
    echo ""
    echo "🔍 Información detallada de conectividad:"
    nmcli device show "$WIFI_INTERFACE" | grep -E "IP4.ADDRESS|IP4.GATEWAY|IP4.DNS"
fi

echo ""
echo "✅ Descubrimiento WiFi completado!"
echo "💡 Tip: Las redes abiertas pueden ser objetivos para análisis de seguridad"
echo "⚠️  Recuerda: Solo realiza pruebas en redes propias o con autorización"
