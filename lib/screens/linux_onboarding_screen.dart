import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/linux_setup_service.dart';
import '../utils/theme.dart';

/// Pantalla de onboarding específica para Linux
/// Guía al usuario a través del proceso de auto-instalación
class LinuxOnboardingScreen extends StatefulWidget {
  const LinuxOnboardingScreen({super.key});

  @override
  State<LinuxOnboardingScreen> createState() => _LinuxOnboardingScreenState();
}

class _LinuxOnboardingScreenState extends State<LinuxOnboardingScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late PageController _pageController;

  int _currentPage = 0;
  bool _isSetupRunning = false;
  bool _isSetupComplete = false;
  Map<String, dynamic> _setupSummary = {};
  List<String> _setupSteps = [];

  final LinuxSetupService _setupService = LinuxSetupService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _pageController = PageController();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// Ejecutar el setup automático de Linux
  Future<void> _runLinuxSetup() async {
    setState(() {
      _isSetupRunning = true;
      _setupSteps.clear();
    });

    try {
      final success = await _setupService.initializeLinuxSetup();

      setState(() {
        _isSetupRunning = false;
        _isSetupComplete = success;
        _setupSummary = _setupService.getSetupSummary();
        _setupSteps = _setupService.setupSteps;
      });

      if (success) {
        _nextPage();
      }
    } catch (e) {
      setState(() {
        _isSetupRunning = false;
        _setupSteps.add('❌ Error en setup: $e');
      });
    }
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _currentPage++;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          children: [
            _buildWelcomePage(),
            _buildPreparationPage(),
            _buildSetupPage(),
            _buildCompletionPage(),
          ],
        ),
      ),
    );
  }

  /// Página de bienvenida
  Widget _buildWelcomePage() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo/Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(60),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.security, size: 60, color: Colors.white),
          ),

          const SizedBox(height: 40),

          Text(
            '¡Bienvenido a Hackomatic!',
            style: AppTheme.titleLarge.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          Text(
            'Tu suite completa de hacking ético para Linux',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // Características principales
          _buildFeaturesList(),

          const SizedBox(height: 60),

          // Botón continuar
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Comenzar Setup',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.arrow_forward_rounded, size: 24),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Indicador de páginas
          _buildPageIndicator(),
        ],
      ),
    );
  }

  /// Lista de características principales
  Widget _buildFeaturesList() {
    final features = [
      '🚀 Auto-instalación de herramientas',
      '🔧 Configuración automática',
      '📡 Detección inteligente de red',
      '🐧 Optimizado para Linux',
      '⚡ Scripts sin parámetros',
      '🎯 Listo para usar',
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Text(feature.split(' ')[0], style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  feature.substring(feature.indexOf(' ') + 1),
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Página de preparación del sistema
  Widget _buildPreparationPage() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build_circle, size: 100, color: AppTheme.primaryColor),

          const SizedBox(height: 40),

          Text(
            'Preparación del Sistema',
            style: AppTheme.titleLarge.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          Text(
            'Vamos a configurar tu sistema Linux para hacking ético',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // Lista de preparaciones
          _buildPreparationList(),

          const SizedBox(height: 60),

          // Botones de navegación
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousPage,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Atrás'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    _nextPage();
                    // Auto-iniciar setup después de un breve delay
                    Future.delayed(const Duration(milliseconds: 500), () {
                      _runLinuxSetup();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Configurar Automáticamente',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.auto_fix_high),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          _buildPageIndicator(),
        ],
      ),
    );
  }

  /// Lista de preparaciones del sistema
  Widget _buildPreparationList() {
    final preparations = [
      {
        'title': 'Detección de Distribución',
        'description': 'Identificar tu distribución Linux',
        'icon': Icons.computer,
      },
      {
        'title': 'Package Manager',
        'description': 'Configurar gestor de paquetes (apt, dnf, pacman)',
        'icon': Icons.package_2,
      },
      {
        'title': 'Herramientas de Hacking',
        'description': 'Instalar nmap, nikto, hydra, aircrack-ng y más',
        'icon': Icons.construction,
      },
      {
        'title': 'Permisos y Configuración',
        'description':
            'Configurar permisos para Wireshark y otras herramientas',
        'icon': Icons.admin_panel_settings,
      },
      {
        'title': 'Estructura de Directorios',
        'description': 'Crear directorios de trabajo y configuración',
        'icon': Icons.folder,
      },
    ];

    return Column(
      children: preparations.map((prep) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          color: AppTheme.cardColor,
          elevation: 4,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              child: Icon(
                prep['icon'] as IconData,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              prep['title'] as String,
              style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              prep['description'] as String,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Página de proceso de setup
  Widget _buildSetupPage() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Indicador de progreso
          if (_isSetupRunning)
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              strokeWidth: 6,
            )
          else if (_isSetupComplete)
            Icon(Icons.check_circle, size: 100, color: AppTheme.successColor)
          else
            Icon(Icons.error_outline, size: 100, color: AppTheme.dangerColor),

          const SizedBox(height: 40),

          Text(
            _isSetupRunning
                ? 'Configurando Sistema...'
                : _isSetupComplete
                ? '¡Configuración Completada!'
                : 'Error en Configuración',
            style: AppTheme.titleLarge.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _isSetupRunning
                  ? AppTheme.textPrimary
                  : _isSetupComplete
                  ? AppTheme.successColor
                  : AppTheme.dangerColor,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          if (_isSetupRunning)
            Text(
              'Por favor espera mientras configuramos tu sistema...',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

          const SizedBox(height: 40),

          // Log de progreso
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _setupSteps.map((step) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        step,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Botones de acción
          if (!_isSetupRunning) ...[
            if (_isSetupComplete)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continuar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.arrow_forward_rounded),
                    ],
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousPage,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Atrás'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _runLinuxSetup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Reintentar'),
                    ),
                  ),
                ],
              ),
          ],

          const SizedBox(height: 20),
          _buildPageIndicator(),
        ],
      ),
    );
  }

  /// Página de finalización
  Widget _buildCompletionPage() {
    final summary = _setupSummary;
    final installedCount = summary['tools_installed'] ?? 0;
    final totalCount = summary['tools_total'] ?? 0;
    final percentage = summary['completion_percentage'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icono de éxito
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.successColor,
              borderRadius: BorderRadius.circular(60),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.successColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.rocket_launch,
              size: 60,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 40),

          Text(
            '¡Todo Listo!',
            style: AppTheme.titleLarge.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.successColor,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          Text(
            'Tu sistema Linux está configurado y listo para hacking ético',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // Resumen de instalación
          Card(
            color: AppTheme.cardColor,
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Herramientas Instaladas:',
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$installedCount/$totalCount',
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$percentage% completado',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Próximos pasos
          _buildNextSteps(),

          const SizedBox(height: 60),

          // Botón finalizar
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                // Navegar a la pantalla principal
                Navigator.of(context).pushReplacementNamed('/home');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Comenzar a Hackear',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.security, size: 24),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          _buildPageIndicator(),
        ],
      ),
    );
  }

  /// Próximos pasos después del setup
  Widget _buildNextSteps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Próximos Pasos:',
          style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        _buildStepItem(
          '1',
          'Explora los scripts automáticos',
          Icons.auto_fix_high,
        ),
        _buildStepItem('2', 'Configura tus targets favoritos', Icons.gps_fixed),
        _buildStepItem('3', 'Revisa los logs y resultados', Icons.analytics),
        _buildStepItem('4', 'Personaliza las herramientas', Icons.settings),
      ],
    );
  }

  Widget _buildStepItem(String number, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor,
            radius: 16,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTheme.bodyMedium)),
        ],
      ),
    );
  }

  /// Indicador de páginas
  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == _currentPage
                ? AppTheme.primaryColor
                : AppTheme.primaryColor.withOpacity(0.3),
          ),
        );
      }),
    );
  }
}
