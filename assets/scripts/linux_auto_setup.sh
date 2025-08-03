#!/bin/bash

# Hackomatic Linux Auto-Setup Script
# Soporte universal para todas las distribuciones Linux principales
# Autor: Hackomatic Team
# Versión: 2.0

set -e  # Exit on any error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Emojis para mejor UX
ROBOT="🤖"
PENGUIN="🐧"
ROCKET="🚀"
GEAR="⚙️"
CHECK="✅"
CROSS="❌"
WARNING="⚠️"
FIRE="🔥"

# Función de logging mejorada
log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}${CHECK} $1${NC}"
}

error() {
    echo -e "${RED}${CROSS} $1${NC}"
}

warning() {
    echo -e "${YELLOW}${WARNING} $1${NC}"
}

info() {
    echo -e "${CYAN}${GEAR} $1${NC}"
}

# Banner de bienvenida
show_banner() {
    clear
    echo -e "${PURPLE}"
    cat << "EOF"
 ██╗  ██╗ █████╗  ██████╗██╗  ██╗ ██████╗ ███╗   ███╗ █████╗ ████████╗██╗ ██████╗
 ██║  ██║██╔══██╗██╔════╝██║ ██╔╝██╔═══██╗████╗ ████║██╔══██╗╚══██╔══╝██║██╔════╝
 ███████║███████║██║     █████╔╝ ██║   ██║██╔████╔██║███████║   ██║   ██║██║     
 ██╔══██║██╔══██║██║     ██╔═██╗ ██║   ██║██║╚██╔╝██║██╔══██║   ██║   ██║██║     
 ██║  ██║██║  ██║╚██████╗██║  ██╗╚██████╔╝██║ ╚═╝ ██║██║  ██║   ██║   ██║╚██████╗
 ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝
EOF
    echo -e "${NC}"
    echo -e "${CYAN}${ROBOT} Auto-Setup Script para Linux ${PENGUIN}${NC}"
    echo -e "${YELLOW}${FIRE} Configuración automática de herramientas de hacking ético ${FIRE}${NC}"
    echo ""
}

# Detectar distribución Linux
detect_distro() {
    log "Detectando distribución Linux..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        DISTRO=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
        VERSION=$(lsb_release -sr)
    else
        DISTRO="unknown"
        VERSION="unknown"
    fi
    
    success "Distribución detectada: $DISTRO $VERSION"
    export DISTRO VERSION
}

# Detectar package manager
detect_package_manager() {
    log "Detectando package manager..."
    
    if command -v apt >/dev/null 2>&1; then
        PKG_MANAGER="apt"
        UPDATE_CMD="apt update"
        INSTALL_CMD="apt install -y"
        SEARCH_CMD="apt search"
    elif command -v dnf >/dev/null 2>&1; then
        PKG_MANAGER="dnf"
        UPDATE_CMD="dnf check-update || true"
        INSTALL_CMD="dnf install -y"
        SEARCH_CMD="dnf search"
    elif command -v yum >/dev/null 2>&1; then
        PKG_MANAGER="yum"
        UPDATE_CMD="yum check-update || true"
        INSTALL_CMD="yum install -y"
        SEARCH_CMD="yum search"
    elif command -v pacman >/dev/null 2>&1; then
        PKG_MANAGER="pacman"
        UPDATE_CMD="pacman -Sy"
        INSTALL_CMD="pacman -S --noconfirm"
        SEARCH_CMD="pacman -Ss"
    elif command -v zypper >/dev/null 2>&1; then
        PKG_MANAGER="zypper"
        UPDATE_CMD="zypper refresh"
        INSTALL_CMD="zypper install -y"
        SEARCH_CMD="zypper search"
    elif command -v apk >/dev/null 2>&1; then
        PKG_MANAGER="apk"
        UPDATE_CMD="apk update"
        INSTALL_CMD="apk add"
        SEARCH_CMD="apk search"
    else
        error "No se encontró un package manager compatible"
        exit 1
    fi
    
    success "Package manager: $PKG_MANAGER"
    export PKG_MANAGER UPDATE_CMD INSTALL_CMD SEARCH_CMD
}

