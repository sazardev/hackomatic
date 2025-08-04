import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as dev;

/// Servicio de Terminal Visual para Hackomatic
/// Proporciona experiencia de terminal hacker con vis  ) async {
// Mostrar descripción si se proporcionaación en tiempo real
class TerminalUIService {
  static final TerminalUIService _instance = TerminalUIService._internal();
  factory TerminalUIService() => _instance;
  TerminalUIService._internal();

  // Estado del terminal
  final List<TerminalLine> _terminalLines = [];
  final StreamController<List<TerminalLine>> _outputController =
      StreamController<List<TerminalLine>>.broadcast();

  String _currentUser = '';
  String _currentHost = '';
  bool _isInitialized = false;

  // Configuración visual
  // (Colores definidos en TerminalLine.color getter)

  // Getters
  List<TerminalLine> get terminalLines => List.from(_terminalLines);
  Stream<List<TerminalLine>> get outputStream => _outputController.stream;
  bool get isInitialized => _isInitialized;
  String get currentUser => _currentUser;
  String get currentHost => _currentHost;

  /// Inicializar el terminal con información del usuario
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Obtener información del usuario
      await _getUserInfo();

      // Mostrar banner de bienvenida
      await _showWelcomeBanner();

      // Inicializar sistema
      await _initializeSystem();

      _isInitialized = true;

