#!/bin/bash

# Script de Escaneo Personalizado con Auto-detección
# Permite objetivo personalizado con auto-configuración inteligente

echo "🎯 ESCANEO PERSONALIZADO CON AUTO-DETECCIÓN"
echo "==========================================="

# Auto-detectar configuración de red local como referencia
LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -1)
GATEWAY=$(ip route | grep "default" | awk '{print $3}' | head -1)
LOCAL_NETWORK=$(ip route | grep "$LOCAL_IP" | grep "/" | grep -v "default" | head -1 | awk '{print $1}')

echo "📍 Tu configuración de red:"
echo "   └─ IP Local: $LOCAL_IP"
echo "   └─ Gateway: $GATEWAY"
echo "   └─ Red Local: $LOCAL_NETWORK"

echo ""
echo "🎯 SELECCIÓN AUTOMÁTICA DE OBJETIVO"
echo "=================================="

# Determinar objetivo más probable
TARGET=""

# 1. Probar gateway primero (más común)
if [ -n "$GATEWAY" ]; then
    echo "🔍 Probando gateway como objetivo: $GATEWAY"
    if ping -c 2 -W 3 "$GATEWAY" &>/dev/null; then
        TARGET="$GATEWAY"
        TARGET_TYPE="Gateway/Router"
        echo "✅ Gateway responde - será el objetivo principal"
    else
        echo "❌ Gateway no responde a ping"
    fi
fi

# 2. Si gateway no responde, buscar otros dispositivos
if [ -z "$TARGET" ] && [ -n "$LOCAL_NETWORK" ]; then
    echo "🔍 Buscando dispositivos activos en la red local..."
    
    NETWORK_BASE=$(echo "$LOCAL_NETWORK" | cut -d'/' -f1 | cut -d'.' -f1-3)
    
    # Buscar IPs comunes de dispositivos
    COMMON_IPS=("${NETWORK_BASE}.1" "${NETWORK_BASE}.254" "${NETWORK_BASE}.100" "${NETWORK_BASE}.10")
    
    for IP in "${COMMON_IPS[@]}"; do
        if [ "$IP" != "$LOCAL_IP" ] && ping -c 1 -W 2 "$IP" &>/dev/null; then
            TARGET="$IP"
            TARGET_TYPE="Dispositivo de red"
            echo "✅ Dispositivo encontrado: $IP"
            break
        fi
    done
fi

# 3. Si aún no hay objetivo, usar una IP externa conocida
if [ -z "$TARGET" ]; then
    echo "🌐 No se encontraron dispositivos locales, usando objetivo externo..."
    TARGET="8.8.8.8"
    TARGET_TYPE="Servidor DNS público (Google)"
    echo "ℹ️  Objetivo: $TARGET (para pruebas de conectividad)"
fi

echo ""
echo "🎯 OBJETIVO SELECCIONADO"
echo "======================="
echo "📍 IP: $TARGET"
echo "🏷️  Tipo: $TARGET_TYPE"

echo ""
echo "🔍 VERIFICACIÓN DE CONECTIVIDAD"
echo "==============================="

# Test de conectividad básica
echo "🔗 Probando conectividad con $TARGET..."

PING_RESULT=$(ping -c 3 -W 3 "$TARGET" 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "✅ Objetivo responde a ping"
    
    # Extraer estadísticas de ping
    RTT=$(echo "$PING_RESULT" | grep "avg" | awk -F'/' '{print $5}' | awk '{print $1}')
    if [ -n "$RTT" ]; then
        echo "   └─ Tiempo promedio de respuesta: ${RTT}ms"
    fi
    
    PACKET_LOSS=$(echo "$PING_RESULT" | grep "packet loss" | awk '{print $6}')
    echo "   └─ Pérdida de paquetes: $PACKET_LOSS"
    
else
    echo "⚠️  Objetivo no responde a ping (puede tener firewall)"
fi

echo ""
echo "🔍 ESCANEO AUTOMÁTICO DE PUERTOS"
echo "==============================="

# Puertos más comunes para escanear automáticamente
COMMON_PORTS=(21 22 23 25 53 80 110 143 443 993 995 8080 8443)

echo "🔍 Escaneando puertos comunes en $TARGET..."

OPEN_PORTS=()
FILTERED_PORTS=()

for PORT in "${COMMON_PORTS[@]}"; do
    # Test de conectividad TCP con timeout
    if timeout 3 bash -c "echo >/dev/tcp/$TARGET/$PORT" 2>/dev/null; then
        OPEN_PORTS+=("$PORT")
        echo "✅ Puerto $PORT: ABIERTO"
        
        # Identificar servicio probable
        case $PORT in
            21) echo "   └─ 📁 FTP (File Transfer Protocol)" ;;
            22) echo "   └─ 🔐 SSH (Secure Shell)" ;;
            23) echo "   └─ 📡 Telnet" ;;
            25) echo "   └─ 📧 SMTP (Email)" ;;
            53) echo "   └─ 🌐 DNS (Domain Name System)" ;;
            80) echo "   └─ 🌐 HTTP (Web Server)" ;;
            110) echo "   └─ 📧 POP3 (Email)" ;;
            143) echo "   └─ 📧 IMAP (Email)" ;;
            443) echo "   └─ 🔒 HTTPS (Secure Web)" ;;
            993) echo "   └─ 📧 IMAPS (Secure IMAP)" ;;
            995) echo "   └─ 📧 POP3S (Secure POP3)" ;;
            8080) echo "   └─ 🌐 HTTP Alternativo" ;;
            8443) echo "   └─ 🔒 HTTPS Alternativo" ;;
        esac
        
    else
        # Verificar si está filtrado o cerrado
        FILTERED_PORTS+=("$PORT")
    fi