# Actualizar sistema
update_system() {
    log "Actualizando repositorios del sistema..."
    
    case $PKG_MANAGER in
        "apt")
            sudo $UPDATE_CMD
            sudo apt upgrade -y
            ;;
        "dnf"|"yum")
            sudo $UPDATE_CMD
            sudo $INSTALL_CMD dnf-plugins-core || sudo $INSTALL_CMD yum-utils
            ;;
        "pacman")
            sudo $UPDATE_CMD
            sudo pacman -Su --noconfirm
            ;;
        "zypper")
            sudo $UPDATE_CMD
            sudo zypper update -y
            ;;
        "apk")
            sudo $UPDATE_CMD
            sudo apk upgrade
            ;;
    esac
    
    success "Sistema actualizado"
}

# Instalar dependencias básicas
install_dependencies() {
    log "Instalando dependencias básicas..."
    
    local deps=""
    case $PKG_MANAGER in
        "apt")
            deps="curl wget git build-essential python3 python3-pip ruby-dev nodejs npm cmake"
            ;;
        "dnf"|"yum")
            deps="curl wget git gcc gcc-c++ make python3 python3-pip ruby-devel nodejs npm cmake"
            ;;
        "pacman")
            deps="curl wget git base-devel python python-pip ruby nodejs npm cmake"
            ;;
        "zypper")
            deps="curl wget git gcc gcc-c++ make python3 python3-pip ruby-devel nodejs20 npm20 cmake"
            ;;
        "apk")
            deps="curl wget git build-base python3 py3-pip ruby-dev nodejs npm cmake"
            ;;
    esac
    
    if [ -n "$deps" ]; then
        sudo $INSTALL_CMD $deps
        success "Dependencias básicas instaladas"
    fi
}

# Instalar herramientas de red
install_network_tools() {
    log "Instalando herramientas de red..."
    
    local tools=""
    case $PKG_MANAGER in
        "apt")
            tools="nmap masscan zmap netcat-traditional socat netdiscover arp-scan fping hping3 tcpdump wireshark tshark ngrep"
            ;;
        "dnf"|"yum")
            tools="nmap masscan netcat socat fping hping3 tcpdump wireshark-cli ngrep"
            ;;
        "pacman")
            tools="nmap masscan gnu-netcat socat netdiscover fping hping tcpdump wireshark-cli ngrep"
            ;;
        "zypper")
            tools="nmap netcat socat fping hping3 tcpdump wireshark ngrep"
            ;;
        "apk")
            tools="nmap netcat-openbsd socat fping tcpdump ngrep"
            ;;
    esac
    
    for tool in $tools; do
        install_tool "$tool" "Herramienta de red"
    done
    
    success "Herramientas de red instaladas"
}

# Instalar herramientas web
install_web_tools() {
    log "Instalando herramientas de análisis web..."
    
    local tools=""
    case $PKG_MANAGER in
        "apt")
            tools="nikto dirb gobuster ffuf sqlmap whatweb wafw00f sublist3r fierce"
            ;;
        "dnf"|"yum")
            tools="nikto sqlmap whatweb"
            ;;
        "pacman")
            tools="nikto gobuster ffuf sqlmap whatweb"
            ;;
        "zypper")
            tools="nikto sqlmap"
            ;;
        "apk")
            tools="nikto sqlmap"
            ;;
    esac
    
    for tool in $tools; do
        install_tool "$tool" "Herramienta web"
    done
    
    # Instalar herramientas adicionales vía pip/gem/npm
    install_additional_web_tools
    
    success "Herramientas web instaladas"
}

# Instalar herramientas adicionales web vía pip/gem/npm
install_additional_web_tools() {
    info "Instalando herramientas web adicionales..."
    
    # Python tools
    python3 -m pip install --user wfuzz commix xsser dirsearch linkfinder sublist3r
    
    # Ruby tools
    gem install wpscan --user-install 2>/dev/null || true
    
    # Go tools (si go está disponible)
    if command -v go >/dev/null 2>&1; then
        go install github.com/ffuf/ffuf/v2@latest 2>/dev/null || true
        go install github.com/OJ/gobuster/v3@latest 2>/dev/null || true
    fi
}

