import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkDetectionService {
  static final NetworkDetectionService _instance =
      NetworkDetectionService._internal();
  factory NetworkDetectionService() => _instance;
  NetworkDetectionService._internal();

  final NetworkInfo _networkInfo = NetworkInfo();

  // Platform detection
  bool get isAndroid => Platform.isAndroid;
  bool get isLinux => Platform.isLinux;
  bool get isDesktop =>
      Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  // Auto-detectar IP local con soporte Android/Linux
  Future<String> getLocalIP() async {
    try {
      // Método principal: network_info_plus
      final wifiIP = await _networkInfo.getWifiIP();
      if (wifiIP != null && wifiIP.isNotEmpty && wifiIP != '0.0.0.0') {
        return wifiIP;
      }

      // Método alternativo: NetworkInterface
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 &&
              !addr.isLoopback &&
              !addr.address.startsWith('169.254')) {
            // Evitar APIPA

            // Priorizar IPs de redes privadas
            if (addr.address.startsWith('192.168.') ||
                addr.address.startsWith('10.') ||
                (addr.address.startsWith('172.') &&
                    int.parse(addr.address.split('.')[1]) >= 16 &&
                    int.parse(addr.address.split('.')[1]) <= 31)) {
              return addr.address;
            }
          }
        }
      }

      // Android: usar método específico de plataforma
      if (isAndroid) {
        return await _getAndroidLocalIP();
      }

      // Linux: usar comando de sistema
      if (isLinux) {
        return await _getLinuxLocalIP();
      }

      return '192.168.1.100'; // Fallback por defecto
    } catch (e) {
      print('Error detecting local IP: $e');
      return '192.168.1.100';
    }
  }

  // Método específico para Android
  Future<String> _getAndroidLocalIP() async {
    try {
      // Intentar con comando ifconfig en Android
      final result = await Process.run('sh', ['-c', 'ip route get 1.1.1.1']);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final match = RegExp(r'src (\d+\.\d+\.\d+\.\d+)').firstMatch(output);
        if (match != null) {
          return match.group(1)!;
        }
      }

      // Fallback: buscar en /proc/net/route (Android)
      final routeResult = await Process.run('cat', ['/proc/net/route']);
      if (routeResult.exitCode == 0) {
        // Implementar parsing de tabla de rutas si es necesario
      }

      return '192.168.1.100';
    } catch (e) {
      return '192.168.1.100';
    }
  }

  // Método específico para Linux
  Future<String> _getLinuxLocalIP() async {
    try {
      // Método 1: ip route get
      var result = await Process.run('ip', ['route', 'get', '1.1.1.1']);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final match = RegExp(r'src (\d+\.\d+\.\d+\.\d+)').firstMatch(output);
        if (match != null) {
          return match.group(1)!;
        }
      }

      // Método 2: hostname -I
      result = await Process.run('hostname', ['-I']);
      if (result.exitCode == 0) {
        final ips = result.stdout.toString().trim().split(' ');
        for (final ip in ips) {
          if (ip.contains('.') && !ip.startsWith('127.')) {
            return ip;
          }
        }
      }

      return '192.168.1.100';
    } catch (e) {
      return '192.168.1.100';
    }
  }

  // Auto-detectar red local (CIDR)
  Future<String> getLocalNetwork() async {
    try {
      final localIP = await getLocalIP();
      final parts = localIP.split('.');
      if (parts.length >= 3) {
        return '${parts[0]}.${parts[1]}.${parts[2]}.0/24';
      }
      return '192.168.1.0/24';
    } catch (e) {
      return '192.168.1.0/24';
    }
  }

  // Auto-detectar gateway con soporte Android/Linux
  Future<String> getGatewayIP() async {
    try {
      // Método principal: network_info_plus
      final gateway = await _networkInfo.getWifiGatewayIP();
      if (gateway != null && gateway.isNotEmpty && gateway != '0.0.0.0') {
        return gateway;
      }

      // Android: método específico
      if (isAndroid) {
        return await _getAndroidGateway();
      }

      // Linux: método específico
      if (isLinux) {
        return await _getLinuxGateway();
      }

      // Fallback: asumir que el gateway es .1
      final localIP = await getLocalIP();
      final parts = localIP.split('.');
      if (parts.length >= 3) {
        return '${parts[0]}.${parts[1]}.${parts[2]}.1';
      }
      return '192.168.1.1';
    } catch (e) {
      print('Error detecting gateway: $e');
      return '192.168.1.1';
    }
  }

  // Gateway específico para Android
  Future<String> _getAndroidGateway() async {
    try {
      // Método 1: ip route (disponible en Android moderno)
      var result = await Process.run('sh', ['-c', 'ip route | grep default']);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final match = RegExp(
          r'default via (\d+\.\d+\.\d+\.\d+)',
        ).firstMatch(output);
        if (match != null) {
          return match.group(1)!;
        }
      }

      // Método 2: getprop (Android específico)
      result = await Process.run('getprop', ['dhcp.wlan0.gateway']);
      if (result.exitCode == 0) {
        final gateway = result.stdout.toString().trim();
        if (gateway.isNotEmpty && gateway.contains('.')) {
          return gateway;
        }
      }

      // Fallback basado en IP local
      final localIP = await getLocalIP();
      final parts = localIP.split('.');
      if (parts.length >= 3) {
        return '${parts[0]}.${parts[1]}.${parts[2]}.1';
      }
      return '192.168.1.1';
    } catch (e) {
      return '192.168.1.1';
    }
  }

  // Gateway específico para Linux
  Future<String> _getLinuxGateway() async {
    try {
      // Método 1: ip route
      var result = await Process.run('ip', ['route', 'show', 'default']);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final match = RegExp(
          r'default via (\d+\.\d+\.\d+\.\d+)',
        ).firstMatch(output);
        if (match != null) {
          return match.group(1)!;
        }
      }

      // Método 2: route command (fallback)
      result = await Process.run('route', ['-n']);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        for (final line in lines) {
          if (line.startsWith('0.0.0.0')) {
            final parts = line.split(RegExp(r'\s+'));
            if (parts.length > 1) {
              return parts[1];
            }
          }
        }
      }

      return '192.168.1.1';
    } catch (e) {
      return '192.168.1.1';
    }
  }

  // Auto-detectar interfaz WiFi principal (Android/Linux)
  Future<String> getWifiInterface() async {
    try {
      if (isAndroid) {
        return await _getAndroidWifiInterface();
      } else if (isLinux) {
        return await _getLinuxWifiInterface();
      }

      return 'wlan0'; // Fallback más común
    } catch (e) {
      print('Error detecting WiFi interface: $e');
      return 'wlan0';
    }
  }

  // WiFi interface específico para Android
  Future<String> _getAndroidWifiInterface() async {
    try {
      // Android típicamente usa wlan0
      final interfaces = await NetworkInterface.list();

      for (var interface in interfaces) {
        final name = interface.name.toLowerCase();
        if (name == 'wlan0' || name == 'wlan1') {
          return interface.name;
        }
      }

      // Verificar con getprop
      final result = await Process.run('getprop', ['wifi.interface']);
      if (result.exitCode == 0) {
        final wifiInterface = result.stdout.toString().trim();
        if (wifiInterface.isNotEmpty) {
          return wifiInterface;
        }
      }

      return 'wlan0';
    } catch (e) {
      return 'wlan0';
    }
  }

  // WiFi interface específico para Linux
  Future<String> _getLinuxWifiInterface() async {
    try {
      // Buscar interfaces inalámbricas comunes en Linux
      final interfaces = await NetworkInterface.list();

      for (var interface in interfaces) {
        final name = interface.name.toLowerCase();
        if (name.contains('wlan') ||
            name.contains('wifi') ||
            name.contains('wlp')) {
          return interface.name;
        }
      }

      // Verificar con iwconfig
      final result = await Process.run('iwconfig', []);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final lines = output.split('\n');
        for (var line in lines) {
          if (line.contains('IEEE 802.11')) {
            final interfaceName = line.split(' ')[0];
            if (interfaceName.isNotEmpty) {
              return interfaceName;
            }
          }
        }
      }

      // Verificar con iw
      final iwResult = await Process.run('iw', ['dev']);
      if (iwResult.exitCode == 0) {
        final output = iwResult.stdout.toString();
        final match = RegExp(r'Interface (\w+)').firstMatch(output);
        if (match != null) {
          return match.group(1)!;
        }
      }

      return 'wlan0';
    } catch (e) {
      return 'wlan0';
    }
  }

  // Auto-detectar interfaz Ethernet principal (Android/Linux)
  Future<String> getEthernetInterface() async {
    try {
      if (isAndroid) {
        return await _getAndroidEthernetInterface();
      } else if (isLinux) {
        return await _getLinuxEthernetInterface();
      }

      return 'eth0'; // Fallback
    } catch (e) {
      print('Error detecting Ethernet interface: $e');
      return 'eth0';
    }
  }

  // Ethernet interface específico para Android
  Future<String> _getAndroidEthernetInterface() async {
    try {
      final interfaces = await NetworkInterface.list();

      for (var interface in interfaces) {
        final name = interface.name.toLowerCase();
        if (name.contains('eth') ||
            name.contains('rmnet') ||
            name.contains('ccmni')) {
          return interface.name;
        }
      }

      return 'eth0';
    } catch (e) {
      return 'eth0';
    }
  }

  // Ethernet interface específico para Linux
  Future<String> _getLinuxEthernetInterface() async {
    try {
      final interfaces = await NetworkInterface.list();

      for (var interface in interfaces) {
        final name = interface.name.toLowerCase();
        if (name.contains('eth') ||
            name.contains('enp') ||
            name.contains('eno') ||
            name.contains('ens')) {
          return interface.name;
        }
      }

      return 'eth0';
    } catch (e) {
      return 'eth0';
    }
  }

  // Detectar si hay conexión WiFi activa
  Future<bool> isWifiConnected() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult.contains(ConnectivityResult.wifi);
    } catch (e) {
      return false;
    }
  }

  // Auto-detectar rango de puertos comunes para escanear
  String getCommonPortRange() {
    return '1-1000,3389,5432,5900,8080,8443,9090';
  }

  // Auto-detectar wordlist común (Android/Linux)
  Future<String> getCommonWordlist() async {
    List<String> commonPaths;

    if (isAndroid) {
      // Android paths (usando almacenamiento de la app o externo)
      commonPaths = [
        '/sdcard/hackomatic/wordlists/common.txt',
        '/data/data/com.example.hackomatic/files/wordlists/common.txt',
        '/android_asset/wordlists/common.txt',
        './assets/wordlists/common.txt',
      ];
    } else {
      // Linux paths
      commonPaths = [
        '/usr/share/wordlists/dirb/common.txt',
        '/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt',
        '/usr/share/seclists/Discovery/Web-Content/common.txt',
        '/opt/SecLists/Discovery/Web-Content/common.txt',
        '/usr/share/wordlists/rockyou.txt',
        './wordlists/common.txt',
        '~/wordlists/common.txt',
      ];
    }

    for (final path in commonPaths) {
      try {
        if (await File(path).exists()) {
          return path;
        }
      } catch (e) {
        // Continue to next path
      }
    }

    // Return platform-appropriate fallback
    return isAndroid
        ? './assets/wordlists/common.txt'
        : '/usr/share/wordlists/dirb/common.txt';
  }

  // Auto-detectar URL objetivo común
  Future<String> getCommonTarget() async {
    final gateway = await getGatewayIP();
    return 'http://$gateway'; // Router como objetivo por defecto
  }

  // Detectar si estamos en una red corporativa o doméstica
  Future<String> getNetworkType() async {
    try {
      final localIP = await getLocalIP();

      if (localIP.startsWith('192.168.')) {
        return 'home'; // Red doméstica
      } else if (localIP.startsWith('10.') || localIP.startsWith('172.')) {
        return 'corporate'; // Red corporativa
      }

      return 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  // Auto-configurar parámetros para diferentes tipos de escaneo
  Future<Map<String, String>> getAutoScanConfig() async {
    final localIP = await getLocalIP();
    final network = await getLocalNetwork();
    final gateway = await getGatewayIP();
    final wifiInterface = await getWifiInterface();
    final ethInterface = await getEthernetInterface();
    final isWifi = await isWifiConnected();

    return {
      'local_ip': localIP,
      'network_range': network,
      'gateway': gateway,
      'wifi_interface': wifiInterface,
      'ethernet_interface': ethInterface,
      'active_interface': isWifi ? wifiInterface : ethInterface,
      'port_range': getCommonPortRange(),
      'target_url': await getCommonTarget(),
      'wordlist_path': await getCommonWordlist(),
      'network_type': await getNetworkType(),
    };
  }

  // Generar comandos pre-configurados específicos por plataforma
  Future<Map<String, String>> getPreConfiguredCommands() async {
    final config = await getAutoScanConfig();

    if (isAndroid) {
      // Comandos optimizados para Android
      return {
        'network_scan': 'nmap -sn ${config['network_range']}',
        'port_scan': 'nmap -sS -p ${config['port_range']} ${config['gateway']}',
        'wifi_scan': 'iwlist ${config['wifi_interface']} scan',
        'ping_gateway': 'ping -c 4 ${config['gateway']}',
        'simple_scan': 'nmap -F ${config['gateway']}', // Fast scan
        'connectivity_test': 'ping -c 3 8.8.8.8',
        'local_services': 'netstat -tuln',
        'route_info': 'ip route',
      };
    } else {
      // Comandos completos para Linux
      return {
        'network_scan': 'nmap -sn ${config['network_range']}',
        'port_scan': 'nmap -sS -p ${config['port_range']} ${config['gateway']}',
        'wifi_scan': 'iwlist ${config['wifi_interface']} scan',
        'arp_scan': 'arp-scan ${config['network_range']}',
        'ping_gateway': 'ping -c 4 ${config['gateway']}',
        'stealth_scan': 'nmap -sS -O ${config['gateway']}',
        'vuln_scan': 'nmap --script vuln ${config['gateway']}',
        'service_detection': 'nmap -sV ${config['gateway']}',
        'udp_scan': 'nmap -sU --top-ports 100 ${config['gateway']}',
        'discovery_scan': 'nmap -sC ${config['gateway']}',
      };
    }
  }

  // Obtener herramientas disponibles por plataforma
  Future<Map<String, bool>> getAvailableTools() async {
    final tools = <String, bool>{};

    final toolsToCheck = isAndroid
        ? ['ping', 'nmap', 'netstat', 'ip'] // Herramientas básicas en Android
        : [
            'ping',
            'nmap',
            'arp-scan',
            'iwlist',
            'iwconfig',
            'netstat',
            'ss',
            'dig',
            'nslookup',
          ];

    for (final tool in toolsToCheck) {
      try {
        final result = await Process.run('which', [tool]);
        tools[tool] = result.exitCode == 0;
      } catch (e) {
        tools[tool] = false;
      }
    }

    return tools;
  }

  // Verificar permisos requeridos
  Future<Map<String, bool>> checkRequiredPermissions() async {
    final permissions = <String, bool>{};

    if (isAndroid) {
      // Android permissions (estos se verificarían con permission_handler)
      permissions['INTERNET'] = true; // Asumimos que está concedido
      permissions['ACCESS_NETWORK_STATE'] = true;
      permissions['ACCESS_WIFI_STATE'] = true;
      permissions['CHANGE_WIFI_STATE'] = false; // Requiere verificación
      permissions['ACCESS_FINE_LOCATION'] = false; // Para WiFi scanning
    } else {
      // Linux capabilities
      try {
        // Verificar si puede ejecutar comandos de red
        final pingResult = await Process.run('ping', ['-c', '1', '127.0.0.1']);
        permissions['PING'] = pingResult.exitCode == 0;

        // Verificar si puede ejecutar nmap
        final nmapResult = await Process.run('nmap', ['--version']);
        permissions['NMAP'] = nmapResult.exitCode == 0;

        // Verificar si tiene permisos para raw sockets (para SYN scan)
        final rawSocketTest = await Process.run('nmap', ['-sS', '127.0.0.1']);
        permissions['RAW_SOCKETS'] = rawSocketTest.exitCode == 0;
      } catch (e) {
        permissions['PING'] = false;
        permissions['NMAP'] = false;
        permissions['RAW_SOCKETS'] = false;
      }
    }

    return permissions;
  }

  // Obtener información completa del sistema
  Future<Map<String, dynamic>> getSystemInfo() async {
    final info = <String, dynamic>{};

    info['platform'] = Platform.operatingSystem;
    info['version'] = Platform.operatingSystemVersion;
    info['is_android'] = isAndroid;
    info['is_linux'] = isLinux;
    info['is_desktop'] = isDesktop;

    // Información de red
    final networkConfig = await getAutoScanConfig();
    info['network'] = networkConfig;

    // Herramientas disponibles
    info['available_tools'] = await getAvailableTools();

    // Permisos
    info['permissions'] = await checkRequiredPermissions();

    // Información adicional de Android
    if (isAndroid) {
      try {
        final androidVersionResult = await Process.run('getprop', [
          'ro.build.version.release',
        ]);
        if (androidVersionResult.exitCode == 0) {
          info['android_version'] = androidVersionResult.stdout
              .toString()
              .trim();
        }

        final deviceModelResult = await Process.run('getprop', [
          'ro.product.model',
        ]);
        if (deviceModelResult.exitCode == 0) {
          info['device_model'] = deviceModelResult.stdout.toString().trim();
        }
      } catch (e) {
        // Not critical
      }
    }

    return info;
  }
}