done

echo ""
echo "📊 RESUMEN DEL ESCANEO"
echo "====================="

echo "🎯 Objetivo escaneado: $TARGET"
echo "🔍 Puertos probados: ${#COMMON_PORTS[@]}"
echo "✅ Puertos abiertos: ${#OPEN_PORTS[@]}"

if [ ${#OPEN_PORTS[@]} -gt 0 ]; then
    echo "📂 Puertos abiertos encontrados:"
    for PORT in "${OPEN_PORTS[@]}"; do
        echo "   └─ $PORT"
    done
fi

echo ""
echo "🔍 ANÁLISIS DE SERVICIOS WEB"
echo "============================"

# Si hay servicios web, intentar obtener más información
WEB_PORTS_FOUND=()

for PORT in "${OPEN_PORTS[@]}"; do
    if [[ "$PORT" == "80" ]] || [[ "$PORT" == "443" ]] || [[ "$PORT" == "8080" ]] || [[ "$PORT" == "8443" ]]; then
        WEB_PORTS_FOUND+=("$PORT")
    fi
done

if [ ${#WEB_PORTS_FOUND[@]} -gt 0 ]; then
    echo "🌐 Servicios web encontrados en puertos: ${WEB_PORTS_FOUND[*]}"
    
    for PORT in "${WEB_PORTS_FOUND[@]}"; do
        if [[ "$PORT" == "443" ]] || [[ "$PORT" == "8443" ]]; then
            PROTOCOL="https"
        else
            PROTOCOL="http"
        fi
        
        URL="$PROTOCOL://$TARGET:$PORT"
        echo "🔍 Analizando $URL..."
        
        if command -v curl &>/dev/null; then
            # Obtener headers HTTP
            HEADERS=$(curl -I -s -m 5 "$URL" 2>/dev/null)
            if [ -n "$HEADERS" ]; then
                SERVER=$(echo "$HEADERS" | grep -i "server:" | head -1)
                STATUS=$(echo "$HEADERS" | head -1)
                
                if [ -n "$SERVER" ]; then
                    echo "   └─ $SERVER"
                fi
                echo "   └─ $STATUS"
            else
                echo "   └─ No se pudo obtener respuesta HTTP"
            fi
        fi
    done
else
    echo "❌ No se encontraron servicios web"
fi

echo ""
echo "💡 RECOMENDACIONES DE SIGUIENTE PASO"
echo "===================================="

if [ ${#OPEN_PORTS[@]} -gt 0 ]; then
    echo "🔍 Para análisis más profundo:"
    echo "   └─ nmap -sV -sC $TARGET"
    echo "   └─ nmap -p ${OPEN_PORTS[*]} -sV $TARGET"
    
    if [ ${#WEB_PORTS_FOUND[@]} -gt 0 ]; then
        echo "🌐 Para análisis web específico:"
        echo "   └─ nikto -h $TARGET"
        echo "   └─ dirb http://$TARGET"
    fi
    
    echo "🔒 Para escaneo de vulnerabilidades:"
    echo "   └─ nmap --script vuln $TARGET"
else
    echo "🛡️ Objetivo bien protegido o inaccesible"
    echo "🔍 Intenta escaneo más agresivo:"
    echo "   └─ nmap -Pn -sS $TARGET"
    echo "   └─ nmap -Pn -sU --top-ports 100 $TARGET"
fi

echo ""
echo "✅ Escaneo personalizado completado!"
echo "⚠️  Recordatorio: Solo usar en sistemas propios o con autorización"
echo "🔐 Respetar políticas de uso y términos de servicio"
