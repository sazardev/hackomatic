import 'dart:io';
import 'package:flutter/foundation.dart';

/// Servicio especializado para configuración automática de Linux
/// Enfocado en preparación completa del entorno de penetration testing
class LinuxAutoSetupService {
  static final LinuxAutoSetupService _instance =
      LinuxAutoSetupService._internal();
  factory LinuxAutoSetupService() => _instance;
  LinuxAutoSetupService._internal();

  // Estado de la configuración
  bool _isSetupComplete = false;
  bool _isSetupInProgress = false;
  String _currentStep = '';
  double _setupProgress = 0.0;
  List<String> _installedTools = [];
  List<String> _failedTools = [];
  Map<String, String> _systemInfo = {};

  // Getters
  bool get isSetupComplete => _isSetupComplete;
  bool get isSetupInProgress => _isSetupInProgress;
  String get currentStep => _currentStep;
  double get setupProgress => _setupProgress;
  List<String> get installedTools => List.from(_installedTools);
  List<String> get failedTools => List.from(_failedTools);
  Map<String, String> get systemInfo => Map.from(_systemInfo);

  /// Herramientas esenciales para pentesting en Linux
  static const Map<String, Map<String, String>> _essentialTools = {
    // Network Discovery & Scanning
    'nmap': {
      'name': 'Nmap',
      'description': 'Network discovery and security scanning',
      'package': 'nmap',
      'command': 'nmap',
      'category': 'scanning',
      'priority': '1',
    },
    'masscan': {
      'name': 'Masscan',
      'description': 'High-speed port scanner',
      'package': 'masscan',
      'command': 'masscan',
      'category': 'scanning',
      'priority': '2',
    },

    // Web Application Testing
    'nikto': {
      'name': 'Nikto',
      'description': 'Web server scanner',
      'package': 'nikto',
      'command': 'nikto',
      'category': 'web',
      'priority': '1',
    },
    'dirb': {
      'name': 'Dirb',
      'description': 'Directory and file brute forcer',
      'package': 'dirb',
      'command': 'dirb',
      'category': 'web',
      'priority': '1',
    },
    'gobuster': {
      'name': 'Gobuster',
      'description': 'Fast directory/file brute forcer',
      'package': 'gobuster',
      'command': 'gobuster',
      'category': 'web',
      'priority': '2',
    },

    // Wireless Testing
    'aircrack-ng': {
      'name': 'Aircrack-ng',
      'description': 'WiFi security testing suite',
      'package': 'aircrack-ng',
      'command': 'aircrack-ng',
      'category': 'wireless',
      'priority': '1',
    },

    // Password Testing
    'john': {
      'name': 'John the Ripper',
      'description': 'Password cracking tool',
      'package': 'john',
      'command': 'john',
      'category': 'password',
      'priority': '2',
    },
    'hydra': {
      'name': 'Hydra',
      'description': 'Network login cracker',
      'package': 'hydra',
      'command': 'hydra',
      'category': 'password',
      'priority': '1',
    },

    // Network Analysis
    'wireshark': {
      'name': 'Wireshark',
      'description': 'Network protocol analyzer',
      'package': 'wireshark',
      'command': 'wireshark',
      'category': 'analysis',
      'priority': '2',
    },
    'tcpdump': {
      'name': 'TCPDump',
      'description': 'Command-line packet analyzer',
      'package': 'tcpdump',
      'command': 'tcpdump',
      'category': 'analysis',
      'priority': '1',
    },

    // Utilities
    'curl': {
      'name': 'cURL',
      'description': 'Command line HTTP client',
      'package': 'curl',
      'command': 'curl',
      'category': 'utility',
      'priority': '1',
    },
    'wget': {
      'name': 'Wget',
      'description': 'Network downloader',
      'package': 'wget',
      'command': 'wget',
      'category': 'utility',
      'priority': '1',
    },
    'netcat': {
      'name': 'Netcat',
      'description': 'Network utility',
      'package': 'netcat-traditional',
      'command': 'nc',
      'category': 'utility',
      'priority': '1',
    },
  };

