import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:developer' as dev;

/// Servicio para configuración automática de Linux para HACKOMATIC
class LinuxSetupService {
  static final LinuxSetupService _instance = LinuxSetupService._internal();
  factory LinuxSetupService() => _instance;
  LinuxSetupService._internal();

  // Estado del setup
  bool _isSetupComplete = false;
  bool _isSetupInProgress = false;
  final List<String> _setupSteps = [];
  final Map<String, dynamic> _setupSummary = {};

  // Getters
  bool get isSetupComplete => _isSetupComplete;
  bool get isSetupInProgress => _isSetupInProgress;
  List<String> get setupSteps => List.from(_setupSteps);

  /// Inicializar el setup de Linux
  Future<bool> initializeLinuxSetup() async {
    if (_isSetupInProgress) return false;

    _isSetupInProgress = true;
    _setupSteps.clear();
    _setupSummary.clear();

    try {
      _addStep('🚀 Iniciando configuración de HACKOMATIC para Linux...');
      await Future.delayed(const Duration(milliseconds: 500));

      // Detectar distribución
      _addStep('🔍 Detectando distribución de Linux...');
      await _detectLinuxDistro();
      await Future.delayed(const Duration(milliseconds: 300));

      // Verificar herramientas esenciales
      _addStep('🛠️ Verificando herramientas esenciales...');
      await _checkEssentialTools();
      await Future.delayed(const Duration(milliseconds: 300));

      // Configurar permisos
      _addStep('🔐 Configurando permisos del sistema...');
      await _setupPermissions();
      await Future.delayed(const Duration(milliseconds: 300));

      // Verificar conectividad
      _addStep('🌐 Verificando conectividad de red...');
      await _checkNetworkConnectivity();
      await Future.delayed(const Duration(milliseconds: 300));

      // Configurar directorios
      _addStep('📁 Configurando directorios de trabajo...');
      await _setupWorkDirectories();
      await Future.delayed(const Duration(milliseconds: 300));

      _addStep('✅ Configuración completada exitosamente!');
      _isSetupComplete = true;
      _isSetupInProgress = false;

      _setupSummary['status'] = 'success';
      _setupSummary['completed_at'] = DateTime.now().toIso8601String();
      _setupSummary['total_steps'] = _setupSteps.length;

      return true;
    } catch (e) {
      _addStep('❌ Error durante la configuración: $e');
      _isSetupComplete = false;
      _isSetupInProgress = false;

      _setupSummary['status'] = 'error';
      _setupSummary['error'] = e.toString();

      return false;
    }
  }

  /// Detectar distribución de Linux
  Future<void> _detectLinuxDistro() async {
    try {
      if (Platform.isLinux) {
        final result = await Process.run('lsb_release', ['-i', '-s']);
        if (result.exitCode == 0) {
          final distro = result.stdout.toString().trim();
          _setupSummary['distro'] = distro;
          _addStep('  📋 Distribución detectada: $distro');
        } else {
          _setupSummary['distro'] = 'Unknown Linux';
          _addStep('  📋 Distribución: Linux (genérico)');
        }
      } else {
        _setupSummary['distro'] = 'Non-Linux';
        _addStep('  📋 Sistema: No Linux detectado');
      }
    } catch (e) {
      _setupSummary['distro'] = 'Unknown';
      _addStep('  ⚠️ No se pudo detectar la distribución');
    }
  }

  /// Verificar herramientas esenciales
  Future<void> _checkEssentialTools() async {
    final tools = ['ping', 'nmap', 'netstat', 'ss', 'dig', 'curl', 'wget'];
    final installedTools = <String>[];
    final missingTools = <String>[];

    for (final tool in tools) {
      try {
        final result = await Process.run('which', [tool]);
        if (result.exitCode == 0) {
          installedTools.add(tool);
          _addStep('  ✅ $tool está disponible');
        } else {
          missingTools.add(tool);
          _addStep('  ⚠️ $tool no encontrado');
        }
      } catch (e) {
        missingTools.add(tool);
        _addStep('  ❌ Error verificando $tool');
      }
    }

    _setupSummary['installed_tools'] = installedTools;
    _setupSummary['missing_tools'] = missingTools;
    _addStep(
      '  📊 Herramientas disponibles: ${installedTools.length}/${tools.length}',
    );
  }

