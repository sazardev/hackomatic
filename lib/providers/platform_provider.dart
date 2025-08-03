import 'package:flutter/foundation.dart';
import '../services/platform_integration_service.dart';
import '../services/network_detection_service.dart';
import '../services/command_execution_service.dart';

class PlatformProvider extends ChangeNotifier {
  final PlatformIntegrationService _platformService =
      PlatformIntegrationService();
  final NetworkDetectionService _networkService = NetworkDetectionService();
  final CommandExecutionService _commandService = CommandExecutionService();

  bool _isInitialized = false;
  bool _isReady = false;
  Map<String, dynamic> _systemInfo = {};
  Map<String, dynamic> _configuration = {};
  String _initializationError = '';

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isReady => _isReady;
  bool get isAndroid => _platformService.isAndroid;
  bool get isLinux => _platformService.isLinux;
  bool get isDesktop => _platformService.isDesktop;
  Map<String, dynamic> get systemInfo => Map.from(_systemInfo);
  Map<String, dynamic> get configuration => Map.from(_configuration);
  String get initializationError => _initializationError;

  // Platform-specific getters
  String get platformName => _platformService.isAndroid ? 'Android' : 'Linux';
  String get platformEmoji => _platformService.isAndroid ? '📱' : '🐧';

  /// Inicializar el proveedor de plataforma
  Future<void> initialize() async {
    try {
      _initializationError = '';

      if (kDebugMode) {
        print('🚀 Starting platform initialization...');
        print(
          '� Platform: ${_platformService.isAndroid ? 'Android' : 'Linux'}',
        );
      }

      // 1. Inicializar servicios de plataforma
      _isInitialized = await _platformService.initialize();

      if (kDebugMode) {
        print('✅ Platform service initialized: $_isInitialized');
      }

      if (!_isInitialized) {
        _initializationError = 'Failed to initialize platform services';
        if (kDebugMode) {
          print('❌ Platform initialization failed');
        }
        return;
      }

      // 2. Cargar información del sistema
      await loadSystemInfo();
      if (kDebugMode) {
        print('✅ System info loaded');
      }

      // 3. Cargar configuración optimizada
      await loadConfiguration();
      if (kDebugMode) {
        print('✅ Configuration loaded');
      }

      // 4. Verificar si está listo para usar
      _isReady = await _platformService.isPlatformReady();
      if (kDebugMode) {
        print('🔍 Platform ready: $_isReady');
      }

      if (!_isReady) {
        _initializationError = 'Platform not ready for operation';
        if (kDebugMode) {
          print('⚠️ Platform not ready, but continuing...');
        }
      }

      if (kDebugMode) {
        print('🎉 Platform initialization completed successfully!');
      }
    } catch (e, stackTrace) {
      _initializationError = 'Initialization error: $e';
      _isInitialized = false;
      _isReady = false;
      if (kDebugMode) {
        print('💥 Platform initialization error: $e');
        print('📍 Stack trace: $stackTrace');
      }
    }
  }

  /// Cargar información completa del sistema
  Future<void> loadSystemInfo() async {
    try {
      _systemInfo = await _platformService.getSystemInformation();
      // Don't notify listeners here during initialization
    } catch (e) {
      if (kDebugMode) {
        print('Error loading system info: $e');
      }
      _systemInfo = {'error': e.toString()};
    }
  }

  /// Cargar configuración optimizada
  Future<void> loadConfiguration() async {
    try {
      _configuration = await _platformService.getOptimizedConfiguration();
      // Don't notify listeners here during initialization
    } catch (e) {
      if (kDebugMode) {
        print('Error loading configuration: $e');
      }
      _configuration = {'error': e.toString()};
    }
  }

  /// Recargar toda la información
  Future<void> refresh() async {
    await loadSystemInfo();
    await loadConfiguration();
    _isReady = await _platformService.isPlatformReady();
    notifyListeners();
  }

