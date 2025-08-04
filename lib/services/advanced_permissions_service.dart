import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'command_execution_service.dart';

/// Servicio avanzado para gestión de permisos y privilegios del sistema
class AdvancedPermissionsService {
  static const String _tag = 'AdvancedPermissionsService';
  final Logger _logger = Logger();
  final CommandExecutionService _commandService = CommandExecutionService();

  // Lista de permisos esenciales para funcionamiento básico
  static const List<Permission> _essentialPermissions = [
    Permission.storage,
    Permission.camera,
    Permission.microphone,
    Permission.location,
    Permission.phone,
    Permission.contacts,
    Permission.sms,
    Permission.notification,
  ];

  // Lista de permisos avanzados para funcionalidades de hacking
  static const List<Permission> _advancedPermissions = [
    Permission.bluetooth,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.bluetoothAdvertise,
    Permission.location,
    Permission.locationWhenInUse,
    Permission.locationAlways,
    Permission.camera,
    Permission.microphone,
    Permission.nearbyWifiDevices,
    Permission.phone,
    Permission.sensors,
    Permission.activityRecognition,
    Permission.ignoreBatteryOptimizations,
  ];

  // Privilegios Linux/Unix específicos
  static const List<String> _linuxPrivileges = [
    'sudo',
    'root',
    'network',
    'bluetooth',
    'dialout',
    'plugdev',
    'wireshark',
    'docker',
    'kvm',
    'libvirt',
    'systemd-journal',
    'audio',
    'video',
    'input',
    'tty',
  ];

  /// Inicializar y verificar todos los permisos
  Future<PermissionStatus> initializePermissions() async {
    _logger.i('$_tag: Iniciando verificación de permisos...');

    try {
      // Verificar permisos esenciales primero
      final essentialStatus = await _requestEssentialPermissions();
      if (essentialStatus != PermissionStatus.granted) {
        _logger.w('$_tag: Permisos esenciales no concedidos');
        return essentialStatus;
      }

      // Verificar permisos avanzados
      await _requestAdvancedPermissions();

      // En Linux, verificar privilegios del sistema
      if (Platform.isLinux) {
        await _checkLinuxPrivileges();
        await _setupLinuxPermissions();
      }

      // Guardar estado de permisos
      await _savePermissionStatus();

      _logger.i('$_tag: Inicialización de permisos completada');
      return PermissionStatus.granted;
    } catch (e) {
      _logger.e('$_tag: Error en inicialización de permisos: $e');
      return PermissionStatus.denied;
    }
  }

  /// Solicitar permisos esenciales
  Future<PermissionStatus> _requestEssentialPermissions() async {
    _logger.i('$_tag: Solicitando permisos esenciales...');

    for (final permission in _essentialPermissions) {
      final status = await permission.request();
      if (status == PermissionStatus.denied ||
          status == PermissionStatus.permanentlyDenied) {
        _logger.w('$_tag: Permiso esencial denegado: $permission');
        return status;
      }
    }

    return PermissionStatus.granted;
  }

  /// Solicitar permisos avanzados (no críticos)
  Future<void> _requestAdvancedPermissions() async {
    _logger.i('$_tag: Solicitando permisos avanzados...');

    for (final permission in _advancedPermissions) {
      try {
        final status = await permission.request();
        _logger.d('$_tag: Permiso $permission: $status');
      } catch (e) {
        _logger.w('$_tag: Error solicitando permiso $permission: $e');
      }
    }
  }

  /// Verificar privilegios en Linux
  Future<void> _checkLinuxPrivileges() async {
    _logger.i('$_tag: Verificando privilegios Linux...');

    // Verificar si tenemos acceso sudo
    final sudoResult = await _commandService.executeCommand('sudo -n true');
    if (sudoResult.success) {
      _logger.i('$_tag: Acceso sudo disponible');
    } else {
      _logger.w('$_tag: Acceso sudo no disponible');
    }

    // Verificar grupos del usuario actual
    final groupsResult = await _commandService.executeCommand('groups');
    if (groupsResult.success) {
      final userGroups = groupsResult.output;
      _logger.i('$_tag: Grupos del usuario: $userGroups');

      for (final privilege in _linuxPrivileges) {
        if (userGroups.contains(privilege)) {
          _logger.i('$_tag: Usuario tiene privilegio: $privilege');
        }
      }
    }

    // Verificar capacidades especiales
    await _checkLinuxCapabilities();
  }

  /// Verificar capacidades Linux (capabilities)
  Future<void> _checkLinuxCapabilities() async {
    final capabilitiesResult = await _commandService.executeCommand(
      'getcap /usr/bin/* 2>/dev/null | head -20',
    );
    if (capabilitiesResult.success) {
      _logger.i('$_tag: Capacidades del sistema detectadas');
    }

    // Verificar si podemos acceder a interfaces de red
    final netResult = await _commandService.executeCommand('ip link show');
    if (netResult.success) {
      _logger.i('$_tag: Acceso a interfaces de red disponible');
    }
  }

  /// Configurar permisos específicos de Linux
  Future<void> _setupLinuxPermissions() async {
    _logger.i('$_tag: Configurando permisos Linux...');

    final setupCommands = [
      // Configurar permisos para Bluetooth
      'sudo usermod -a -G bluetooth \$USER',

      // Configurar permisos para dispositivos seriales
      'sudo usermod -a -G dialout \$USER',

      // Configurar permisos para dispositivos USB
      'sudo usermod -a -G plugdev \$USER',

      // Configurar permisos para Wireshark (si está instalado)
      'sudo usermod -a -G wireshark \$USER',

      // Configurar permisos para audio/video
      'sudo usermod -a -G audio,video \$USER',
    ];

    for (final command in setupCommands) {
      try {
        final result = await _commandService.executeCommand(command);
        if (result.success) {
          _logger.d('$_tag: Comando ejecutado: $command');
        }
      } catch (e) {
        _logger.w('$_tag: Error ejecutando comando $command: $e');
      }
    }
  }

