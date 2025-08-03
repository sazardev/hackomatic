#!/bin/bash

# Script de Escaneo Rápido de Red - Automático
# Auto-detecta y escanea tu red local

echo "🔍 ESCANEO RÁPIDO DE RED - AUTOMÁTICO"
echo "====================================="

# Auto-detectar IP local
LOCAL_IP=$(ip route get 1.1.1.1 | awk '{print $7; exit}' 2>/dev/null)
if [ -z "$LOCAL_IP" ]; then
    LOCAL_IP=$(hostname -I | awk '{print $1}')
fi

if [ -z "$LOCAL_IP" ]; then
    echo "❌ No se pudo detectar la IP local"
    exit 1
fi

# Calcular red local
IFS='.' read -ra IP_PARTS <<< "$LOCAL_IP"
NETWORK="${IP_PARTS[0]}.${IP_PARTS[1]}.${IP_PARTS[2]}.0/24"

echo "📍 IP Local detectada: $LOCAL_IP"
echo "🌐 Red a escanear: $NETWORK"
echo ""

# Verificar si nmap está disponible
if ! command -v nmap &> /dev/null; then
    echo "⚠️  nmap no está instalado, usando ping básico..."
    echo ""
    
    # Escaneo básico con ping
    echo "🔍 Escaneando dispositivos activos..."
    for i in {1..254}; do
        IP="${IP_PARTS[0]}.${IP_PARTS[1]}.${IP_PARTS[2]}.$i"
        if ping -c 1 -W 1 "$IP" &> /dev/null; then
            HOSTNAME=$(nslookup "$IP" 2>/dev/null | grep "name = " | awk '{print $4}' | sed 's/\.$//')
            if [ -n "$HOSTNAME" ]; then
                echo "✅ $IP - $HOSTNAME"
            else
                echo "✅ $IP"
            fi
        fi
    done
else
    echo "🔍 Realizando escaneo de red con nmap..."
    echo ""
    
    # Escaneo de hosts activos
    echo "📡 Fase 1: Descubrimiento de hosts"
    nmap -sn "$NETWORK" | grep -E "Nmap scan report|MAC Address" | while read line; do
        if [[ $line == *"Nmap scan report"* ]]; then
            echo "✅ $line" | sed 's/Nmap scan report for //'
        elif [[ $line == *"MAC Address"* ]]; then
            echo "   └─ $line"
        fi
    done
    
    echo ""
    echo "🔍 Fase 2: Escaneo rápido de puertos en gateway"
    GATEWAY="${IP_PARTS[0]}.${IP_PARTS[1]}.${IP_PARTS[2]}.1"
    echo "🎯 Escaneando gateway: $GATEWAY"
    nmap -sS -F "$GATEWAY" | grep -E "PORT|open"
fi

echo ""
echo "📊 Información adicional de red:"
echo "================================"

# Mostrar gateway
GATEWAY=$(ip route | grep default | awk '{print $3}' | head -1)
echo "🚪 Gateway: $GATEWAY"

# Mostrar DNS
DNS=$(cat /etc/resolv.conf | grep nameserver | head -1 | awk '{print $2}')
echo "🌐 DNS: $DNS"

# Mostrar interfaces activas
echo "🔌 Interfaces de red activas:"
ip addr show | grep -E "^[0-9]+:" | grep -v lo | while read line; do
    INTERFACE=$(echo "$line" | cut -d: -f2 | tr -d ' ')
    STATE=$(echo "$line" | grep -o "state [A-Z]*" | cut -d' ' -f2)
    echo "   • $INTERFACE ($STATE)"
done

echo ""
echo "✅ Escaneo completado!"
echo "💡 Tip: Revisa los dispositivos encontrados para identificar posibles objetivos"
