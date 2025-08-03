#!/bin/bash

# Script de Escaneo de Puertos Automático
# Auto-detecta el gateway y escanea puertos comunes

echo "🔍 ESCANEO DE PUERTOS AUTOMÁTICO"
echo "================================"

# Auto-detectar gateway
GATEWAY=$(ip route | grep default | awk '{print $3}' | head -1)

if [ -z "$GATEWAY" ]; then
    # Fallback: calcular gateway desde IP local
    LOCAL_IP=$(ip route get 1.1.1.1 | awk '{print $7; exit}' 2>/dev/null)
    if [ -n "$LOCAL_IP" ]; then
        IFS='.' read -ra IP_PARTS <<< "$LOCAL_IP"
        GATEWAY="${IP_PARTS[0]}.${IP_PARTS[1]}.${IP_PARTS[2]}.1"
    else
        GATEWAY="192.168.1.1"
    fi
fi

echo "🎯 Objetivo detectado: $GATEWAY (Gateway)"
echo "⏱️  Iniciando escaneo de puertos..."
echo ""

# Puertos más comunes a escanear
COMMON_PORTS="21,22,23,25,53,80,110,135,139,143,443,993,995,1723,3389,5900,8080,8443,9090"

if command -v nmap &> /dev/null; then
    echo "🔍 Usando nmap para escaneo avanzado..."
    echo ""
    
    # Escaneo SYN rápido
    echo "📡 Fase 1: Escaneo SYN de puertos comunes"
    nmap -sS -p "$COMMON_PORTS" "$GATEWAY" --open
    
    echo ""
    echo "📡 Fase 2: Detección de servicios en puertos abiertos"
    
    # Obtener puertos abiertos
    OPEN_PORTS=$(nmap -sS -p "$COMMON_PORTS" "$GATEWAY" --open | grep "^[0-9]" | grep "open" | cut -d'/' -f1 | tr '\n' ',' | sed 's/,$//')
    
    if [ -n "$OPEN_PORTS" ]; then
        echo "🔍 Detectando servicios y versiones en puertos: $OPEN_PORTS"
        nmap -sV -sC -p "$OPEN_PORTS" "$GATEWAY"
        
        echo ""
        echo "🛡️  Fase 3: Escaneo básico de vulnerabilidades"
        nmap --script vuln -p "$OPEN_PORTS" "$GATEWAY" | grep -E "VULNERABLE|CVE|HIGH|MEDIUM"
    else
        echo "❌ No se encontraron puertos abiertos en los puertos comunes"
    fi
    
else
    echo "⚠️  nmap no disponible, usando netcat para escaneo básico..."
    echo ""
    
    # Escaneo básico con netcat
    for PORT in $(echo "$COMMON_PORTS" | tr ',' ' '); do
        if timeout 2 bash -c "echo >/dev/tcp/$GATEWAY/$PORT" 2>/dev/null; then
            echo "✅ Puerto $PORT/tcp abierto"
            
            # Intentar identificar servicio
            case $PORT in
                21) echo "   └─ Posible FTP" ;;
                22) echo "   └─ Posible SSH" ;;
                23) echo "   └─ Posible Telnet" ;;
                25) echo "   └─ Posible SMTP" ;;
                53) echo "   └─ Posible DNS" ;;
                80) echo "   └─ Posible HTTP" ;;
                443) echo "   └─ Posible HTTPS" ;;
                3389) echo "   └─ Posible RDP" ;;
                5900) echo "   └─ Posible VNC" ;;
                8080) echo "   └─ Posible HTTP Alternativo" ;;
                *) echo "   └─ Servicio desconocido" ;;
            esac
        fi
    done
fi

echo ""
echo "🌐 Información adicional del objetivo:"
echo "======================================"

# Ping básico
if ping -c 3 "$GATEWAY" &> /dev/null; then
    echo "✅ Host responde a ping"
else
    echo "❌ Host no responde a ping (puede tener firewall)"
fi

# Intentar resolver nombre
HOSTNAME=$(nslookup "$GATEWAY" 2>/dev/null | grep "name = " | awk '{print $4}' | sed 's/\.$//')
if [ -n "$HOSTNAME" ]; then
    echo "🏷️  Hostname: $HOSTNAME"
fi

# Traceroute básico
echo "🛤️  Ruta hasta el objetivo:"
if command -v traceroute &> /dev/null; then
    traceroute -m 5 "$GATEWAY" 2>/dev/null | head -6
else
    echo "   (traceroute no disponible)"
fi

echo ""
echo "✅ Escaneo de puertos completado!"
echo "💡 Tip: Los puertos abiertos pueden indicar servicios disponibles para análisis"