# Instalar herramientas wireless
install_wireless_tools() {
    log "Instalando herramientas wireless..."
    
    local tools=""
    case $PKG_MANAGER in
        "apt")
            tools="aircrack-ng reaver bully cowpatty kismet hostapd dnsmasq"
            ;;
        "dnf"|"yum")
            tools="aircrack-ng kismet hostapd dnsmasq"
            ;;
        "pacman")
            tools="aircrack-ng reaver kismet hostapd dnsmasq"
            ;;
        "zypper")
            tools="aircrack-ng hostapd dnsmasq"
            ;;
        "apk")
            tools="aircrack-ng hostapd dnsmasq"
            ;;
    esac
    
    for tool in $tools; do
        install_tool "$tool" "Herramienta wireless"
    done
    
    success "Herramientas wireless instaladas"
}

# Instalar herramientas de password cracking
install_password_tools() {
    log "Instalando herramientas de password cracking..."
    
    local tools=""
    case $PKG_MANAGER in
        "apt")
            tools="john hashcat hydra medusa ncrack crunch cewl cupp patator"
            ;;
        "dnf"|"yum")
            tools="john hashcat hydra medusa crunch"
            ;;
        "pacman")
            tools="john hashcat hydra medusa crunch"
            ;;
        "zypper")
            tools="john hashcat hydra crunch"
            ;;
        "apk")
            tools="john hydra crunch"
            ;;
    esac
    
    for tool in $tools; do
        install_tool "$tool" "Herramienta de passwords"
    done
    
    success "Herramientas de password cracking instaladas"
}

# Instalar herramientas forenses
install_forensics_tools() {
    log "Instalando herramientas forenses..."
    
    local tools=""
    case $PKG_MANAGER in
        "apt")
            tools="binwalk foremost autopsy volatility sleuthkit dcfldd ddrescue testdisk"
            ;;
        "dnf"|"yum")
            tools="binwalk foremost sleuthkit testdisk ddrescue"
            ;;
        "pacman")
            tools="binwalk foremost sleuthkit testdisk ddrescue"
            ;;
        "zypper")
            tools="binwalk foremost sleuthkit testdisk"
            ;;
        "apk")
            tools="binwalk foremost testdisk"
            ;;
    esac
    
    for tool in $tools; do
        install_tool "$tool" "Herramienta forense"
    done
    
    success "Herramientas forenses instaladas"
}

# Función genérica para instalar herramientas
install_tool() {
    local tool="$1"
    local description="$2"
    
    if command -v "$tool" >/dev/null 2>&1; then
        info "$tool ya está instalado"
        return 0
    fi
    
    info "Instalando $tool ($description)..."
    if sudo $INSTALL_CMD "$tool" >/dev/null 2>&1; then
        success "$tool instalado correctamente"
    else
        warning "No se pudo instalar $tool, puede no estar disponible en los repositorios"
    fi
}

# Configurar permisos especiales
configure_permissions() {
    log "Configurando permisos especiales..."
    
    local current_user=$(whoami)
    
    # Permitir captura de paquetes sin sudo
    if [ -f /usr/bin/dumpcap ]; then
        sudo setcap cap_net_raw,cap_net_admin=eip /usr/bin/dumpcap
        success "Permisos de captura configurados para dumpcap"
    fi
    
    # Agregar usuario a grupos importantes
    local groups="wireshark dialout plugdev"
    for group in $groups; do
        if getent group "$group" >/dev/null 2>&1; then
            sudo usermod -a -G "$group" "$current_user"
            success "Usuario agregado al grupo $group"
        fi
    done
    
    # Configurar sudoers para herramientas específicas
    configure_sudoers "$current_user"
    
    success "Permisos configurados"
}

