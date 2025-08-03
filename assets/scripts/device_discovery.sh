#!/bin/bash

# Script de Descubrimiento de Dispositivos Automático
# Auto-detecta red local y escanea dispositivos conectados

echo "📱 DESCUBRIMIENTO AUTOMÁTICO DE DISPOSITIVOS"
echo "============================================"

# Auto-detectar configuración de red
echo "🔍 Auto-detectando configuración de red..."

# Obtener IP local
LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -1)
if [ -z "$LOCAL_IP" ]; then
    LOCAL_IP=$(hostname -I | awk '{print $1}')
fi

# Obtener red local
NETWORK=$(ip route | grep "$LOCAL_IP" | grep "/" | grep -v "default" | head -1 | awk '{print $1}')
if [ -z "$NETWORK" ]; then
    # Calcular red basado en IP local (asumiendo /24)
    NETWORK_BASE=$(echo "$LOCAL_IP" | cut -d'.' -f1-3)
    NETWORK="${NETWORK_BASE}.0/24"
fi

# Obtener gateway
GATEWAY=$(ip route | grep "default" | awk '{print $3}' | head -1)

echo "📍 IP Local: $LOCAL_IP"
echo "🏠 Red Local: $NETWORK"
echo "🚪 Gateway: $GATEWAY"

echo ""
echo "📡 ESCANEO RÁPIDO DE DISPOSITIVOS"
echo "================================="

# Método 1: Ping Sweep (rápido)
echo "🔍 Realizando ping sweep en $NETWORK..."

ACTIVE_IPS=()
NETWORK_BASE=$(echo "$NETWORK" | cut -d'/' -f1 | cut -d'.' -f1-3)

# Ping paralelo para velocidad
echo "⚡ Escaneando IPs activas..."
for i in {1..254}; do
    IP="${NETWORK_BASE}.$i"
    (
        if ping -c 1 -W 1 "$IP" &>/dev/null; then
            echo "✅ $IP"
        fi
    ) &
    
    # Limitar procesos paralelos
    if (( i % 50 == 0 )); then
        wait
    fi
done
wait

echo ""
echo "📋 DISPOSITIVOS ENCONTRADOS"
echo "==========================="

# Escaneo más detallado de IPs activas
echo "🔍 Analizando dispositivos activos..."

DEVICE_COUNT=0

