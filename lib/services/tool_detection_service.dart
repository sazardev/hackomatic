import 'dart:io';

class ToolDetectionService {
  static final ToolDetectionService _instance =
      ToolDetectionService._internal();
  factory ToolDetectionService() => _instance;
  ToolDetectionService._internal();

  final Map<String, bool> _installationCache = {};

  Future<bool> isToolInstalled(String command) async {
    if (_installationCache.containsKey(command)) {
      return _installationCache[command]!;
    }

    try {
      // Try to run the command with --version or --help
      final result = await Process.run('which', [command]);
      final isInstalled = result.exitCode == 0;

      _installationCache[command] = isInstalled;
      return isInstalled;
    } catch (e) {
      _installationCache[command] = false;
      return false;
    }
  }

  Future<Map<String, bool>> checkMultipleTools(List<String> commands) async {
    final results = <String, bool>{};

    for (final command in commands) {
      results[command] = await isToolInstalled(command);
    }

    return results;
  }

  Future<String?> getToolVersion(String command) async {
    if (!await isToolInstalled(command)) {
      return null;
    }

    try {
      // Try common version flags
      for (final flag in ['--version', '-v', '-V', 'version']) {
        try {
          final result = await Process.run(command, [flag]);
          if (result.exitCode == 0 && result.stdout.toString().isNotEmpty) {
            return result.stdout.toString().trim().split('\n').first;
          }
        } catch (e) {
          continue;
        }
      }
      return 'Unknown version';
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> getInstalledHackingTools() async {
    const commonTools = [
      'nmap',
      'netcat',
      'nc',
      'aircrack-ng',
      'hydra',
      'sqlmap',
      'gobuster',
      'nikto',
      'dirb',
      'wpscan',
      'metasploit',
      'msfconsole',
      'burpsuite',
      'wireshark',
      'tcpdump',
      'hashcat',
      'john',
      'recon-ng',
      'theharvester',
      'amass',
      'subfinder',
      'masscan',
      'zap',
      'curl',
      'wget',
      'dig',
      'nslookup',
      'ping',
      'traceroute',
      'arp-scan',
      'maltego',
    ];

    final installedTools = <String>[];

    for (final tool in commonTools) {
      if (await isToolInstalled(tool)) {
        installedTools.add(tool);
      }
    }

    return installedTools;
  }

  Future<Map<String, String>> getSystemInfo() async {
    final info = <String, String>{};

    try {
      // Get OS information
      final osResult = await Process.run('uname', ['-a']);
      if (osResult.exitCode == 0) {
        info['os'] = osResult.stdout.toString().trim();
      }

      // Get kernel version
      final kernelResult = await Process.run('uname', ['-r']);
      if (kernelResult.exitCode == 0) {
        info['kernel'] = kernelResult.stdout.toString().trim();
      }

      // Check if running as root
      final whoamiResult = await Process.run('whoami', []);
      if (whoamiResult.exitCode == 0) {
        info['user'] = whoamiResult.stdout.toString().trim();
        info['isRoot'] = info['user'] == 'root' ? 'Yes' : 'No';
      }

      // Check available shell
      final shellResult = await Process.run('echo', ['\$SHELL']);
      if (shellResult.exitCode == 0) {
        info['shell'] = shellResult.stdout.toString().trim();
      }
    } catch (e) {
      info['error'] = 'Failed to get system info: $e';
    }

    return info;
  }

  Future<Map<String, String>> getAutoDetectedNetworkInfo() async {
    final info = <String, String>{};

    try {
      // Get local IP address
      final ipResult = await Process.run('hostname', ['-I']);
      if (ipResult.exitCode == 0) {
        final ips = ipResult.stdout.toString().trim().split(' ');
        final localIp = ips.firstWhere(
          (ip) =>
              ip.startsWith('192.168.') ||
              ip.startsWith('10.') ||
              ip.startsWith('172.'),
          orElse: () => ips.first,
        );
        info['local_ip'] = localIp;

        // Calculate network range from local IP
        final parts = localIp.split('.');
        if (parts.length >= 3) {
          info['network_range'] = '${parts[0]}.${parts[1]}.${parts[2]}.0/24';
        }
      }

      // Get default gateway
      final routeResult = await Process.run('ip', ['route', 'show', 'default']);
      if (routeResult.exitCode == 0) {
        final output = routeResult.stdout.toString();
        final match = RegExp(
          r'default via (\d+\.\d+\.\d+\.\d+)',
        ).firstMatch(output);
        if (match != null) {
          info['gateway'] = match.group(1)!;
        }
      }

      // Get wireless interfaces
      final interfaces = await getNetworkInterfaces();
      final wifiInterface = interfaces.firstWhere(
        (iface) => iface.startsWith('wl') || iface.contains('wifi'),
        orElse: () => interfaces.isNotEmpty ? interfaces.first : 'wlan0',
      );
      info['wifi_interface'] = wifiInterface;

      // Get ethernet interface
      final ethInterface = interfaces.firstWhere(
        (iface) => iface.startsWith('eth') || iface.startsWith('en'),
        orElse: () => 'eth0',
      );
      info['ethernet_interface'] = ethInterface;
    } catch (e) {
      // Fallback values
      info['local_ip'] = '192.168.1.100';
      info['network_range'] = '192.168.1.0/24';
      info['gateway'] = '192.168.1.1';
      info['wifi_interface'] = 'wlan0';
      info['ethernet_interface'] = 'eth0';
    }

    return info;
  }

  Future<String> getRandomTarget() async {
    final networkInfo = await getAutoDetectedNetworkInfo();
    final networkRange = networkInfo['network_range'] ?? '192.168.1.0/24';
    final parts = networkRange.split('.').sublist(0, 3);
    final baseNetwork = '${parts[0]}.${parts[1]}.${parts[2]}';

    // Return a random IP in the same network (avoiding .1 which is usually gateway)
    final randomHost = 10 + (DateTime.now().millisecond % 240);
    return '$baseNetwork.$randomHost';
  }

  void clearCache() {
    _installationCache.clear();
  }

  Future<bool> hasRootAccess() async {
    try {
      final result = await Process.run('sudo', ['-n', 'true']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> getNetworkInterfaces() async {
    try {
      final result = await Process.run('ip', ['link', 'show']);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final interfaces = <String>[];

        for (final line in output.split('\n')) {
          if (line.contains(': ') && !line.contains('lo:')) {
            final parts = line.split(': ');
            if (parts.length > 1) {
              final interfaceName = parts[1].split('@')[0];
              if (!interfaces.contains(interfaceName)) {
                interfaces.add(interfaceName);
              }
            }
          }
        }

        return interfaces;
      }
    } catch (e) {
      // Fallback to iwconfig for wireless interfaces
      try {
        final iwResult = await Process.run('iwconfig', []);
        if (iwResult.exitCode == 0) {
          final output = iwResult.stdout.toString();
          final interfaces = <String>[];

          for (final line in output.split('\n')) {
            if (line.contains('IEEE 802.11')) {
              final interfaceName = line.split(' ')[0];
              interfaces.add(interfaceName);
            }
          }

          return interfaces;
        }
      } catch (e) {
        // Ignore
      }
    }

    return ['wlan0', 'eth0']; // Default fallback
  }
}