# Configurar sudoers
configure_sudoers() {
    local user="$1"
    
    info "Configurando sudoers para herramientas de pentesting..."
    
    cat << EOF | sudo tee /etc/sudoers.d/hackomatic >/dev/null
# Hackomatic sudoers rules - Permitir ejecución sin password
$user ALL=(ALL) NOPASSWD: /usr/bin/airmon-ng
$user ALL=(ALL) NOPASSWD: /usr/bin/airodump-ng
$user ALL=(ALL) NOPASSWD: /usr/bin/aireplay-ng
$user ALL=(ALL) NOPASSWD: /usr/bin/tcpdump
$user ALL=(ALL) NOPASSWD: /usr/sbin/ettercap
$user ALL=(ALL) NOPASSWD: /usr/bin/nmap
$user ALL=(ALL) NOPASSWD: /usr/bin/masscan
$user ALL=(ALL) NOPASSWD: /usr/bin/arp-scan
$user ALL=(ALL) NOPASSWD: /usr/bin/netdiscover
EOF
    
    sudo chmod 0440 /etc/sudoers.d/hackomatic
    success "Reglas de sudoers configuradas"
}

# Crear estructura de directorios
create_directory_structure() {
    log "Creando estructura de directorios..."
    
    local hackomatic_dir="$HOME/.hackomatic"
    local dirs=(
        "$hackomatic_dir"
        "$hackomatic_dir/scripts"
        "$hackomatic_dir/wordlists"
        "$hackomatic_dir/output"
        "$hackomatic_dir/logs"
        "$hackomatic_dir/tools"
        "$hackomatic_dir/payloads"
        "$hackomatic_dir/reports"
        "$hackomatic_dir/exploits"
        "$hackomatic_dir/configs"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
        success "Directorio creado: $dir"
    done
    
    # Crear archivos de configuración
    create_config_files "$hackomatic_dir"
    
    success "Estructura de directorios creada"
}

# Crear archivos de configuración
create_config_files() {
    local hackomatic_dir="$1"
    
    # Archivo de configuración principal
    cat << EOF > "$hackomatic_dir/.hackomaticrc"
# Hackomatic Configuration
# Auto-generated on $(date)

# Directories
export HACKOMATIC_HOME="$hackomatic_dir"
export SCRIPTS_DIR="$hackomatic_dir/scripts"
export OUTPUT_DIR="$hackomatic_dir/output"
export WORDLISTS_DIR="$hackomatic_dir/wordlists"
export LOGS_DIR="$hackomatic_dir/logs"
export TOOLS_DIR="$hackomatic_dir/tools"

# Default settings
export DEFAULT_WORDLIST="$hackomatic_dir/wordlists/common.txt"
export DEFAULT_PORTS="1-10000"
export DEFAULT_THREADS="50"
export DEFAULT_TIMEOUT="30"

# Tool paths (auto-detected)
export NMAP_PATH="$(command -v nmap || echo 'not-found')"
export NIKTO_PATH="$(command -v nikto || echo 'not-found')"
export DIRB_PATH="$(command -v dirb || echo 'not-found')"
export HYDRA_PATH="$(command -v hydra || echo 'not-found')"
export SQLMAP_PATH="$(command -v sqlmap || echo 'not-found')"

# Aliases útiles
alias hn='nmap'
alias hnikto='nikto'
alias hsqlmap='sqlmap'
alias hhydra='hydra'
alias htcpdump='sudo tcpdump'
alias hwireshark='wireshark'

# Functions
function hscan() {
    if [ -z "\$1" ]; then
        echo "Uso: hscan <target>"
        return 1
    fi
    nmap -sS -sV -sC -O "\$1" | tee "\$OUTPUT_DIR/scan-\$(date +%Y%m%d-%H%M%S).txt"
}

function hweb() {
    if [ -z "\$1" ]; then
        echo "Uso: hweb <url>"
        return 1
    fi
    nikto -h "\$1" | tee "\$OUTPUT_DIR/web-\$(date +%Y%m%d-%H%M%S).txt"
}
EOF

    # Agregar configuración a .bashrc/.zshrc
    for rcfile in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ -f "$rcfile" ]; then
            if ! grep -q "hackomatic" "$rcfile"; then
                echo "" >> "$rcfile"
                echo "# Hackomatic configuration" >> "$rcfile"
                echo "[ -f \"$hackomatic_dir/.hackomaticrc\" ] && source \"$hackomatic_dir/.hackomaticrc\"" >> "$rcfile"
                success "Configuración agregada a $rcfile"
            fi
        fi
    done
}