      if (kDebugMode) {
        dev.log('🖥️ Terminal UI Service initialized');
      }
    } catch (e) {
      addErrorLine('Error inicializando terminal: $e');
    }
  }

  /// Obtener información del usuario actual
  Future<void> _getUserInfo() async {
    try {
      // Obtener usuario actual
      final whoamiResult = await Process.run('whoami', []);
      if (whoamiResult.exitCode == 0) {
        _currentUser = whoamiResult.stdout.toString().trim();
      } else {
        _currentUser = Platform.environment['USER'] ?? 'hacker';
      }

      // Obtener hostname
      final hostnameResult = await Process.run('hostname', []);
      if (hostnameResult.exitCode == 0) {
        _currentHost = hostnameResult.stdout.toString().trim();
      } else {
        _currentHost = Platform.environment['HOSTNAME'] ?? 'hackomatic';
      }
    } catch (e) {
      _currentUser = 'hacker';
      _currentHost = 'hackomatic';
    }
  }

  /// Mostrar banner de bienvenida personalizado
  Future<void> _showWelcomeBanner() async {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // ASCII Art Banner
    final bannerLines = [
      '',
      '██╗  ██╗ █████╗  ██████╗██╗  ██╗ ██████╗ ███╗   ███╗ █████╗ ████████╗██╗ ██████╗',
      '██║  ██║██╔══██╗██╔════╝██║ ██╔╝██╔═══██╗████╗ ████║██╔══██╗╚══██╔══╝██║██╔════╝',
      '███████║███████║██║     █████╔╝ ██║   ██║██╔████╔██║███████║   ██║   ██║██║     ',
      '██╔══██║██╔══██║██║     ██╔═██╗ ██║   ██║██║╚██╔╝██║██╔══██║   ██║   ██║██║     ',
      '██║  ██║██║  ██║╚██████╗██║  ██╗╚██████╔╝██║ ╚═╝ ██║██║  ██║   ██║   ██║╚██████╗',
      '╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝',
      '',
      '                    🚀 PENETRATION TESTING FRAMEWORK 🚀',
      '                          Linux Auto-Setup System',
      '',
    ];

    // Añadir líneas del banner
    for (final line in bannerLines) {
      _addLine(
        TerminalLine(
          content: line,
          type: TerminalLineType.banner,
          timestamp: DateTime.now(),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 50));
    }

    // Saludo personalizado
    final greeting = _getTimeBasedGreeting();
    _addLine(
      TerminalLine(
        content: '[$timeStr] $greeting, $_currentUser! 👋',
        type: TerminalLineType.success,
        timestamp: DateTime.now(),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 200));

    _addLine(
      TerminalLine(
        content: '[$timeStr] Conectado como: $_currentUser@$_currentHost',
        type: TerminalLineType.info,
        timestamp: DateTime.now(),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 100));

    _addLine(
      TerminalLine(
        content:
            '[$timeStr] Sistema: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
        type: TerminalLineType.info,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Obtener saludo basado en la hora
  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 6 && hour < 12) {
      return 'Buenos días';
    } else if (hour >= 12 && hour < 18) {
      return 'Buenas tardes';
    } else {
      return 'Buenas noches';
    }
  }

  /// Inicializar verificaciones del sistema
  Future<void> _initializeSystem() async {
    await Future.delayed(const Duration(milliseconds: 300));

    addInfoLine('🔍 Iniciando verificaciones del sistema...');
    await Future.delayed(const Duration(milliseconds: 500));

    // Verificar permisos
    addProcessLine('Verificando permisos de usuario...');
    await Future.delayed(const Duration(milliseconds: 800));

    final hasRoot = await _checkRootAccess();
    if (hasRoot) {
      addSuccessLine('✅ Permisos administrativos: DISPONIBLES');
    } else {
      addWarningLine(
        '⚠️  Permisos administrativos: LIMITADOS (se pedirán cuando sea necesario)',
      );
    }

    // Verificar conectividad
    addProcessLine('Verificando conectividad de red...');
    await Future.delayed(const Duration(milliseconds: 600));

    final hasInternet = await _checkInternetConnectivity();
    if (hasInternet) {
      addSuccessLine('✅ Conectividad de red: ACTIVA');
    } else {
      addErrorLine('❌ Conectividad de red: SIN CONEXIÓN');
    }

    // Verificar herramientas básicas
    addProcessLine('Escaneando herramientas de penetración testing...');
    await Future.delayed(const Duration(milliseconds: 700));

    final tools = await _scanAvailableTools();
    addSuccessLine('✅ Herramientas encontradas: ${tools.length}');

    for (final tool in tools.take(5)) {
      addInfoLine('  → $tool');
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (tools.length > 5) {
      addInfoLine('  → ... y ${tools.length - 5} más');
    }

    await Future.delayed(const Duration(milliseconds: 300));
    addSuccessLine('🚀 Sistema listo para penetration testing!');
  }

  /// Verificar acceso root
  Future<bool> _checkRootAccess() async {
    try {
      final result = await Process.run('sudo', ['-n', 'true']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Verificar conectividad a internet
  Future<bool> _checkInternetConnectivity() async {
    try {
      final result = await Process.run('ping', [
        '-c',
        '1',
        '-W',
        '3',
        '8.8.8.8',
      ]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Escanear herramientas disponibles
  Future<List<String>> _scanAvailableTools() async {
    final commonTools = [
      'nmap',
      'netcat',
      'nc',
      'curl',
      'wget',
      'ping',
      'dig',
      'nslookup',
      'aircrack-ng',
      'hydra',
      'john',
      'hashcat',
      'sqlmap',
      'gobuster',
      'nikto',
      'dirb',
      'masscan',
      'wireshark',
      'tcpdump',
      'arp-scan',
    ];

    final availableTools = <String>[];

    for (final tool in commonTools) {
      try {
        final result = await Process.run('which', [tool]);
        if (result.exitCode == 0) {
          availableTools.add(tool);
        }
      } catch (e) {
        // Tool not found
      }
    }

    return availableTools;
  }

  /// Ejecutar comando con visualización en tiempo real
  Future<void> executeCommand(
    String command, {
    String? description,
    bool requiresRoot = false,
    Map<String, String>? environment,
  }) async {
    // Mostrar descripción si se proporciona
    if (description != null) {
      addInfoLine('📋 $description');
    }

    // Mostrar comando que se va a ejecutar
    addCommandLine('$_currentUser@$_currentHost:~\$ $command');

    try {
      // Configurar proceso con mejor manejo de sudo
      Process process;

      if (requiresRoot) {
        // Para comandos sudo, usamos -S para leer contraseña desde stdin
        process = await Process.start('sudo', [
          '-S',
          'sh',
          '-c',
          command,
        ], environment: environment);

        // Si tenemos contraseña en caché (desde SudoAuthService)
        // La inyectaríamos aquí, pero por ahora simulamos
        process.stdin.writeln(''); // Línea vacía para continuar
        await process.stdin.close();
      } else {
        process = await Process.start('sh', [
          '-c',
          command,
        ], environment: environment);
      }

      // Escuchar salida estándar con mejor formateo
      process.stdout.transform(utf8.decoder).listen((data) {
        // Procesar líneas individualmente para mejor visualización
        for (final line in data.split('\n')) {
          if (line.trim().isNotEmpty) {
            addOutputLine('  $line'); // Indentar output del comando
          }
        }
      });

      // Escuchar salida de error con manejo mejorado
      process.stderr.transform(utf8.decoder).listen((data) {
        for (final line in data.split('\n')) {
          if (line.trim().isNotEmpty) {
            // Filtrar errores comunes de sudo
            if (!line.contains('sudo:') && !line.contains('password for')) {
              addErrorLine('  ⚠️ $line');
            }
          }
        }
      });

      // Esperar a que termine con timeout
      final exitCode = await process.exitCode.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          process.kill();
          addErrorLine('❌ Comando cancelado por timeout');
          return -1;
        },
      );

      // Mostrar resultado final
      if (exitCode == 0) {
        addSuccessLine('✅ Comando completado exitosamente');
      } else if (exitCode != -1) {
        addErrorLine('❌ Comando falló con código: $exitCode');
      }
    } catch (e) {
      addErrorLine('❌ Error ejecutando comando: $e');
    }

    // Añadir línea en blanco para separar comandos
    addInfoLine('');
  }

  /// Mostrar progreso de instalación
  void showInstallationProgress(
    String toolName,
    double progress, {
    String? currentStep,
  }) {
    final progressBar = _createProgressBar(progress);
    final progressText = '${(progress * 100).toInt()}%';

    final content = currentStep != null
        ? '🔧 Instalando $toolName... $progressBar $progressText - $currentStep'
        : '🔧 Instalando $toolName... $progressBar $progressText';

    // Actualizar o añadir línea de progreso
    if (_terminalLines.isNotEmpty &&
        _terminalLines.last.type == TerminalLineType.progress) {
      _terminalLines.last = TerminalLine(
        content: content,
        type: TerminalLineType.progress,
        timestamp: DateTime.now(),
      );
    } else {
      _addLine(
        TerminalLine(
          content: content,
          type: TerminalLineType.progress,
          timestamp: DateTime.now(),
        ),
      );
    }

    _notifyListeners();
  }

  /// Crear barra de progreso visual
  String _createProgressBar(double progress, {int width = 20}) {
    final filledWidth = (progress * width).round();
    final emptyWidth = width - filledWidth;

    return '[${'█' * filledWidth}${'░' * emptyWidth}]';
  }

  /// Mostrar estadísticas de red
  void showNetworkStats({
    String? interface,
    String? speed,
    String? signal,
    int? packetsReceived,
    int? packetsSent,
  }) {
    addInfoLine('📊 Estadísticas de Red:');

    if (interface != null) {
      addInfoLine('  → Interfaz: $interface');
    }
    if (speed != null) {
      addInfoLine('  → Velocidad: $speed');
    }
    if (signal != null) {
      addInfoLine('  → Señal WiFi: $signal');
    }
    if (packetsReceived != null) {
      addInfoLine('  → Paquetes recibidos: $packetsReceived');
    }
    if (packetsSent != null) {
      addInfoLine('  → Paquetes enviados: $packetsSent');
    }
  }

  /// Añadir diferentes tipos de líneas
  void addCommandLine(String content) {
    _addLine(
      TerminalLine(
        content: content,
        type: TerminalLineType.command,
        timestamp: DateTime.now(),
      ),
    );
  }

  void addOutputLine(String content) {
    _addLine(
      TerminalLine(
        content: content,
        type: TerminalLineType.output,
        timestamp: DateTime.now(),
      ),
    );
  }

  void addErrorLine(String content) {
    _addLine(
      TerminalLine(
        content: content,
        type: TerminalLineType.error,
        timestamp: DateTime.now(),
      ),
    );
  }

  void addSuccessLine(String content) {
    _addLine(
      TerminalLine(
        content: content,
        type: TerminalLineType.success,
        timestamp: DateTime.now(),
      ),
    );
  }

  void addWarningLine(String content) {
    _addLine(
      TerminalLine(
        content: content,
        type: TerminalLineType.warning,
        timestamp: DateTime.now(),
      ),
    );
  }

  void addInfoLine(String content) {
    _addLine(
      TerminalLine(
        content: content,
        type: TerminalLineType.info,
        timestamp: DateTime.now(),
      ),
    );
  }

  void addProcessLine(String content) {
    _addLine(
      TerminalLine(
        content: '⚙️  $content',
        type: TerminalLineType.process,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Añadir línea y notificar
  void _addLine(TerminalLine line) {
    _terminalLines.add(line);

    // Mantener solo las últimas 1000 líneas
    if (_terminalLines.length > 1000) {
      _terminalLines.removeAt(0);
    }

    _notifyListeners();
  }

  /// Notificar a los oyentes
  void _notifyListeners() {
    _outputController.add(terminalLines);
  }

  /// Limpiar terminal
  void clear() {
    _terminalLines.clear();
    _notifyListeners();
  }

  /// Dispose
  void dispose() {
    _outputController.close();
  }
}

/// Tipos de líneas del terminal
enum TerminalLineType {
  banner,
  command,
  output,
  error,
  success,
  warning,
  info,
  process,
  progress,
}

/// Representación de una línea del terminal
class TerminalLine {
  final String content;
  final TerminalLineType type;
  final DateTime timestamp;

  TerminalLine({
    required this.content,
    required this.type,
    required this.timestamp,
  });

  /// Obtener color según el tipo
  Color get color {
    switch (type) {
      case TerminalLineType.banner:
        return const Color(0xFF00FF41);
      case TerminalLineType.command:
        return const Color(0xFF00FFFF);
      case TerminalLineType.output:
        return const Color(0xFFFFFFFF);
      case TerminalLineType.error:
        return const Color(0xFFFF4444);
      case TerminalLineType.success:
        return const Color(0xFF00FF41);
      case TerminalLineType.warning:
        return const Color(0xFFFFD700);
      case TerminalLineType.info:
        return const Color(0xFF888888);
      case TerminalLineType.process:
        return const Color(0xFF00FFFF);
      case TerminalLineType.progress:
        return const Color(0xFFFFD700);
    }
  }

  /// Obtener timestamp formateado
  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }
}
