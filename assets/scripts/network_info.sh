#!/bin/bash

# Script de Información de Red Completa
# Auto-detecta y muestra información detallada de la red

echo "🌐 INFORMACIÓN COMPLETA DE RED"
echo "=============================="

# Función para mostrar información de interfaz
show_interface_info() {
    local INTERFACE=$1
    echo "🔌 Interfaz: $INTERFACE"
    
    # Estado de la interfaz
    STATE=$(ip link show "$INTERFACE" | grep -o "state [A-Z]*" | cut -d' ' -f2)
    echo "   └─ Estado: $STATE"
    
    # Dirección IP
    IP_INFO=$(ip addr show "$INTERFACE" | grep "inet " | head -1)
    if [ -n "$IP_INFO" ]; then
        IP=$(echo "$IP_INFO" | awk '{print $2}' | cut -d'/' -f1)
        MASK=$(echo "$IP_INFO" | awk '{print $2}' | cut -d'/' -f2)
        echo "   └─ IP: $IP/$MASK"
    fi
    
    # MAC Address
    MAC=$(ip link show "$INTERFACE" | grep "link/ether" | awk '{print $2}')
    if [ -n "$MAC" ]; then
        echo "   └─ MAC: $MAC"
    fi
    
    echo ""
}

# Auto-detectar interfaz principal de red
MAIN_INTERFACE=""

# Buscar interfaz con gateway por defecto
DEFAULT_ROUTE=$(ip route | grep "default" | head -1)
if [ -n "$DEFAULT_ROUTE" ]; then
    MAIN_INTERFACE=$(echo "$DEFAULT_ROUTE" | awk '{print $5}')
fi

# Si no se encuentra, buscar interfaces activas
if [ -z "$MAIN_INTERFACE" ]; then
    MAIN_INTERFACE=$(ip route | grep -E "^[0-9]" | head -1 | awk '{print $3}')
fi

echo "📊 INFORMACIÓN DE INTERFACES DE RED"
echo "===================================="

# Mostrar todas las interfaces activas
echo "🔍 Interfaces de red activas:"
for INTERFACE in $(ip link show | grep "state UP" | awk -F: '{print $2}' | tr -d ' '); do
    if [ "$INTERFACE" != "lo" ]; then
        show_interface_info "$INTERFACE"
    fi
done

echo "🌐 CONFIGURACIÓN DE RED PRINCIPAL"
echo "=================================="

if [ -n "$MAIN_INTERFACE" ]; then
    echo "🎯 Interfaz principal: $MAIN_INTERFACE"
    
    # IP local
    LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -1)
    echo "📍 IP Local: $LOCAL_IP"
    
    # Gateway
    GATEWAY=$(ip route | grep "default" | awk '{print $3}' | head -1)
    echo "🚪 Gateway: $GATEWAY"
    
    # Red local
    NETWORK=$(ip route | grep "$MAIN_INTERFACE" | grep "/" | grep -v "default" | head -1 | awk '{print $1}')
    echo "🏠 Red Local: $NETWORK"
    
    # DNS
    echo "🔍 Servidores DNS:"
    if [ -f /etc/resolv.conf ]; then
        grep "nameserver" /etc/resolv.conf | while read line; do
            DNS=$(echo "$line" | awk '{print $2}')
            echo "   └─ $DNS"
        done
    fi
    
else
    echo "❌ No se pudo detectar la interfaz principal"
fi

echo ""
echo "📡 CONECTIVIDAD EXTERNA"
echo "======================="

# Test de conectividad
echo "🌍 Probando conectividad a Internet..."

# Ping a Google DNS
if ping -c 1 -W 3 8.8.8.8 &>/dev/null; then
    echo "✅ Conectividad a Internet: ACTIVA"
else
    echo "❌ Conectividad a Internet: INACTIVA"
fi

# Test de resolución DNS
echo "🔍 Probando resolución DNS..."
if nslookup google.com &>/dev/null; then
    echo "✅ Resolución DNS: FUNCIONAL"
else
    echo "❌ Resolución DNS: PROBLEMAS"
fi

echo ""
echo "🛰️ INFORMACIÓN WiFi (si disponible)"
echo "==================================="

# Detectar interfaz WiFi
WIFI_INTERFACE=""
for INTERFACE in wlan0 wlan1 wlp2s0 wlp3s0 wlo1; do
    if iwconfig "$INTERFACE" 2>/dev/null | grep -q "IEEE 802.11"; then
        WIFI_INTERFACE="$INTERFACE"
        break
    fi
done

if [ -n "$WIFI_INTERFACE" ]; then
    echo "📶 Interfaz WiFi: $WIFI_INTERFACE"
    
    # Red WiFi actual
    CURRENT_SSID=$(iwconfig "$WIFI_INTERFACE" 2>/dev/null | grep "ESSID" | cut -d'"' -f2)
    if [ -n "$CURRENT_SSID" ] && [ "$CURRENT_SSID" != "off/any" ]; then
        echo "📡 Red WiFi actual: $CURRENT_SSID"
        
        # Calidad de señal
        SIGNAL_INFO=$(iwconfig "$WIFI_INTERFACE" 2>/dev/null | grep "Signal level")
        if [ -n "$SIGNAL_INFO" ]; then
            echo "📊 Calidad: $SIGNAL_INFO"
        fi
    else
        echo "❌ No conectado a WiFi"
    fi
else
    echo "❌ No se detectó interfaz WiFi"
fi

echo ""
echo "🔍 TABLA DE ENRUTAMIENTO"
echo "========================"
echo "📋 Rutas activas:"
ip route | head -10

echo ""
echo "👥 DISPOSITIVOS EN LA RED LOCAL"
echo "==============================="

if [ -n "$NETWORK" ] && command -v nmap &>/dev/null; then
    echo "🔍 Escaneando dispositivos en $NETWORK..."
    nmap -sn "$NETWORK" 2>/dev/null | grep -E "Nmap scan report|MAC Address" | head -20
elif [ -n "$GATEWAY" ]; then
    echo "🔍 Probando gateway $GATEWAY..."
    if ping -c 1 -W 2 "$GATEWAY" &>/dev/null; then
        echo "✅ Gateway responde: $GATEWAY"
    else
        echo "❌ Gateway no responde: $GATEWAY"
    fi
else
    echo "❌ No se puede escanear la red (nmap no disponible o red no detectada)"
fi

echo ""
echo "⚡ ESTADÍSTICAS DE TRÁFICO"
echo "=========================="

if command -v ss &>/dev/null; then
    echo "🔗 Conexiones activas (TCP):"
    ss -t | head -10
elif command -v netstat &>/dev/null; then
    echo "🔗 Conexiones activas (TCP):"
    netstat -t | head -10
fi

echo ""
echo "✅ Información de red completada!"
echo "💡 Esta información es útil para auditorías de seguridad de red"
echo "⚠️  Usar solo en redes propias o con autorización"