# Descargar wordlists
download_wordlists() {
    log "Descargando wordlists populares..."
    
    local wordlists_dir="$HOME/.hackomatic/wordlists"
    
    # SecLists
    if [ ! -d "$wordlists_dir/SecLists" ]; then
        info "Descargando SecLists..."
        git clone https://github.com/danielmiessler/SecLists.git "$wordlists_dir/SecLists" || warning "Error descargando SecLists"
    fi
    
    # FuzzDB
    if [ ! -d "$wordlists_dir/fuzzdb" ]; then
        info "Descargando FuzzDB..."
        git clone https://github.com/fuzzdb-project/fuzzdb.git "$wordlists_dir/fuzzdb" || warning "Error descargando FuzzDB"
    fi
    
    # Copiar wordlists del sistema si existen
    copy_system_wordlists "$wordlists_dir"
    
    # Crear wordlist común básica
    create_basic_wordlist "$wordlists_dir"
    
    success "Wordlists configuradas"
}

# Copiar wordlists del sistema
copy_system_wordlists() {
    local dest_dir="$1"
    local system_paths=(
        "/usr/share/wordlists"
        "/usr/share/dirb/wordlists"
        "/usr/share/dirbuster/wordlists"
        "/usr/share/wfuzz/wordlist"
    )
    
    for path in "${system_paths[@]}"; do
        if [ -d "$path" ]; then
            cp -r "$path" "$dest_dir/" 2>/dev/null || true
            success "Wordlists copiadas desde $path"
        fi
    done
}

# Crear wordlist básica
create_basic_wordlist() {
    local wordlists_dir="$1"
    
    cat << 'EOF' > "$wordlists_dir/common.txt"
admin
administrator
root
test
guest
user
login
password
123456
admin123
root123
test123
index
home
main
default
common
backup
old
new
temp
temporary
config
configuration
setup
install
data
files
images
uploads
downloads
documents
www
web
site
app
application
api
service
services
system
systems
EOF
    
    success "Wordlist básica creada"
}

# Instalar herramientas adicionales especializadas
install_specialized_tools() {
    log "Instalando herramientas especializadas..."
    
    # Instalar Go (necesario para muchas herramientas modernas)
    install_go
    
    # Instalar herramientas de Go
    install_go_tools
    
    # Instalar herramientas de Python adicionales
    install_python_tools
    
    # Configurar Metasploit si está disponible
    configure_metasploit
    
    success "Herramientas especializadas instaladas"
}

# Instalar Go
install_go() {
    if command -v go >/dev/null 2>&1; then
        info "Go ya está instalado"
        return 0
    fi
    
    info "Instalando Go..."
    
    case $PKG_MANAGER in
        "apt")
            sudo $INSTALL_CMD golang-go
            ;;
        "dnf"|"yum")
            sudo $INSTALL_CMD golang
            ;;
        "pacman")
            sudo $INSTALL_CMD go
            ;;
        "zypper")
            sudo $INSTALL_CMD go
            ;;
        *)
            warning "Instalación manual de Go requerida para $PKG_MANAGER"
            return 1
            ;;
    esac
    
    success "Go instalado"
}

# Instalar herramientas de Go
install_go_tools() {
    if ! command -v go >/dev/null 2>&1; then
        warning "Go no disponible, saltando herramientas de Go"
        return 1
    fi
    
    info "Instalando herramientas de Go..."
    
    local go_tools=(
        "github.com/ffuf/ffuf/v2@latest"
        "github.com/OJ/gobuster/v3@latest"
        "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
        "github.com/projectdiscovery/httpx/cmd/httpx@latest"
        "github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest"
        "github.com/tomnomnom/waybackurls@latest"
        "github.com/tomnomnom/httprobe@latest"
    )
    
    for tool in "${go_tools[@]}"; do
        info "Instalando $(basename "$tool")..."
        go install "$tool" || warning "Error instalando $tool"
    done
    
    success "Herramientas de Go instaladas"
}

# Instalar herramientas de Python adicionales
install_python_tools() {
    info "Instalando herramientas de Python adicionales..."
    
    local python_tools=(
        "dirsearch"
        "sublist3r"
        "wfuzz"
        "commix"
        "xsser"
        "linkfinder"
        "paramspider"
        "arjun"
        "photon"
        "cloudfail"
        "dnsgen"
        "altdns"
    )
    
    for tool in "${python_tools[@]}"; do
        info "Instalando $tool..."
        python3 -m pip install --user "$tool" || warning "Error instalando $tool"
    done
    
    success "Herramientas de Python instaladas"
}

