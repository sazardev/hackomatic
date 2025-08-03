#!/bin/bash

# Script de Escaneo Web Automático
# Auto-detecta gateway y realiza escaneo web básico

echo "🌐 ESCANEO WEB AUTOMÁTICO"
echo "========================="

# Auto-detectar gateway (objetivo principal)
GATEWAY=$(ip route | grep "default" | awk '{print $3}' | head -1)

if [ -z "$GATEWAY" ]; then
    echo "❌ No se pudo detectar el gateway automáticamente"
    echo "💡 Verificando conectividad de red..."
    
    # Intentar detectar red local
    LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -1)
    if [ -n "$LOCAL_IP" ]; then
        # Calcular posible gateway basado en IP local
        NETWORK_BASE=$(echo "$LOCAL_IP" | cut -d'.' -f1-3)
        GATEWAY="${NETWORK_BASE}.1"
        echo "🔍 Probando gateway calculado: $GATEWAY"
    else
        echo "❌ No se pudo determinar el objetivo de escaneo"
        exit 1
    fi
fi

echo "🎯 Objetivo de escaneo: $GATEWAY"

# Verificar conectividad
echo "🔍 Verificando conectividad con $GATEWAY..."
if ping -c 2 -W 3 "$GATEWAY" &>/dev/null; then
    echo "✅ Objetivo responde a ping"
else
    echo "⚠️  Objetivo no responde a ping (puede tener firewall)"
fi

echo ""
echo "🌐 ESCANEO DE PUERTOS WEB COMUNES"
echo "=================================="

# Puertos web comunes para escanear
WEB_PORTS=(80 443 8080 8443 8000 8008 3000 5000 9000)

echo "🔍 Escaneando puertos web en $GATEWAY..."

for PORT in "${WEB_PORTS[@]}"; do
    # Test de conectividad TCP
    if timeout 3 bash -c "echo >/dev/tcp/$GATEWAY/$PORT" 2>/dev/null; then
        echo "✅ Puerto $PORT: ABIERTO"
        
        # Determinar protocolo
        if [ "$PORT" = "443" ] || [ "$PORT" = "8443" ]; then
            PROTOCOL="https"
        else
            PROTOCOL="http"
        fi
        
        URL="$PROTOCOL://$GATEWAY:$PORT"
        
        # Intentar obtener información del servidor web
        if command -v curl &>/dev/null; then
            echo "   └─ Probando $URL..."
            
            # Headers del servidor
            HEADERS=$(curl -I -s -m 5 "$URL" 2>/dev/null | head -5)
            if [ -n "$HEADERS" ]; then
                SERVER=$(echo "$HEADERS" | grep -i "server:" | head -1)
                if [ -n "$SERVER" ]; then
                    echo "   └─ $SERVER"
                fi
                
                STATUS=$(echo "$HEADERS" | head -1)
                echo "   └─ Status: $STATUS"
            else
                echo "   └─ No se pudo obtener información HTTP"
            fi
        else
            echo "   └─ URL potencial: $URL"
        fi
        
    else
        echo "❌ Puerto $PORT: CERRADO"
    fi
done

echo ""
echo "🔍 DETECCIÓN DE SERVICIOS WEB"
echo "============================="

# Servicios web comunes en puertos alternativos
ALT_PORTS=(81 8081 8082 8090 8888 9080 9090 10000)

echo "🔍 Escaneando puertos alternativos..."

OPEN_COUNT=0
for PORT in "${ALT_PORTS[@]}"; do
    if timeout 2 bash -c "echo >/dev/tcp/$GATEWAY/$PORT" 2>/dev/null; then
        echo "✅ Puerto $PORT: ABIERTO (servicio web alternativo)"
        ((OPEN_COUNT++))
        
        if [ $OPEN_COUNT -ge 3 ]; then
            echo "   └─ (limitando resultados...)"
            break
        fi
    fi
done

if [ $OPEN_COUNT -eq 0 ]; then
    echo "❌ No se encontraron servicios web en puertos alternativos"
fi

echo ""
echo "🛡️ DETECCIÓN BÁSICA DE FIREWALL/WAF"
echo "===================================="

# Test básico de detección de firewall
echo "🔍 Probando detección de firewall..."

# Intentar conexión a puerto comúnmente filtrado
if timeout 1 bash -c "echo >/dev/tcp/$GATEWAY/22" 2>/dev/null; then
    echo "✅ Puerto 22 (SSH): ABIERTO"
elif timeout 1 bash -c "echo >/dev/tcp/$GATEWAY/23" 2>/dev/null; then
    echo "✅ Puerto 23 (Telnet): ABIERTO"
else
    echo "🛡️ Posible firewall detectado (puertos administrativos cerrados)"
fi

# Test de puertos altos
HIGH_PORT_OPEN=false
for PORT in 65534 65535; do
    if timeout 1 bash -c "echo >/dev/tcp/$GATEWAY/$PORT" 2>/dev/null; then
        HIGH_PORT_OPEN=true
        break
    fi
done

if $HIGH_PORT_OPEN; then
    echo "⚠️  Puertos altos abiertos (configuración poco segura)"
else
    echo "🛡️ Puertos altos cerrados (buena práctica de seguridad)"
fi

echo ""
echo "📊 RESUMEN DEL ESCANEO"
echo "======================"

echo "🎯 Objetivo: $GATEWAY"
echo "🔍 Puertos web escaneados: ${#WEB_PORTS[@]}"
echo "🌐 Servicios web encontrados: Ver resultados arriba"
echo "⏱️  Tiempo de escaneo: ~30 segundos"

echo ""
echo "💡 RECOMENDACIONES"
echo "=================="

echo "🔍 Para un escaneo más profundo, usa:"
echo "   └─ nmap -sV $GATEWAY"
echo "   └─ nmap -sC -sV -p- $GATEWAY"

echo "🌐 Para análisis web específico:"
echo "   └─ nikto -h http://$GATEWAY"
echo "   └─ dirb http://$GATEWAY"

echo "⚠️  Para escaneo de vulnerabilidades:"
echo "   └─ nmap --script vuln $GATEWAY"

echo ""
echo "✅ Escaneo web automático completado!"
echo "⚠️  Recordatorio: Solo usar en sistemas propios o con autorización"
echo "🔒 Respetar términos de servicio y políticas de uso"