  /// Verificar conectividad de red
  Future<bool> checkNetworkConnectivity() async {
    try {
      final localIP = await _networkService.getLocalIP();
      final gateway = await _networkService.getGatewayIP();

      // Test básico de ping al gateway
      if (gateway != '0.0.0.0' && gateway.isNotEmpty) {
        final result = await _platformService.executeOptimizedCommand(
          'ping -c 1 $gateway',
          timeout: const Duration(seconds: 5),
        );
        return result.contains('1 received') ||
            result.contains('1 packets transmitted');
      }

      return localIP != '0.0.0.0' && localIP.isNotEmpty;
    } catch (e) {
      print('Network connectivity check failed: $e');
      return false;
    }
  }

  /// Obtener comandos recomendados para la plataforma actual
  Future<List<Map<String, dynamic>>> getRecommendedCommands() async {
    try {
      return await _platformService.getRecommendedCommands();
    } catch (e) {
      print('Error getting recommended commands: $e');
      return [];
    }
  }

  /// Ejecutar comando con manejo de errores
  Future<String> executeCommand(
    String command, {
    bool requiresRoot = false,
    Duration? timeout,
  }) async {
    try {
      return await _platformService.executeOptimizedCommand(
        command,
        requiresRoot: requiresRoot,
        timeout: timeout,
      );
    } catch (e) {
      throw Exception('Command execution failed: $e');
    }
  }

  /// Obtener información de herramientas disponibles
  Future<Map<String, bool>> getAvailableTools() async {
    try {
      return await _networkService.getAvailableTools();
    } catch (e) {
      print('Error getting available tools: $e');
      return {};
    }
  }

  /// Obtener configuración de red automática
  Future<Map<String, String>> getNetworkConfig() async {
    try {
      return await _networkService.getAutoScanConfig();
    } catch (e) {
      print('Error getting network config: $e');
      return {};
    }
  }

  /// Obtener comandos pre-configurados
  Future<Map<String, String>> getPreConfiguredCommands() async {
    try {
      return await _networkService.getPreConfiguredCommands();
    } catch (e) {
      print('Error getting pre-configured commands: $e');
      return {};
    }
  }

  /// Verificar permisos requeridos
  Future<Map<String, bool>> checkPermissions() async {
    try {
      return await _networkService.checkRequiredPermissions();
    } catch (e) {
      print('Error checking permissions: $e');
      return {};
    }
  }

  /// Limpiar recursos y caches
  Future<void> cleanup() async {
    try {
      await _platformService.cleanup();
      // Only notify if cleanup actually changed something
      notifyListeners();
    } catch (e) {
      print('Cleanup error: $e');
    }
  }

  /// Obtener resumen del estado de la plataforma
  Map<String, dynamic> getPlatformSummary() {
    return {
      'platform': platformName,
      'emoji': platformEmoji,
      'initialized': _isInitialized,
      'ready': _isReady,
      'error': _initializationError,
      'network_available': _systemInfo['network'] != null,
      'tools_count': (_systemInfo['available_tools'] as Map?)?.length ?? 0,
      'permissions_ok':
          (_systemInfo['permissions'] as Map?)?.values
              .where((v) => v == true)
              .length ??
          0,
    };
  }

  /// Obtener información de debug
  String getDebugInfo() {
    final buffer = StringBuffer();
    buffer.writeln('=== HACKOMATIC PLATFORM DEBUG ===');
    buffer.writeln('Platform: $platformName $platformEmoji');
    buffer.writeln('Initialized: $_isInitialized');
    buffer.writeln('Ready: $_isReady');
    buffer.writeln(
      'Error: ${_initializationError.isEmpty ? 'None' : _initializationError}',
    );
    buffer.writeln('');

    if (_systemInfo.isNotEmpty) {
      buffer.writeln('System Info:');
      _systemInfo.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
      buffer.writeln('');
    }

    if (_configuration.isNotEmpty) {
      buffer.writeln('Configuration:');
      _configuration.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }

    return buffer.toString();
  }

  @override
  void dispose() {
    _commandService.dispose();
    super.dispose();
  }
}