# Configurar Metasploit
configure_metasploit() {
    if ! command -v msfconsole >/dev/null 2>&1; then
        info "Metasploit no disponible, saltando configuración"
        return 1
    fi
    
    info "Configurando Metasploit..."
    
    # Inicializar base de datos
    sudo msfdb init || warning "Error inicializando base de datos de Metasploit"
    
    success "Metasploit configurado"
}

# Verificar instalación
verify_installation() {
    log "Verificando instalación..."
    
    local tools=(
        "nmap:Network scanner"
        "nikto:Web scanner"
        "sqlmap:SQL injection tool"
        "hydra:Password cracker"
        "aircrack-ng:WiFi security tool"
        "wireshark:Network analyzer"
        "tcpdump:Packet analyzer"
        "john:Password cracker"
        "hashcat:Password recovery"
    )
    
    local installed=0
    local total=${#tools[@]}
    
    echo ""
    echo -e "${CYAN}=== Verificación de Herramientas ===${NC}"
    
    for tool_info in "${tools[@]}"; do
        local tool=$(echo "$tool_info" | cut -d: -f1)
        local description=$(echo "$tool_info" | cut -d: -f2)
        
        if command -v "$tool" >/dev/null 2>&1; then
            success "$tool ($description)"
            ((installed++))
        else
            error "$tool ($description)"
        fi
    done
    
    echo ""
    echo -e "${BLUE}Herramientas instaladas: $installed/$total${NC}"
    
    if [ $installed -eq $total ]; then
        success "¡Todas las herramientas principales están instaladas!"
    else
        warning "Algunas herramientas no se pudieron instalar"
    fi
}

# Mostrar resumen final
show_summary() {
    clear
    echo -e "${GREEN}"
    cat << "EOF"
 ✅ ¡INSTALACIÓN COMPLETADA! ✅

 🎉 Hackomatic está listo para usar
 🐧 Tu sistema Linux está configurado
 🔧 Todas las herramientas están instaladas
 ⚡ Scripts automáticos disponibles
EOF
    echo -e "${NC}"
    
    echo -e "${CYAN}Próximos pasos:${NC}"
    echo -e "${YELLOW}1. Reinicia tu terminal o ejecuta: source ~/.bashrc${NC}"
    echo -e "${YELLOW}2. Ejecuta la app Hackomatic${NC}"
    echo -e "${YELLOW}3. Explora los scripts automáticos${NC}"
    echo -e "${YELLOW}4. Revisa la configuración en ~/.hackomatic/${NC}"
    echo ""
    
    echo -e "${PURPLE}Comandos útiles:${NC}"
    echo -e "${GREEN}• hscan <target>     ${NC}- Escanear objetivo"
    echo -e "${GREEN}• hweb <url>         ${NC}- Análisis web"
    echo -e "${GREEN}• cd ~/.hackomatic   ${NC}- Ir al directorio de trabajo"
    echo ""
    
    echo -e "${BLUE}¡Happy Hacking! ${ROBOT}${NC}"
}

# Función principal
main() {
    show_banner
    
    # Verificar si se ejecuta como root
    if [ "$EUID" -eq 0 ]; then
        error "No ejecutes este script como root"
        exit 1
    fi
    
    # Verificar conexión a internet
    if ! ping -c 1 google.com >/dev/null 2>&1; then
        error "No hay conexión a internet"
        exit 1
    fi
    
    # Proceso principal
    detect_distro
    detect_package_manager
    update_system
    install_dependencies
    install_network_tools
    install_web_tools
    install_wireless_tools
    install_password_tools
    install_forensics_tools
    configure_permissions
    create_directory_structure
    download_wordlists
    install_specialized_tools
    verify_installation
    show_summary
    
    success "¡Setup completado exitosamente!"
}

# Manejo de señales
trap 'error "Script interrumpido"; exit 1' INT TERM

# Ejecutar si se llama directamente
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
