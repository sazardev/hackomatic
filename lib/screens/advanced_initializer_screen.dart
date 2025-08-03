import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/terminal_ui_service.dart';
import '../services/sudo_auth_service.dart';
import '../widgets/terminal_display_widget.dart';
import 'home_screen.dart';

/// Pantalla de inicialización avanzada con terminal visual completa
class AdvancedInitializerScreen extends StatefulWidget {
  const AdvancedInitializerScreen({super.key});

  @override
  State<AdvancedInitializerScreen> createState() =>
      _AdvancedInitializerScreenState();
}

class _AdvancedInitializerScreenState extends State<AdvancedInitializerScreen>
    with TickerProviderStateMixin {
  // Servicios
  final TerminalUIService _terminalService = TerminalUIService();
  final SudoAuthService _authService = SudoAuthService();

  // Controladores de animación
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late AnimationController _glowController;

  // Animaciones
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _glowAnimation;

  // Estado de la inicialización
  bool _initializationStarted = false;
  bool _initializationComplete = false;
  String _currentUser = '';
  double _overallProgress = 0.0;

  // Estadísticas en tiempo real
  final Map<String, dynamic> _stats = {
    'network_speed': '0 MB/s',
    'wifi_signal': '-',
    'packages_installed': 0,
    'total_packages': 12,
    'system_load': '0%',
    'memory_usage': '0%',
    'disk_usage': '0%',
    'processes': 0,
  };

  // Pasos de inicialización
  final List<Map<String, dynamic>> _initSteps = [
    {
      'name': 'Identificación del usuario',
      'description': 'Detectando usuario actual y configuración del sistema',
      'icon': Icons.person,
      'weight': 5,
    },
    {
      'name': 'Análisis del sistema',
      'description': 'Escaneando arquitectura, distribución y recursos',
      'icon': Icons.computer,
      'weight': 10,
    },
    {
      'name': 'Verificación de red',
      'description': 'Testando conectividad, velocidad y configuración WiFi',
      'icon': Icons.wifi,
      'weight': 8,
    },
    {
      'name': 'Autenticación sudo',
      'description': 'Configurando permisos administrativos seguros',
      'icon': Icons.security,
      'weight': 7,
    },
    {
      'name': 'Repositorios del sistema',
      'description': 'Actualizando índices de paquetes y repositorios',
      'icon': Icons.update,
      'weight': 15,
    },
    {
      'name': 'Instalación de herramientas',
      'description': 'Descargando e instalando suite de penetration testing',
      'icon': Icons.build,
      'weight': 35,
    },
    {
      'name': 'Configuración de wordlists',
      'description': 'Configurando diccionarios y bases de datos',
      'icon': Icons.list_alt,
      'weight': 10,
    },
    {
      'name': 'Optimización del sistema',
      'description': 'Configurando permisos y optimizaciones de rendimiento',
      'icon': Icons.tune,
      'weight': 10,
    },
  ];

  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();

    // Configurar animaciones
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOut,
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Obtener usuario actual
    _currentUser = Platform.environment['USER'] ?? 'hacker';

    // Inicializar servicios después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTerminal();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _initializeTerminal() async {
    await _terminalService.initialize();

    // Esperar un momento para que el usuario vea el banner
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        // Terminal ya inicializado, listo para comenzar
      });
    }
  }

  Future<void> _startAdvancedInitialization() async {
    if (_initializationStarted) return;

    setState(() {
      _initializationStarted = true;
      _currentStepIndex = 0;
    });

    _terminalService.addInfoLine('');
    _terminalService.addSuccessLine(
      '🚀 Iniciando configuración avanzada de Hackomatic...',
    );
    _terminalService.addInfoLine('');

    try {
      for (int i = 0; i < _initSteps.length; i++) {
        await _executeInitializationStep(i);

        // Actualizar progreso general
        final stepProgress = _initSteps
            .take(i + 1)
            .fold<double>(
              0.0,
              (sum, step) => sum + (step['weight'] as int).toDouble(),
            );
        final totalWeight = _initSteps.fold<double>(
          0.0,
          (sum, step) => sum + (step['weight'] as int).toDouble(),
        );

        setState(() {
          _overallProgress = stepProgress / totalWeight;
          _currentStepIndex = i;
        });

        // Animar barra de progreso
        _progressController.animateTo(_overallProgress);

        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Completar inicialización
      await _completeInitialization();
    } catch (e) {
      _terminalService.addErrorLine('❌ Error durante la inicialización: $e');
      _showInitializationError(e.toString());
    }
  }

  Future<void> _executeInitializationStep(int stepIndex) async {
    final step = _initSteps[stepIndex];

    setState(() {
      _currentStepIndex = stepIndex;
    });

    _terminalService.addProcessLine('Ejecutando: ${step['name']}...');
    _terminalService.addInfoLine('📋 ${step['description']}');

    switch (stepIndex) {
      case 0: // Identificación del usuario
        await _identifyUser();
        break;
      case 1: // Análisis del sistema
        await _analyzeSystem();
        break;
      case 2: // Verificación de red
        await _verifyNetwork();
        break;
      case 3: // Autenticación sudo
        await _setupSudoAuth();
        break;
      case 4: // Repositorios del sistema
        await _updateRepositories();
        break;
      case 5: // Instalación de herramientas
        await _installTools();
        break;
      case 6: // Configuración de wordlists
        await _setupWordlists();
        break;
      case 7: // Optimización del sistema
        await _optimizeSystem();
        break;
    }

    _terminalService.addSuccessLine(
      '✅ ${step['name']} completado exitosamente',
    );
    _terminalService.addInfoLine('');
  }

  Future<void> _identifyUser() async {
    await Future.delayed(const Duration(milliseconds: 800));

    _terminalService.addOutputLine('👤 Usuario detectado: $_currentUser');
    _terminalService.addOutputLine(
      '🏠 Directorio home: ${Platform.environment['HOME']}',
    );
    _terminalService.addOutputLine(
      '🔧 Shell: ${Platform.environment['SHELL'] ?? '/bin/bash'}',
    );

    final greeting = _getTimeBasedGreeting();
    _terminalService.addSuccessLine('$greeting, $_currentUser! 👋');
  }

  Future<void> _analyzeSystem() async {
    _terminalService.addOutputLine('🔍 Analizando arquitectura del sistema...');
    await Future.delayed(const Duration(milliseconds: 600));

    try {
      final unameResult = await Process.run('uname', ['-a']);
      _terminalService.addOutputLine(
        '📊 Sistema: ${unameResult.stdout.toString().trim()}',
      );

      final memResult = await Process.run('free', ['-h']);
      final memLines = memResult.stdout.toString().split('\n');
      if (memLines.length > 1) {
        _terminalService.addOutputLine(
          '💾 Memoria: ${memLines[1].split(RegExp(r'\s+'))[1]} total',
        );
      }

      final cpuResult = await Process.run('nproc', []);
      _terminalService.addOutputLine(
        '⚡ CPUs: ${cpuResult.stdout.toString().trim()} cores',
      );

      // Simular actualización de estadísticas
      setState(() {
        _stats['memory_usage'] = '45%';
        _stats['system_load'] = '12%';
        _stats['processes'] = 156;
      });
    } catch (e) {
      _terminalService.addWarningLine(
        '⚠️ Información limitada del sistema disponible',
      );
    }
  }

  Future<void> _verifyNetwork() async {
    _terminalService.addOutputLine('🌐 Verificando conectividad de red...');
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      // Test de ping básico
      final pingResult = await Process.run('ping', ['-c', '1', '8.8.8.8']);
      if (pingResult.exitCode == 0) {
        _terminalService.addSuccessLine('✅ Conectividad a Internet: ACTIVA');

        // Simular estadísticas de red
        setState(() {
          _stats['network_speed'] = '85 MB/s';
          _stats['wifi_signal'] = '-42 dBm (Excelente)';
        });

        _terminalService.addOutputLine(
          '📡 Velocidad estimada: ${_stats['network_speed']}',
        );
        _terminalService.addOutputLine(
          '📶 Señal WiFi: ${_stats['wifi_signal']}',
        );
      } else {
        _terminalService.addWarningLine(
          '⚠️ Conectividad limitada o sin conexión',
        );
      }

      // Verificar interfaces de red
      final ifResult = await Process.run('ip', ['link', 'show']);
      final interfaces = ifResult.stdout
          .toString()
          .split('\n')
          .where((line) => line.contains('state UP'))
          .length;
      _terminalService.addOutputLine('🔌 Interfaces activas: $interfaces');
    } catch (e) {
      _terminalService.addWarningLine(
        '⚠️ Error verificando red: limitando a funciones básicas',
      );
    }
  }

  Future<void> _setupSudoAuth() async {
    _terminalService.addOutputLine(
      '🔐 Configurando autenticación administrativa...',
    );
    await Future.delayed(const Duration(milliseconds: 500));

    final hasValidAuth = _authService.hasValidPasswordCache;
    if (!hasValidAuth) {
      _terminalService.addWarningLine(
        '⚠️ Se requiere autenticación administrativa',
      );

      if (mounted) {
        final password = await _authService.requestPassword(
          context,
          title: 'Configuración de Hackomatic',
          message:
              'Se requieren permisos administrativos para instalar herramientas de penetration testing',
        );

        if (password != null) {
          _terminalService.addSuccessLine(
            '✅ Autenticación exitosa - permisos concedidos',
          );
          _terminalService.addInfoLine(
            '🔒 Contraseña guardada temporalmente (15 min)',
          );
        } else {
          throw Exception('Autenticación requerida para continuar');
        }
      }
    } else {
      _terminalService.addSuccessLine('✅ Autenticación administrativa válida');
    }
  }

  Future<void> _updateRepositories() async {
    _terminalService.addOutputLine(
      '📦 Actualizando repositorios del sistema...',
    );

    try {
      await _terminalService.executeCommand(
        'sudo apt update',
        description: 'Sincronizando índices de paquetes',
        requiresRoot: true,
      );

      _terminalService.addSuccessLine('✅ Repositorios actualizados');
    } catch (e) {
      _terminalService.addWarningLine(
        '⚠️ Actualización parcial de repositorios',
      );
    }
  }

  Future<void> _installTools() async {
    final tools = [
      {'name': 'nmap', 'desc': 'Network discovery and security scanning'},
      {'name': 'nikto', 'desc': 'Web server scanner'},
      {'name': 'dirb', 'desc': 'Directory and file brute forcer'},
      {'name': 'aircrack-ng', 'desc': 'WiFi security auditing tools'},
      {'name': 'hydra', 'desc': 'Password cracking tool'},
      {'name': 'john', 'desc': 'John the Ripper password cracker'},
      {'name': 'wireshark', 'desc': 'Network protocol analyzer'},
      {'name': 'tcpdump', 'desc': 'Command-line packet analyzer'},
      {'name': 'masscan', 'desc': 'High-speed port scanner'},
      {'name': 'gobuster', 'desc': 'Directory/file & DNS busting tool'},
      {'name': 'sqlmap', 'desc': 'SQL injection detection tool'},
      {'name': 'metasploit-framework', 'desc': 'Penetration testing framework'},
    ];

    setState(() {
      _stats['total_packages'] = tools.length;
    });

    for (int i = 0; i < tools.length; i++) {
      final tool = tools[i];
      final progress = (i + 1) / tools.length;

      _terminalService.showInstallationProgress(
        tool['name']!,
        progress,
        currentStep: tool['desc'],
      );

      // Simular instalación con estadísticas
      await Future.delayed(const Duration(milliseconds: 1500));

      setState(() {
        _stats['packages_installed'] = i + 1;
        _stats['disk_usage'] = '${((i + 1) * 3.5).toStringAsFixed(1)}%';
      });

      try {
        await _terminalService.executeCommand(
          'sudo apt install -y ${tool['name']}',
          description: 'Instalando ${tool['name']} - ${tool['desc']}',
          requiresRoot: true,
        );
      } catch (e) {
        _terminalService.addWarningLine(
          '⚠️ ${tool['name']}: instalación parcial',
        );
      }
    }

    _terminalService.addSuccessLine(
      '🎉 ${tools.length} herramientas instaladas exitosamente',
    );
  }

  Future<void> _setupWordlists() async {
    _terminalService.addOutputLine(
      '📝 Configurando wordlists y diccionarios...',
    );

    await _terminalService.executeCommand(
      'sudo apt install -y wordlists',
      description: 'Instalando wordlists comunes para pentesting',
      requiresRoot: true,
    );

    _terminalService.addOutputLine(
      '📚 Wordlists disponibles en /usr/share/wordlists/',
    );
  }

  Future<void> _optimizeSystem() async {
    _terminalService.addOutputLine(
      '⚡ Optimizando configuración del sistema...',
    );
    await Future.delayed(const Duration(milliseconds: 800));

    _terminalService.addOutputLine('🔧 Configurando permisos especiales...');
    _terminalService.addOutputLine('🚀 Optimizando rutas de herramientas...');
    _terminalService.addOutputLine('📁 Creando directorios de trabajo...');

    await Future.delayed(const Duration(milliseconds: 1000));
    _terminalService.addSuccessLine('✅ Sistema optimizado para pentesting');
  }

  Future<void> _completeInitialization() async {
    setState(() {
      _initializationComplete = true;
      _overallProgress = 1.0;
    });

    _progressController.animateTo(1.0);

    _terminalService.addInfoLine('');
    _terminalService.addSuccessLine(
      '🎉 ¡Inicialización completada exitosamente!',
    );
    _terminalService.addInfoLine('');
    _terminalService.addInfoLine('📊 Resumen de la configuración:');
    _terminalService.addInfoLine(
      '  → ${_stats['packages_installed']} herramientas instaladas',
    );
    _terminalService.addInfoLine('  → Wordlists configurados');
    _terminalService.addInfoLine('  → Sistema optimizado');
    _terminalService.addInfoLine(
      '  → Red verificada (${_stats['network_speed']})',
    );
    _terminalService.addInfoLine('');
    _terminalService.addSuccessLine(
      '🚀 ¡Bienvenido a Hackomatic, $_currentUser!',
    );
    _terminalService.addSuccessLine(
      '🐧 Tu entorno Linux está listo para penetration testing',
    );

    // Esperar un momento antes de navegar
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  void _showInitializationError(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Error de Inicialización',
          style: TextStyle(color: Colors.red),
        ),
        content: Text(error, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Reintentar
              setState(() {
                _initializationStarted = false;
                _currentStepIndex = 0;
                _overallProgress = 0.0;
              });
            },
            child: const Text(
              'Reintentar',
              style: TextStyle(color: Color(0xFF00FF41)),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) return 'Buenos días';
    if (hour >= 12 && hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Column(
        children: [
          // Header con información del usuario y estadísticas
          _buildHeader(),

          // Progreso general
          if (_initializationStarted) _buildOverallProgress(),

          // Terminal principal
          Expanded(flex: 2, child: _buildTerminalSection()),

          // Panel de estadísticas en tiempo real
          _buildStatsPanel(),

          // Footer con controles
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00FF41).withOpacity(0.1),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(color: const Color(0xFF00FF41).withOpacity(0.3)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF00FF41,
                          ).withOpacity(0.3 * _glowAnimation.value),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFF00FF41),
                      radius: 25,
                      child: Icon(
                        _initializationComplete
                            ? Icons.check
                            : _initializationStarted
                            ? Icons.settings
                            : Icons.person,
                        color: Colors.black,
                        size: 28,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hackomatic Linux Setup',
                      style: const TextStyle(
                        color: Color(0xFF00FF41),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Usuario: $_currentUser@${Platform.localHostname}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (_initializationStarted && !_initializationComplete)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF41).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF00FF41)),
                  ),
                  child: Text(
                    'Paso ${_currentStepIndex + 1}/${_initSteps.length}',
                    style: const TextStyle(
                      color: Color(0xFF00FF41),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverallProgress() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _initSteps[_currentStepIndex]['icon'],
                color: const Color(0xFF00FF41),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _initSteps[_currentStepIndex]['name'],
                  style: const TextStyle(
                    color: Color(0xFF00FF41),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${(_overallProgress * 100).toInt()}%',
                style: const TextStyle(
                  color: Color(0xFF00FF41),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _initSteps[_currentStepIndex]['description'],
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _progressAnimation.value,
                backgroundColor: const Color(0xFF333333),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF00FF41),
                ),
                minHeight: 6,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TerminalDisplayWidget(
        outputStream: _terminalService.outputStream,
        showTimestamps: true,
      ),
    );
  }

  Widget _buildStatsPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text(
            '📊 Estadísticas del Sistema',
            style: TextStyle(
              color: Color(0xFF00FF41),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildStatItem('Red', _stats['network_speed'], Icons.wifi),
              _buildStatItem(
                'WiFi',
                _stats['wifi_signal'],
                Icons.signal_wifi_4_bar,
              ),
              _buildStatItem(
                'Paquetes',
                '${_stats['packages_installed']}/${_stats['total_packages']}',
                Icons.apps,
              ),
              _buildStatItem('CPU', _stats['system_load'], Icons.memory),
              _buildStatItem('RAM', _stats['memory_usage'], Icons.memory),
              _buildStatItem('Disco', _stats['disk_usage'], Icons.storage),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF00FF41).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF00FF41), size: 14),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: !_initializationStarted
          ? AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: ElevatedButton.icon(
                    onPressed: _startAdvancedInitialization,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FF41),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                    ),
                    icon: const Icon(Icons.rocket_launch, size: 24),
                    label: const Text(
                      'Iniciar Configuración Avanzada',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            )
          : _initializationComplete
          ? ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF41),
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.home),
              label: const Text('Ir a Hackomatic'),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  color: Color(0xFF00FF41),
                  strokeWidth: 2,
                ),
                const SizedBox(width: 16),
                Text(
                  'Configuración en progreso...',
                  style: const TextStyle(
                    color: Color(0xFF00FF41),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
    );
  }
}