  /// Inicializar la configuración automática de Linux
  Future<bool> initializeLinuxSetup() async {
    if (_isSetupInProgress) return false;

    _isSetupInProgress = true;
    _setupProgress = 0.0;
    _installedTools.clear();
    _failedTools.clear();

    try {
      // 1. Detectar distribución de Linux
      await _detectLinuxDistribution();
      _updateProgress(10, 'Detecting Linux distribution...');

      // 2. Actualizar repositorios
      await _updateRepositories();
      _updateProgress(20, 'Updating package repositories...');

      // 3. Instalar herramientas esenciales
      await _installEssentialTools();
      _updateProgress(80, 'Installing penetration testing tools...');

      // 4. Configurar directorios y permisos
      await _setupDirectoriesAndPermissions();
      _updateProgress(90, 'Setting up directories and permissions...');

      // 5. Verificar instalación
      await _verifyInstallation();
      _updateProgress(100, 'Setup complete!');

      _isSetupComplete = true;
      _isSetupInProgress = false;

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error during Linux setup: $e');
      }
      _isSetupInProgress = false;
      return false;
    }
  }

  /// Detectar distribución de Linux
  Future<void> _detectLinuxDistribution() async {
    try {
      // Leer /etc/os-release
      final osRelease = File('/etc/os-release');
      if (await osRelease.exists()) {
        final content = await osRelease.readAsString();
        final lines = content.split('\n');

        for (final line in lines) {
          if (line.startsWith('ID=')) {
            _systemInfo['distro'] = line.split('=')[1].replaceAll('"', '');
          } else if (line.startsWith('VERSION_ID=')) {
            _systemInfo['version'] = line.split('=')[1].replaceAll('"', '');
          } else if (line.startsWith('PRETTY_NAME=')) {
            _systemInfo['pretty_name'] = line.split('=')[1].replaceAll('"', '');
          }
        }
      }

      // Detectar gestor de paquetes
      if (await _commandExists('apt')) {
        _systemInfo['package_manager'] = 'apt';
      } else if (await _commandExists('yum')) {
        _systemInfo['package_manager'] = 'yum';
      } else if (await _commandExists('dnf')) {
        _systemInfo['package_manager'] = 'dnf';
      } else if (await _commandExists('pacman')) {
        _systemInfo['package_manager'] = 'pacman';
      } else {
        _systemInfo['package_manager'] = 'unknown';
      }

      if (kDebugMode) {
        print('🐧 Detected Linux: ${_systemInfo['pretty_name']}');
        print('📦 Package manager: ${_systemInfo['package_manager']}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error detecting Linux distribution: $e');
      }
    }
  }

  /// Actualizar repositorios del sistema
  Future<void> _updateRepositories() async {
    final packageManager = _systemInfo['package_manager'] ?? 'apt';

    try {
      switch (packageManager) {
        case 'apt':
          await _runCommand('sudo apt update');
          break;
        case 'yum':
          await _runCommand('sudo yum update');
          break;
        case 'dnf':
          await _runCommand('sudo dnf update');
          break;
        case 'pacman':
          await _runCommand('sudo pacman -Sy');
          break;
      }

      if (kDebugMode) {
        print('✅ Package repositories updated');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to update repositories: $e');
      }
    }
  }

  /// Instalar herramientas esenciales
  Future<void> _installEssentialTools() async {
    final packageManager = _systemInfo['package_manager'] ?? 'apt';

    // Ordenar herramientas por prioridad
    final sortedTools = _essentialTools.entries.toList()
      ..sort((a, b) => a.value['priority']!.compareTo(b.value['priority']!));

    int completed = 0;
    final total = sortedTools.length;

    for (final entry in sortedTools) {
      final toolName = entry.key;
      final toolInfo = entry.value;
      final packageName = toolInfo['package']!;

      try {
        _currentStep = 'Installing ${toolInfo['name']}...';

        // Verificar si ya está instalado
        if (await _commandExists(toolInfo['command']!)) {
          _installedTools.add(toolName);
          if (kDebugMode) {
            print('✅ ${toolInfo['name']} already installed');
          }
        } else {
          // Instalar herramienta
          final success = await _installPackage(packageManager, packageName);

          if (success) {
            _installedTools.add(toolName);
            if (kDebugMode) {
              print('✅ ${toolInfo['name']} installed successfully');
            }
          } else {
            _failedTools.add(toolName);
            if (kDebugMode) {
              print('❌ Failed to install ${toolInfo['name']}');
            }
          }
        }

        completed++;
        final progress = 20 + (completed / total * 60).round();
        _updateProgress(progress.toDouble(), _currentStep);
      } catch (e) {
        _failedTools.add(toolName);
        if (kDebugMode) {
          print('❌ Error installing $toolName: $e');
        }
      }
    }
  }

  /// Instalar un paquete específico
  Future<bool> _installPackage(
    String packageManager,
    String packageName,
  ) async {
    try {
      switch (packageManager) {
        case 'apt':
          await _runCommand('sudo apt install -y $packageName');
          break;
        case 'yum':
          await _runCommand('sudo yum install -y $packageName');
          break;
        case 'dnf':
          await _runCommand('sudo dnf install -y $packageName');
          break;
        case 'pacman':
          await _runCommand('sudo pacman -S --noconfirm $packageName');
          break;
        default:
          return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Configurar directorios y permisos
  Future<void> _setupDirectoriesAndPermissions() async {
    try {
      final homeDir =
          Platform.environment['HOME'] ??
          '/home/${Platform.environment['USER']}';

      // Crear directorios de trabajo
      final directories = [
        '$homeDir/.hackomatic',
        '$homeDir/.hackomatic/wordlists',
        '$homeDir/.hackomatic/output',
        '$homeDir/.hackomatic/logs',
        '$homeDir/.hackomatic/scripts',
      ];

      for (final dir in directories) {
        await Directory(dir).create(recursive: true);
      }

      // Descargar wordlists básicas si no existen
      await _downloadWordlists('$homeDir/.hackomatic/wordlists');

      if (kDebugMode) {
        print('✅ Directories and permissions configured');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting up directories: $e');
      }
    }
  }

  /// Descargar wordlists esenciales
  Future<void> _downloadWordlists(String wordlistsDir) async {
    try {
      // Lista básica de wordlists comunes
      final basicWordlist = [
        'common.txt',
        'admin.txt',
        'passwords.txt',
      ].join('\n');

      // Crear wordlist básica
      final commonFile = File('$wordlistsDir/common.txt');
      if (!await commonFile.exists()) {
        await commonFile.writeAsString(
          [
            'admin',
            'password',
            'login',
            'test',
            'guest',
            'user',
            'root',
            'administrator',
            '123456',
            'qwerty',
            'letmein',
            'welcome',
            'monkey',
            'dragon',
            'master',
            'shadow',
            'superman',
            'michael',
            'batman',
            'computer',
            'matrix',
            'server',
            'database',
            'backup',
            'config',
            'upload',
            'download',
            'temp',
            'secure',
            'private',
            'public',
            'api',
            'web',
            'www',
            'ftp',
            'mail',
            'email',
            'blog',
            'forum',
            'shop',
            'store',
            'news',
            'media',
            'images',
            'files',
            'docs',
            'documents',
            'assets',
            'scripts',
            'css',
            'js',
          ].join('\n'),
        );
      }

      if (kDebugMode) {
        print('✅ Basic wordlists created');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error downloading wordlists: $e');
      }
    }
  }

  /// Verificar instalación completa
  Future<void> _verifyInstallation() async {
    final workingTools = <String>[];
    final brokenTools = <String>[];

    for (final entry in _essentialTools.entries) {
      final toolName = entry.key;
      final toolInfo = entry.value;

      if (await _commandExists(toolInfo['command']!)) {
        workingTools.add(toolName);
      } else {
        brokenTools.add(toolName);
      }
    }

    _installedTools.clear();
    _installedTools.addAll(workingTools);

    if (kDebugMode) {
      print(
        '✅ Verification complete: ${workingTools.length}/${_essentialTools.length} tools working',
      );
      if (brokenTools.isNotEmpty) {
        print('⚠️ Not working: ${brokenTools.join(', ')}');
      }
    }
  }

  /// Verificar si un comando existe
  Future<bool> _commandExists(String command) async {
    try {
      final result = await Process.run('which', [command]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Ejecutar un comando del sistema
  Future<void> _runCommand(String command) async {
    final result = await Process.run('sh', ['-c', command]);
    if (result.exitCode != 0) {
      throw Exception('Command failed: $command\nError: ${result.stderr}');
    }
  }

  /// Actualizar progreso
  void _updateProgress(double progress, String step) {
    _setupProgress = progress;
    _currentStep = step;

    if (kDebugMode) {
      print('📊 Progress: ${progress.toStringAsFixed(1)}% - $step');
    }
  }

  /// Obtener resumen de herramientas por categoría
  Map<String, List<String>> getToolsByCategory() {
    final categories = <String, List<String>>{};

    for (final entry in _essentialTools.entries) {
      final toolName = entry.key;
      final category = entry.value['category']!;

      categories.putIfAbsent(category, () => []);
      if (_installedTools.contains(toolName)) {
        categories[category]!.add(toolName);
      }
    }

    return categories;
  }

  /// Obtener herramientas faltantes críticas
  List<String> getMissingCriticalTools() {
    final critical = <String>[];

    for (final entry in _essentialTools.entries) {
      if (entry.value['priority'] == '1' &&
          !_installedTools.contains(entry.key)) {
        critical.add(entry.key);
      }
    }

    return critical;
  }

  /// Reinstalar herramientas que fallaron
  Future<bool> retryFailedInstallations() async {
    if (_failedTools.isEmpty) return true;

    final packageManager = _systemInfo['package_manager'] ?? 'apt';
    final retryTools = List<String>.from(_failedTools);
    _failedTools.clear();

    for (final toolName in retryTools) {
      final toolInfo = _essentialTools[toolName];
      if (toolInfo != null) {
        final success = await _installPackage(
          packageManager,
          toolInfo['package']!,
        );
        if (success) {
          _installedTools.add(toolName);
        } else {
          _failedTools.add(toolName);
        }
      }
    }

    return _failedTools.isEmpty;
  }

  /// Obtener estado detallado de la configuración
  Map<String, dynamic> getSetupStatus() {
    return {
      'is_complete': _isSetupComplete,
      'is_in_progress': _isSetupInProgress,
      'current_step': _currentStep,
      'progress': _setupProgress,
      'installed_tools': _installedTools.length,
      'total_tools': _essentialTools.length,
      'failed_tools': _failedTools.length,
      'system_info': _systemInfo,
      'tools_by_category': getToolsByCategory(),
      'missing_critical': getMissingCriticalTools(),
    };
  }
}