  /// Obtener información detallada del dispositivo
  Future<Map<String, dynamic>> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();

    Map<String, dynamic> info = {
      'package': {
        'name': packageInfo.appName,
        'version': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
        'packageName': packageInfo.packageName,
      },
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
    };

    if (Platform.isLinux) {
      final linuxInfo = await deviceInfo.linuxInfo;
      info['device'] = {
        'name': linuxInfo.name,
        'version': linuxInfo.version,
        'id': linuxInfo.id,
        'idLike': linuxInfo.idLike,
        'versionCodename': linuxInfo.versionCodename,
        'versionId': linuxInfo.versionId,
        'prettyName': linuxInfo.prettyName,
        'buildId': linuxInfo.buildId,
        'variant': linuxInfo.variant,
        'variantId': linuxInfo.variantId,
        'machineId': linuxInfo.machineId,
      };
    }

    return info;
  }

  /// Verificar estado actual de permisos
  Future<Map<String, PermissionStatus>> checkCurrentPermissions() async {
    final permissions = <String, PermissionStatus>{};

    // Verificar permisos esenciales
    for (final permission in _essentialPermissions) {
      try {
        permissions[permission.toString()] = await permission.status;
      } catch (e) {
        permissions[permission.toString()] = PermissionStatus.denied;
      }
    }

    // Verificar permisos avanzados
    for (final permission in _advancedPermissions) {
      try {
        permissions[permission.toString()] = await permission.status;
      } catch (e) {
        permissions[permission.toString()] = PermissionStatus.denied;
      }
    }

    return permissions;
  }

  /// Verificar si tenemos permisos para una funcionalidad específica
  Future<bool> hasPermissionFor(String functionality) async {
    switch (functionality.toLowerCase()) {
      case 'bluetooth':
        return await _hasBluetoothPermissions();
      case 'network':
        return await _hasNetworkPermissions();
      case 'storage':
        return await _hasStoragePermissions();
      case 'camera':
        return await Permission.camera.isGranted;
      case 'location':
        return await _hasLocationPermissions();
      case 'sudo':
        return await hasSudoAccess();
      default:
        return false;
    }
  }

  /// Verificar permisos Bluetooth
  Future<bool> _hasBluetoothPermissions() async {
    if (Platform.isLinux) {
      final result = await _commandService.executeCommand(
        'bluetoothctl --version',
      );
      return result.success;
    }

    return await Permission.bluetooth.isGranted &&
        await Permission.bluetoothScan.isGranted &&
        await Permission.bluetoothConnect.isGranted;
  }

  /// Verificar permisos de red
  Future<bool> _hasNetworkPermissions() async {
    if (Platform.isLinux) {
      final result = await _commandService.executeCommand('ip link show');
      return result.success;
    }

    return await Permission.nearbyWifiDevices.isGranted;
  }

  /// Verificar permisos de almacenamiento
  Future<bool> _hasStoragePermissions() async {
    return await Permission.storage.isGranted ||
        await Permission.manageExternalStorage.isGranted;
  }

  /// Verificar permisos de ubicación
  Future<bool> _hasLocationPermissions() async {
    return await Permission.location.isGranted ||
        await Permission.locationWhenInUse.isGranted;
  }

  /// Verificar acceso sudo
  Future<bool> hasSudoAccess() async {
    if (!Platform.isLinux) return false;

    final result = await _commandService.executeCommand('sudo -n true');
    return result.success;
  }

  /// Abrir configuración de permisos del sistema
  Future<void> openPermissionSettings() async {
    await openAppSettings();
  }

  /// Guardar estado de permisos
  Future<void> _savePermissionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final permissions = await checkCurrentPermissions();

    for (final entry in permissions.entries) {
      await prefs.setString('permission_${entry.key}', entry.value.toString());
    }

    await prefs.setString(
      'permissions_last_check',
      DateTime.now().toIso8601String(),
    );
  }

  /// Obtener logs de permisos
  Future<List<String>> getPermissionLogs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('permission_logs') ?? [];
  }

  /// Agregar log de permiso
  Future<void> addPermissionLog(String log) async {
    final prefs = await SharedPreferences.getInstance();
    final logs = await getPermissionLogs();
    logs.add('${DateTime.now().toIso8601String()}: $log');

    // Mantener solo los últimos 100 logs
    if (logs.length > 100) {
      logs.removeRange(0, logs.length - 100);
    }

    await prefs.setStringList('permission_logs', logs);
  }

  /// Verificar si necesitamos actualizar permisos
  Future<bool> needsPermissionUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getString('permissions_last_check');

    if (lastCheck == null) return true;

    final lastCheckTime = DateTime.parse(lastCheck);
    final now = DateTime.now();

    // Verificar permisos cada 24 horas
    return now.difference(lastCheckTime).inHours > 24;
  }

  /// Exportar configuración de permisos
  Future<Map<String, dynamic>> exportPermissionConfig() async {
    final deviceInfo = await getDeviceInfo();
    final permissions = await checkCurrentPermissions();
    final logs = await getPermissionLogs();

    return {
      'device': deviceInfo,
      'permissions': permissions.map((k, v) => MapEntry(k, v.toString())),
      'logs': logs,
      'exportTime': DateTime.now().toIso8601String(),
    };
  }
}