for i in {1..254}; do
    IP="${NETWORK_BASE}.$i"
    
    if ping -c 1 -W 1 "$IP" &>/dev/null; then
        ((DEVICE_COUNT++))
        
        echo "📱 Dispositivo $DEVICE_COUNT: $IP"
        
        # Obtener información adicional
        # MAC Address (si está en ARP table)
        MAC=$(arp -n "$IP" 2>/dev/null | awk '{print $3}' | grep -E "([0-9a-f]{2}:){5}[0-9a-f]{2}")
        if [ -n "$MAC" ]; then
            echo "   └─ MAC: $MAC"
            
            # Identificar fabricante (primeros 3 octetos)
            OUI=$(echo "$MAC" | cut -d':' -f1-3 | tr ':' '-' | tr 'a-f' 'A-F')
            case "$OUI" in
                "00-50-56"|"00-0C-29"|"00-05-69") echo "   └─ 🖥️  VMware Virtual Machine" ;;
                "08-00-27") echo "   └─ 🖥️  VirtualBox Virtual Machine" ;;
                "52-54-00") echo "   └─ 🖥️  QEMU Virtual Machine" ;;
                "00-15-5D"|"00-03-FF") echo "   └─ 🖥️  Microsoft Hyper-V" ;;
                "DC-A6-32"|"E8-DE-27"|"F0-18-98") echo "   └─ 📱 Dispositivo Raspberry Pi" ;;
                "B8-27-EB"|"DC-A6-32") echo "   └─ 📱 Raspberry Pi Foundation" ;;
                *) echo "   └─ 📱 Dispositivo de red" ;;
            esac
        fi
        
        # Hostname lookup
        HOSTNAME=$(nslookup "$IP" 2>/dev/null | grep "name =" | awk '{print $4}' | sed 's/\.$//')
        if [ -n "$HOSTNAME" ]; then
            echo "   └─ 🏷️  Hostname: $HOSTNAME"
        fi
        
        # Puertos comunes abiertos
        OPEN_SERVICES=""
        
        # SSH
        if timeout 1 bash -c "echo >/dev/tcp/$IP/22" 2>/dev/null; then
            OPEN_SERVICES="$OPEN_SERVICES SSH(22)"
        fi
        
        # HTTP
        if timeout 1 bash -c "echo >/dev/tcp/$IP/80" 2>/dev/null; then
            OPEN_SERVICES="$OPEN_SERVICES HTTP(80)"
        fi
        
        # HTTPS
        if timeout 1 bash -c "echo >/dev/tcp/$IP/443" 2>/dev/null; then
            OPEN_SERVICES="$OPEN_SERVICES HTTPS(443)"
        fi
        
        # Telnet
        if timeout 1 bash -c "echo >/dev/tcp/$IP/23" 2>/dev/null; then
            OPEN_SERVICES="$OPEN_SERVICES Telnet(23)"
        fi
        
        # FTP
        if timeout 1 bash -c "echo >/dev/tcp/$IP/21" 2>/dev/null; then
            OPEN_SERVICES="$OPEN_SERVICES FTP(21)"
        fi
        
        if [ -n "$OPEN_SERVICES" ]; then
            echo "   └─ 🔗 Servicios:$OPEN_SERVICES"
        fi
        
        # Marcar si es el gateway
        if [ "$IP" = "$GATEWAY" ]; then
            echo "   └─ 🚪 GATEWAY/ROUTER"
        fi
        
        # Marcar si es la IP local
        if [ "$IP" = "$LOCAL_IP" ]; then
            echo "   └─ 💻 ESTE DISPOSITIVO"
        fi
        
        echo ""
        
        # Limitar a 20 dispositivos para no saturar
        if [ $DEVICE_COUNT -ge 20 ]; then
            echo "   └─ (Limitando resultados a 20 dispositivos...)"
            break
        fi
    fi
done

echo "📊 RESUMEN DEL DESCUBRIMIENTO"
echo "============================="

echo "🏠 Red escaneada: $NETWORK"
echo "📱 Dispositivos encontrados: $DEVICE_COUNT"
echo "💻 Tu IP: $LOCAL_IP"
echo "🚪 Gateway: $GATEWAY"

# Información adicional de ARP table
echo ""
echo "📋 TABLA ARP COMPLETA"
echo "===================="
echo "🔍 Dispositivos en la tabla ARP local:"

arp -a 2>/dev/null | head -15 | while IFS= read -r line; do
    echo "   └─ $line"
done

echo ""
echo "🛰️ INFORMACIÓN DE INTERFACES DE RED"
echo "==================================="

# Mostrar interfaces activas
echo "🔌 Interfaces de red activas:"
ip link show | grep "state UP" | awk -F: '{print $2}' | while read INTERFACE; do
    INTERFACE=$(echo "$INTERFACE" | tr -d ' ')
    if [ "$INTERFACE" != "lo" ]; then
        echo "   └─ $INTERFACE"
        
        # IP de la interfaz
        INTERFACE_IP=$(ip addr show "$INTERFACE" | grep "inet " | awk '{print $2}' | head -1)
        if [ -n "$INTERFACE_IP" ]; then
            echo "      └─ IP: $INTERFACE_IP"
        fi
    fi
done

echo ""
echo "💡 RECOMENDACIONES PARA ANÁLISIS PROFUNDO"
echo "========================================"

echo "🔍 Para escaneo detallado con nmap:"
echo "   └─ nmap -sn $NETWORK"
echo "   └─ nmap -sV $NETWORK"

echo "🕵️  Para análisis de servicios:"
echo "   └─ nmap -sC -sV [IP_objetivo]"

echo "🔒 Para análisis de vulnerabilidades:"
echo "   └─ nmap --script vuln [IP_objetivo]"

echo ""
echo "✅ Descubrimiento de dispositivos completado!"
echo "⚠️  Recordatorio: Solo realizar en redes propias o con autorización"
echo "🔐 Respetar la privacidad y términos de uso de la red"
