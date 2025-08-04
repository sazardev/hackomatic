import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/linux_auto_setup_service.dart';
import '../providers/platform_provider.dart';
import 'home_screen.dart';

class LinuxAutoSetupScreen extends StatefulWidget {
  const LinuxAutoSetupScreen({super.key});

  @override
  State<LinuxAutoSetupScreen> createState() => _LinuxAutoSetupScreenState();
}

class _LinuxAutoSetupScreenState extends State<LinuxAutoSetupScreen>
    with TickerProviderStateMixin {
  final LinuxAutoSetupService _setupService = LinuxAutoSetupService();

  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;

  bool _setupStarted = false;
  bool _setupComplete = false;
  bool _showAdvanced = false;
  String _currentStep = '';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _checkSetupStatus();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _checkSetupStatus() {
    if (_setupService.isSetupComplete) {
      setState(() {
        _setupComplete = true;
        _progress = 100.0;
        _currentStep = '¡Configuración completa!';
      });
    }
  }

  Future<void> _startAutoSetup() async {
    if (_setupStarted) return;

    setState(() {
      _setupStarted = true;
      _currentStep = 'Iniciando configuración automática...';
    });

    // Monitorear progreso en tiempo real
    _monitorSetupProgress();

    try {
      final success = await _setupService.initializeLinuxSetup();

      setState(() {
        _setupComplete = success;
        if (success) {
          _currentStep = '¡Configuración completada exitosamente!';
          _progress = 100.0;
        } else {
          _currentStep = 'Error en la configuración';
        }
      });

      if (success) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          _navigateToHome();
        }
      }
    } catch (e) {
      setState(() {
        _currentStep = 'Error: $e';
      });
    }
  }

  void _monitorSetupProgress() {
    // Actualizar progreso cada 500ms
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted && _setupStarted && !_setupComplete) {
        setState(() {
          _progress = _setupService.setupProgress;
          _currentStep = _setupService.currentStep;
        });

        _progressController.animateTo(_progress / 100.0);
        return true;
      }
      return false;
    });
  }

  void _navigateToHome() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  void _skipSetup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          '⚠️ Saltar Configuración',
          style: TextStyle(color: Color(0xFF00FF41)),
        ),
        content: const Text(
          'Sin la configuración automática, muchas herramientas de pentesting no estarán disponibles. ¿Estás seguro?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToHome();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Continuar sin configurar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),

              const SizedBox(height: 32),

              // Main content
              Expanded(
                child: _setupStarted ? _buildSetupProgress() : _buildWelcome(),
              ),

              // Footer buttons
              _buildFooterButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF41).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFF00FF41), width: 2),
                ),
                child: const Icon(
                  Icons.computer,
                  color: Color(0xFF00FF41),
                  size: 30,
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
              const Text(
                'Hackomatic Linux',
                style: TextStyle(
                  color: Color(0xFF00FF41),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '🐧 Configuración Automática de Pentesting',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWelcome() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¡Bienvenido al entorno de Pentesting más completo! 🚀',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Configuración automática incluye:',
            style: TextStyle(
              color: Color(0xFF00FF41),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          ..._buildFeatureList(),

          const SizedBox(height: 32),

          if (_showAdvanced) _buildAdvancedInfo(),

          const SizedBox(height: 24),

          _buildSystemInfo(),
        ],
      ),
    );
  }

  List<Widget> _buildFeatureList() {
    final features = [
      {
        'icon': '🔍',
        'title': 'Herramientas de Escaneo',
        'description': 'Nmap, Masscan, Dirb, Gobuster',
      },
      {
        'icon': '📡',
        'title': 'Análisis Wireless',
        'description': 'Aircrack-ng suite completa',
      },
      {
        'icon': '🌐',
        'title': 'Testing Web',
        'description': 'Nikto, SQLMap, Burp Suite',
      },
      {
        'icon': '🔐',
        'title': 'Cracking de Passwords',
        'description': 'John the Ripper, Hydra',
      },
      {
        'icon': '📊',
        'title': 'Análisis de Red',
        'description': 'Wireshark, TCPDump',
      },
      {
        'icon': '⚙️',
        'title': 'Configuración Automática',
        'description': 'Directorios, permisos, wordlists',
      },
    ];

    return features
        .map(
          (feature) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text(feature['icon']!, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature['title']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        feature['description']!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  Widget _buildAdvancedInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00FF41).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔧 Información Técnica',
            style: TextStyle(
              color: Color(0xFF00FF41),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '• Detección automática de distribución Linux\n'
            '• Instalación vía gestor de paquetes nativo\n'
            '• Configuración de permisos y directorios\n'
            '• Verificación de herramientas instaladas\n'
            '• Descarga de wordlists básicas\n'
            '• Configuración de entorno de trabajo',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfo() {
    return Consumer<PlatformProvider>(
      builder: (context, platformProvider, child) {
        final systemInfo = platformProvider.systemInfo;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📋 Información del Sistema',
                style: TextStyle(
                  color: Color(0xFF00FF41),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'SO: ${systemInfo['platform'] ?? 'Linux'}\n'
                'Versión: ${systemInfo['version'] ?? 'Detectando...'}\n'
                'Red: ${systemInfo['network']?['local_ip'] ?? 'Detectando...'}\n'
                'Estado: ${platformProvider.isReady ? '✅ Listo' : '⚠️ Requiere configuración'}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSetupProgress() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Progress indicator
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF00FF41).withValues(alpha: 0.3),
              width: 3,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: _progress / 100.0,
                    strokeWidth: 6,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF00FF41),
                    ),
                  ),
                ),
              ),
              Center(
                child: Text(
                  '${_progress.toInt()}%',
                  style: const TextStyle(
                    color: Color(0xFF00FF41),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        Text(
          _currentStep,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),

        // Installation details
        if (_setupService.installedTools.isNotEmpty)
          _buildInstallationDetails(),
      ],
    );
  }

  Widget _buildInstallationDetails() {
    final installedCount = _setupService.installedTools.length;
    final totalCount = 12; // Total tools from LinuxAutoSetupService

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '🛠️ Herramientas: $installedCount/$totalCount instaladas',
            style: const TextStyle(
              color: Color(0xFF00FF41),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (_setupService.failedTools.isNotEmpty)
            Text(
              'Fallos: ${_setupService.failedTools.join(', ')}',
              style: const TextStyle(color: Colors.orange, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildFooterButtons() {
    if (_setupComplete) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _navigateToHome,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00FF41),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.rocket_launch),
          label: const Text(
            '¡Comenzar Pentesting!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    if (_setupStarted) {
      return Container(); // No buttons during setup
    }

    return Column(
      children: [
        // Advanced options toggle
        TextButton(
          onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
          child: Text(
            _showAdvanced
                ? 'Ocultar detalles técnicos'
                : 'Ver detalles técnicos',
            style: const TextStyle(color: Colors.white70),
          ),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            // Skip button
            Expanded(
              child: OutlinedButton(
                onPressed: _skipSetup,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.orange),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Saltar',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Setup button
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _startAutoSetup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF41),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.settings),
                label: const Text(
                  'Configurar Automáticamente',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