  /// Configurar permisos del sistema
  Future<void> _setupPermissions() async {
    try {
      // Verificar si tenemos permisos sudo
      final result = await Process.run('sudo', ['-n', 'true']);
      if (result.exitCode == 0) {
        _setupSummary['has_sudo'] = true;
        _addStep('  🔓 Permisos sudo disponibles');
      } else {
        _setupSummary['has_sudo'] = false;
        _addStep('  🔒 Permisos sudo no disponibles (normal para usuario)');
      }
    } catch (e) {
      _setupSummary['has_sudo'] = false;
      _addStep('  ⚠️ No se pudieron verificar permisos sudo');
    }

    // Verificar permisos de escritura en directorio home
    try {
      final homeDir = Platform.environment['HOME'] ?? '/tmp';
      final testFile = File('$homeDir/.hackomatic_test');
      await testFile.writeAsString('test');
      await testFile.delete();

      _setupSummary['home_writable'] = true;
      _addStep('  📝 Permisos de escritura en home: OK');
    } catch (e) {
      _setupSummary['home_writable'] = false;
      _addStep('  ❌ Permisos de escritura en home: ERROR');
    }
  }

  /// Verificar conectividad de red
  Future<void> _checkNetworkConnectivity() async {
    try {
      final result = await Process.run('ping', ['-c', '1', '8.8.8.8']);
      if (result.exitCode == 0) {
        _setupSummary['internet_connected'] = true;
        _addStep('  🌐 Conectividad a Internet: OK');
      } else {
        _setupSummary['internet_connected'] = false;
        _addStep('  🌐 Conectividad a Internet: ERROR');
      }
    } catch (e) {
      _setupSummary['internet_connected'] = false;
      _addStep('  ⚠️ No se pudo verificar conectividad');
    }

    // Verificar interfaces de red
    try {
      final result = await Process.run('ip', ['link', 'show']);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final interfaces = <String>[];

        // Buscar interfaces comunes
        if (output.contains('wlan')) interfaces.add('WiFi');
        if (output.contains('eth')) interfaces.add('Ethernet');
        if (output.contains('lo')) interfaces.add('Loopback');

        _setupSummary['network_interfaces'] = interfaces;
        _addStep('  🔌 Interfaces de red: ${interfaces.join(', ')}');
      }
    } catch (e) {
      _addStep('  ⚠️ No se pudieron listar interfaces de red');
    }
  }

  /// Configurar directorios de trabajo
  Future<void> _setupWorkDirectories() async {
    final homeDir = Platform.environment['HOME'] ?? '/tmp';
    final hackomaticDir = '$homeDir/.hackomatic';

    try {
      final dir = Directory(hackomaticDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
        _addStep('  📁 Directorio creado: ~/.hackomatic');
      } else {
        _addStep('  📁 Directorio ya existe: ~/.hackomatic');
      }

      // Crear subdirectorios
      final subdirs = ['logs', 'scripts', 'wordlists', 'results'];
      for (final subdir in subdirs) {
        final subdirPath = Directory('$hackomaticDir/$subdir');
        if (!await subdirPath.exists()) {
          await subdirPath.create();
          _addStep('  📂 Creado: ~/.hackomatic/$subdir');
        }
      }

      _setupSummary['work_directory'] = hackomaticDir;
      _setupSummary['subdirectories'] = subdirs;
    } catch (e) {
      _addStep('  ❌ Error configurando directorios: $e');
    }
  }

  /// Agregar paso al log
  void _addStep(String step) {
    _setupSteps.add(step);
    if (kDebugMode) {
      dev.log('[LinuxSetupService] $step');
    }
  }

  /// Obtener resumen del setup
  Map<String, dynamic> getSetupSummary() {
    return Map.from(_setupSummary);
  }

  /// Resetear el estado del setup
  void resetSetup() {
    _isSetupComplete = false;
    _isSetupInProgress = false;
    _setupSteps.clear();
    _setupSummary.clear();
  }

  /// Verificar si el sistema está listo para usar
  bool isSystemReady() {
    return _setupSummary['internet_connected'] == true &&
        _setupSummary['home_writable'] == true &&
        (_setupSummary['installed_tools'] as List?)?.isNotEmpty == true;
  }
}
