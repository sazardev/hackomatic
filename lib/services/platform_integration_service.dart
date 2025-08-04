import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'network_detection_service.dart';
import 'dart:developer' as dev;

/// Servicio de integración específico por plataforma
/// Maneja la configuración automática y preparación del entorno
/// para Android y Linux
class PlatformIntegrationService {
  static final PlatformIntegrationService _instance =
      PlatformIntegrationService._internal();
  factory PlatformIntegrationService() => _instance;
  PlatformIntegrationService._internal();

  final NetworkDetectionService _networkService = NetworkDetectionService();

  // Platform detection
  bool get isAndroid => Platform.isAndroid;
  bool get isLinux => Platform.isLinux;
  bool get isDesktop =>
      Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  /// Inicializar el servicio según la plataforma
  Future<bool> initialize() async {
    try {
      if (isAndroid) {
        return await _initializeAndroid();
      } else if (isLinux) {
        return await _initializeLinux();
      }
      return true;
    } catch (e) {
      dev.log('Error initializing platform integration: $e');
      return false;
    }
  }

  /// Inicialización específica para Android
  Future<bool> _initializeAndroid() async {
    try {
      // 1. Preparar directorios necesarios
      await _setupAndroidDirectories();

      // 2. Copiar scripts a ubicación accesible
      await _copyScriptsToAndroid();

      // 3. Verificar herramientas disponibles
      final tools = await _networkService.getAvailableTools();
      dev.log('Android tools available: $tools');

      // 4. Configurar variables de entorno
      await _setupAndroidEnvironment();

      return true;
    } catch (e) {
      dev.log('Android initialization error: $e');
      return false;
    }
  }

  /// Inicialización específica para Linux
  Future<bool> _initializeLinux() async {
    try {
      // 1. Verificar herramientas de hacking disponibles
      final tools = await _networkService.getAvailableTools();
      dev.log('Linux tools available: $tools');

      // 2. Verificar permisos
      final permissions = await _networkService.checkRequiredPermissions();
      dev.log('Linux permissions: $permissions');

      // 3. Preparar directorio de trabajo
      await _setupLinuxDirectories();

      return true;
    } catch (e) {
      dev.log('Linux initialization error: $e');
      return false;
    }
  }

  /// Configurar directorios para Android
  Future<void> _setupAndroidDirectories() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();

      final directories = [
        '${appDocDir.path}/scripts',
        '${appDocDir.path}/output',
        '${appDocDir.path}/wordlists',
        '${appDocDir.path}/logs',
      ];

