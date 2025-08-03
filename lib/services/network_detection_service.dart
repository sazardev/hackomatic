import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkDetectionService {
  static final NetworkDetectionService _instance =
      NetworkDetectionService._internal();
  factory NetworkDetectionService() => _instance;
  NetworkDetectionService._internal();

  final NetworkInfo _networkInfo = NetworkInfo();

  // Auto-detectar IP local
  Future<String> getLocalIP() async {
    try {
      final wifiIP = await _networkInfo.getWifiIP();
      if (wifiIP != null && wifiIP.isNotEmpty) {
        return wifiIP;
      }

      // Fallback: buscar IP a través de interfaces de red
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }

      return '192.168.1.100'; // Fallback por defecto
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

  // Auto-detectar gateway
  Future<String> getGatewayIP() async {
    try {
      final gateway = await _networkInfo.getWifiGatewayIP();
      if (gateway != null && gateway.isNotEmpty) {
        return gateway;
      }

      // Fallback: asumir que el gateway es .1
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

  // Auto-detectar interfaz WiFi principal
  Future<String> getWifiInterface() async {
    try {
      // Buscar interfaces inalámbricas comunes
      final interfaces = await NetworkInterface.list();

      for (var interface in interfaces) {
        final name = interface.name.toLowerCase();
        if (name.contains('wlan') ||
            name.contains('wifi') ||
            name.contains('wlp')) {
          return interface.name;
        }
      }

      // Verificar si wlan0 existe directamente
      final result = await Process.run('iwconfig', []);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        if (output.contains('wlan0')) return 'wlan0';
        if (output.contains('wlan1')) return 'wlan1';
        if (output.contains('wlp')) {
          final lines = output.split('\n');
          for (var line in lines) {
            if (line.contains('IEEE 802.11')) {
              return line.split(' ')[0];
            }
          }
        }
      }

      return 'wlan0'; // Fallback más común
    } catch (e) {
      return 'wlan0';
    }
  }

  // Auto-detectar interfaz Ethernet principal
  Future<String> getEthernetInterface() async {
    try {
      final interfaces = await NetworkInterface.list();

      for (var interface in interfaces) {
        final name = interface.name.toLowerCase();
        if (name.contains('eth') ||
            name.contains('enp') ||
            name.contains('eno')) {
          return interface.name;
        }
      }

      return 'eth0'; // Fallback
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

  // Auto-detectar wordlist común
  Future<String> getCommonWordlist() async {
    final commonPaths = [
      '/usr/share/wordlists/dirb/common.txt',
      '/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt',
      '/usr/share/seclists/Discovery/Web-Content/common.txt',
      '/opt/SecLists/Discovery/Web-Content/common.txt',
      './wordlists/common.txt',
    ];

    for (final path in commonPaths) {
      if (await File(path).exists()) {
        return path;
      }
    }

    return '/usr/share/wordlists/dirb/common.txt'; // Fallback
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

  // Generar comandos pre-configurados
  Future<Map<String, String>> getPreConfiguredCommands() async {
    final config = await getAutoScanConfig();

    return {
      'network_scan': 'nmap -sn ${config['network_range']}',
      'port_scan': 'nmap -sS -p ${config['port_range']} ${config['gateway']}',
      'wifi_scan': 'iwlist ${config['wifi_interface']} scan',
      'arp_scan': 'arp-scan ${config['network_range']}',
      'ping_gateway': 'ping -c 4 ${config['gateway']}',
    };
  }
}