      for (final dirPath in directories) {
        final dir = Directory(dirPath);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
          dev.log('Created Android directory: $dirPath');
        }
      }
    } catch (e) {
      dev.log('Error setting up Android directories: $e');
    }
  }

  /// Configurar directorios para Linux
  Future<void> _setupLinuxDirectories() async {
    try {
      final homeDir = Platform.environment['HOME'] ?? '/home/user';
      final hackomaticDir = '$homeDir/.hackomatic';

      final directories = [
        hackomaticDir,
        '$hackomaticDir/output',
        '$hackomaticDir/logs',
        '$hackomaticDir/wordlists',
      ];

      for (final dirPath in directories) {
        final dir = Directory(dirPath);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
          dev.log('Created Linux directory: $dirPath');
        }
      }
    } catch (e) {
      dev.log('Error setting up Linux directories: $e');
    }
  }

  /// Copiar scripts de assets a ubicación accesible en Android
  Future<void> _copyScriptsToAndroid() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final scriptsDir = Directory('${appDocDir.path}/scripts');

      if (!await scriptsDir.exists()) {
        await scriptsDir.create(recursive: true);
      }

      // Lista de scripts a copiar
      final scriptNames = [
        'quick_network_scan.sh',
        'auto_port_scan.sh',
        'wifi_discovery.sh',
        'network_info.sh',
        'auto_web_scan.sh',
        'device_discovery.sh',
        'custom_target_scan.sh',
      ];

      for (final scriptName in scriptNames) {
        try {
          // Leer script desde assets
          final scriptContent = await rootBundle.loadString(
            'assets/scripts/$scriptName',
          );

          // Escribir en directorio accesible
          final targetFile = File('${scriptsDir.path}/$scriptName');
          await targetFile.writeAsString(scriptContent);

          // Hacer ejecutable (en Android podría no ser necesario)
          await Process.run('chmod', ['+x', targetFile.path]);

          dev.log('Copied script to Android: $scriptName');
        } catch (e) {
          dev.log('Error copying script $scriptName: $e');
        }
      }
    } catch (e) {
      dev.log('Error copying scripts to Android: $e');
    }
  }

  /// Configurar variables de entorno para Android
  Future<void> _setupAndroidEnvironment() async {
    try {
      // Variables de entorno específicas para Android
      final env = {
        'HACKOMATIC_PLATFORM': 'android',
        'HACKOMATIC_DATA_DIR': (await getApplicationDocumentsDirectory()).path,
        'PATH':
            '${Platform.environment['PATH']}:/system/bin:/system/xbin:/data/local/bin',
      };

      // Estas variables se aplicarán en comandos específicos
      dev.log('Android environment configured: $env');
    } catch (e) {
      dev.log('Error setting up Android environment: $e');
    }
  }

  /// Obtener información completa del sistema para debugging
  Future<Map<String, dynamic>> getSystemInformation() async {
    final info = <String, dynamic>{};

    // Información básica
    info['platform'] = Platform.operatingSystem;
    info['version'] = Platform.operatingSystemVersion;
    info['is_android'] = isAndroid;
    info['is_linux'] = isLinux;
    info['is_desktop'] = isDesktop;

    // Información de red
    try {
      info['network'] = await _networkService.getAutoScanConfig();
    } catch (e) {
      info['network_error'] = e.toString();
    }

    // Herramientas disponibles
    try {
      info['available_tools'] = await _networkService.getAvailableTools();
    } catch (e) {
      info['tools_error'] = e.toString();
    }

    // Permisos
    try {
      info['permissions'] = await _networkService.checkRequiredPermissions();
    } catch (e) {
      info['permissions_error'] = e.toString();
    }

    // Información específica de Android
    if (isAndroid) {
      try {
        final appDocDir = await getApplicationDocumentsDirectory();
        info['android_app_dir'] = appDocDir.path;

        // Verificar scripts copiados
        final scriptsDir = Directory('${appDocDir.path}/scripts');
        if (await scriptsDir.exists()) {
          final files = await scriptsDir
              .list()
              .map((f) => f.path.split('/').last)
              .toList();
          info['android_scripts'] = files;
        }
      } catch (e) {
        info['android_error'] = e.toString();
      }
    }

    // Información específica de Linux
    if (isLinux) {
      try {
        final homeDir = Platform.environment['HOME'] ?? '/home/user';
        info['linux_home_dir'] = homeDir;
        info['linux_user'] = Platform.environment['USER'] ?? 'unknown';

        // Verificar herramientas de hacking comunes
        final hacktoolsCheck = await _checkLinuxHackingTools();
        info['linux_hacktools'] = hacktoolsCheck;
      } catch (e) {
        info['linux_error'] = e.toString();
      }
    }

    return info;
  }

  /// Verificar herramientas de hacking específicas en Linux
  Future<Map<String, bool>> _checkLinuxHackingTools() async {
    final tools = <String, bool>{};

    final hackingTools = [
      'nmap',
      'masscan',
      'naabu',
      'nikto',
      'dirb',
      'gobuster',
      'ffuf',
      'sqlmap',
      'wpscan',
      'hydra',
      'medusa',
      'john',
      'aircrack-ng',
      'kismet',
      'wireshark',
      'tcpdump',
      'metasploit-framework',
      'burpsuite',
      'zaproxy',
    ];

    for (final tool in hackingTools) {
      try {
        final result = await Process.run('which', [tool]);
        tools[tool] = result.exitCode == 0;
      } catch (e) {
        tools[tool] = false;
      }
    }

    return tools;
  }

  /// Obtener configuración optimizada según la plataforma
  Future<Map<String, dynamic>> getOptimizedConfiguration() async {
    final config = <String, dynamic>{};

    // Configuración base de red
    config.addAll(await _networkService.getAutoScanConfig());

    if (isAndroid) {
      // Configuración optimizada para Android
      config['shell'] = 'sh';
      config['max_processes'] = 5; // Limitar procesos concurrentes
      config['timeout'] = 30; // Timeout más corto
      config['output_buffer_size'] = 1024; // Buffer más pequeño
      config['use_busybox'] = true;

      // Rutas específicas de Android
      final appDocDir = await getApplicationDocumentsDirectory();
      config['scripts_path'] = '${appDocDir.path}/scripts';
      config['output_path'] = '${appDocDir.path}/output';
      config['logs_path'] = '${appDocDir.path}/logs';
    } else if (isLinux) {
      // Configuración optimizada para Linux
      config['shell'] = 'bash';
      config['max_processes'] = 20; // Más procesos concurrentes
      config['timeout'] = 300; // Timeout más largo
      config['output_buffer_size'] = 4096; // Buffer más grande
      config['use_sudo'] = true;

      // Rutas específicas de Linux
      final homeDir = Platform.environment['HOME'] ?? '/home/user';
      config['scripts_path'] = 'assets/scripts';
      config['output_path'] = '$homeDir/.hackomatic/output';
      config['logs_path'] = '$homeDir/.hackomatic/logs';
      config['wordlists_path'] = '/usr/share/wordlists';
    }

    return config;
  }

  /// Ejecutar comando con configuración optimizada por plataforma
  Future<String> executeOptimizedCommand(
    String command, {
    bool requiresRoot = false,
    Duration? timeout,
  }) async {
    try {
      final config = await getOptimizedConfiguration();
      final shell = config['shell'] as String;
      final maxTimeout = timeout ?? Duration(seconds: config['timeout'] as int);

      // Preparar comando según la plataforma
      var finalCommand = command;

      if (requiresRoot) {
        if (isAndroid) {
          finalCommand = 'su -c "$command"';
        } else {
          finalCommand = 'sudo $command';
        }
      }

      // Ejecutar con timeout
      final process = await Process.start(shell, ['-c', finalCommand]);

      var output = '';
      var errorOutput = '';

      // Streams con timeout
      final outputFuture = process.stdout
          .transform(const SystemEncoding().decoder)
          .join();

      final errorFuture = process.stderr
          .transform(const SystemEncoding().decoder)
          .join();

      final results = await Future.wait([
        outputFuture,
        errorFuture,
        process.exitCode,
      ]).timeout(maxTimeout);

      output = results[0] as String;
      errorOutput = results[1] as String;
      final exitCode = results[2] as int;

      if (exitCode == 0) {
        return output;
      } else {
        throw Exception('Command failed (exit code $exitCode): $errorOutput');
      }
    } catch (e) {
      throw Exception('Command execution error: $e');
    }
  }

  /// Verificar si la plataforma está lista para usar
  Future<bool> isPlatformReady() async {
    try {
      // Test básico de ejecución de comandos
      final testResult = await executeOptimizedCommand('echo "test"');
      if (!testResult.contains('test')) {
        return false;
      }

      // Verificar configuración de red
      final networkConfig = await _networkService.getAutoScanConfig();
      if (networkConfig.isEmpty) {
        return false;
      }

      // Verificaciones específicas por plataforma
      if (isAndroid) {
        // Verificar que los scripts estén copiados
        final appDocDir = await getApplicationDocumentsDirectory();
        final scriptsDir = Directory('${appDocDir.path}/scripts');
        return await scriptsDir.exists();
      } else {
        // Para Linux, verificar que al menos ping funcione
        try {
          await executeOptimizedCommand('ping -c 1 127.0.0.1');
          return true;
        } catch (e) {
          return false;
        }
      }
    } catch (e) {
      dev.log('Platform readiness check failed: $e');
      return false;
    }
  }

  /// Obtener comandos recomendados según la plataforma
  Future<List<Map<String, dynamic>>> getRecommendedCommands() async {
    final commands = <Map<String, dynamic>>[];

    if (isAndroid) {
      // Comandos seguros y útiles para Android
      commands.addAll([
        {
          'name': 'Network Info',
          'command': 'ip addr show',
          'description': 'Show network interfaces',
          'category': 'network',
          'safe': true,
        },
        {
          'name': 'WiFi Status',
          'command': 'cat /proc/net/wireless',
          'description': 'Show WiFi status',
          'category': 'wireless',
          'safe': true,
        },
        {
          'name': 'ARP Table',
          'command': 'cat /proc/net/arp',
          'description': 'Show ARP table',
          'category': 'network',
          'safe': true,
        },
      ]);
    } else {
      // Comandos completos para Linux
      final networkConfig = await _networkService.getAutoScanConfig();

      commands.addAll([
        {
          'name': 'Quick Network Scan',
          'command': 'nmap -sn ${networkConfig['network_range']}',
          'description': 'Discover devices on network',
          'category': 'discovery',
          'safe': true,
        },
        {
          'name': 'Port Scan Gateway',
          'command': 'nmap -F ${networkConfig['gateway']}',
          'description': 'Fast port scan of gateway',
          'category': 'scanning',
          'safe': true,
        },
        {
          'name': 'WiFi Networks',
          'command': 'iwlist ${networkConfig['wifi_interface']} scan',
          'description': 'Scan for WiFi networks',
          'category': 'wireless',
          'safe': true,
        },
      ]);
    }

    return commands;
  }

  /// Limpiar recursos y caches
  Future<void> cleanup() async {
    try {
      // Limpiar logs antiguos
      if (isAndroid) {
        final appDocDir = await getApplicationDocumentsDirectory();
        final logsDir = Directory('${appDocDir.path}/logs');
        if (await logsDir.exists()) {
          await _cleanOldFiles(logsDir, days: 7);
        }
      } else {
        final homeDir = Platform.environment['HOME'] ?? '/home/user';
        final logsDir = Directory('$homeDir/.hackomatic/logs');
        if (await logsDir.exists()) {
          await _cleanOldFiles(logsDir, days: 30);
        }
      }
    } catch (e) {
      dev.log('Cleanup error: $e');
    }
  }

  /// Limpiar archivos antiguos
  Future<void> _cleanOldFiles(Directory dir, {int days = 7}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      await for (final file in dir.list()) {
        if (file is File) {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await file.delete();
            dev.log('Deleted old file: ${file.path}');
          }
        }
      }
    } catch (e) {
      dev.log('Error cleaning old files: $e');
    }
  }
}
