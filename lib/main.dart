import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/advanced_initializer_screen.dart';
import 'screens/appbar_demo_screen.dart';
import 'screens/advanced_terminal_screen.dart';
import 'providers/tool_provider.dart';
import 'providers/script_provider.dart';
import 'providers/task_provider.dart';
import 'providers/bluetooth_provider.dart';
import 'providers/platform_provider.dart';
import 'services/advanced_permissions_service.dart';
import 'services/advanced_logging_service.dart';
import 'services/advanced_terminal_service.dart';
import 'utils/theme.dart';

void main() {
  runApp(const HackomaticApp());
}

class HackomaticApp extends StatelessWidget {
  const HackomaticApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ToolProvider()),
        ChangeNotifierProvider(create: (_) => ScriptProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => BluetoothProvider()),
        ChangeNotifierProvider(create: (_) => PlatformProvider()),
        ChangeNotifierProvider(create: (_) => AdvancedTerminalService()),
      ],
      child: MaterialApp(
        title: 'Hackomatic - Advanced Penetration Testing',
        theme: HackomaticTheme.darkTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const HackomaticInitializer(),
          '/home': (context) => const HomeScreen(),
          '/linux-setup': (context) => const AdvancedInitializerScreen(),
          '/appbar-demo': (context) => const AppBarDemoScreen(),
          '/advanced_terminal': (context) => const AdvancedTerminalScreen(),
        },
        debugShowCheckedModeBanner: false,
        // Eliminar completamente el toolbar del sistema
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              // Forzar que no use toolbar del sistema
              systemGestureInsets: EdgeInsets.zero,
            ),
            child: child!,
          );
        },
      ),
    );
  }
}

/// Widget que inicializa la plataforma antes de mostrar la app
class HackomaticInitializer extends StatefulWidget {
  const HackomaticInitializer({super.key});

  @override
  State<HackomaticInitializer> createState() => _HackomaticInitializerState();
}

class _HackomaticInitializerState extends State<HackomaticInitializer> {
  final bool _checkingLinuxSetup = false;
  final bool _showLinuxOnboarding = false;

  @override
  void initState() {
    super.initState();
    // Defer initialization until after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      // 🚀 INICIALIZAR SERVICIOS AVANZADOS PRIMERO
      final loggingService = AdvancedLoggingService.instance;
      await loggingService.initialize();

      loggingService.info(
        'Starting HACKOMATIC initialization with advanced services',
      );

      // Inicializar permisos avanzados
      final permissionsService = AdvancedPermissionsService();
      await permissionsService.initializePermissions();

      loggingService.info('Advanced permissions service initialized');

      // ⚡ SKIP SETUP AUTOMÁTICO - ir directo a home
      final platformProvider = Provider.of<PlatformProvider>(
        context,
        listen: false,
      );
      await platformProvider.initialize();

      loggingService.info('Platform provider initialized');

      // 🚀 FORZAR SALTO DEL SETUP DE LINUX
      if (Platform.isLinux && mounted) {
        // ✅ MARCAR COMO COMPLETO automáticamente sin verificar
        await _markSetupAsComplete();
        loggingService.info('Linux setup marked as complete automatically');
      }

      // ⚡ TRIGGER UPDATE
      if (mounted) {
        setState(() {});
        loggingService.info('App initialization completed successfully');
      }
    } catch (e) {
      final loggingService = AdvancedLoggingService.instance;
      loggingService.error('Error during app initialization', error: e);
    }
  }

  /// ✅ Marcar setup como completo para futuras ejecuciones
  Future<void> _markSetupAsComplete() async {
    try {
      final home =
          Platform.environment['HOME'] ??
          '/home/${Platform.environment['USER']}';
      final skipFile = File('$home/.hackomatic_setup_complete');
      await skipFile.writeAsString(
        'setup_completed_at=${DateTime.now().toIso8601String()}\n'
        'auto_skip=true\n'
        'version=1.0.0',
      );
    } catch (e) {
      // Ignorar errores de archivo
    }
  }

  /// 🚀 Verificar si hay caché disponible
  Future<bool> _getCacheStatus() async {
    try {
      final home = Platform.environment['HOME'] ?? '/tmp';
      final cacheFile = File('$home/.hackomatic_fast_cache');
      final setupFile = File('$home/.hackomatic_setup_complete');

      // Verificar si existe algún tipo de caché
      return await cacheFile.exists() || await setupFile.exists();
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show Linux onboarding if needed
    if (_showLinuxOnboarding) {
      return const AdvancedInitializerScreen();
    }

    return Consumer<PlatformProvider>(
      builder: (context, platformProvider, child) {
        // Show checking Linux setup
        if (_checkingLinuxSetup) {
          return Scaffold(
            backgroundColor: const Color(0xFF0A0A0A),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF00FF41)),
                  const SizedBox(height: 16),
                  Text(
                    'Verificando configuración de Linux... 🐧',
                    style: const TextStyle(
                      color: Color(0xFF00FF41),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (!platformProvider.isInitialized) {
          return Scaffold(
            backgroundColor: const Color(0xFF0A0A0A),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF00FF41)),
                  const SizedBox(height: 16),
                  Text(
                    'Initializing Hackomatic ${platformProvider.platformEmoji}',
                    style: const TextStyle(
                      color: Color(0xFF00FF41),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Platform: ${platformProvider.platformName}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        if (platformProvider.initializationError.isNotEmpty) {
          return Scaffold(
            backgroundColor: const Color(0xFF0A0A0A),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Initialization Failed',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      platformProvider.initializationError,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => platformProvider.initialize(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FF41),
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      // Show debug info
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF1A1A1A),
                          title: const Text(
                            'Debug Information',
                            style: TextStyle(color: Color(0xFF00FF41)),
                          ),
                          content: SingleChildScrollView(
                            child: Text(
                              platformProvider.getDebugInfo(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Close',
                                style: TextStyle(color: Color(0xFF00FF41)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text(
                      'Show Debug Info',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Platform initialization successful but not ready
        if (!platformProvider.isReady) {
          return Scaffold(
            backgroundColor: const Color(0xFF0A0A0A),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: Colors.orange,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Platform Not Ready',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Some features may not work properly',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => platformProvider.refresh(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Check Again'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      // Continue anyway
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    },
                    child: const Text(
                      'Continue Anyway',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Platform ready - show main app
        return Scaffold(
          backgroundColor: const Color(0xFF0A0A0A),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo principal
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF00FF41),
                        const Color(0xFF00FF41).withValues(alpha: 0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00FF41).withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.security,
                    color: Colors.black,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '🚀 HACKOMATIC',
                  style: TextStyle(
                    color: const Color(0xFF00FF41),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    shadows: [
                      Shadow(
                        color: const Color(0xFF00FF41).withValues(alpha: 0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sistema listo ✅',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 40),

                // Botón principal - Ir a HomeScreen
                SizedBox(
                  width: 280,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FF41),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 10,
                    ),
                    icon: const Icon(Icons.home, size: 24),
                    label: const Text(
                      'ENTRAR AL SISTEMA',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Botón demo del AppBar
                SizedBox(
                  width: 280,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AppBarDemoScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00FF41),
                      side: const BorderSide(
                        color: Color(0xFF00FF41),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    icon: const Icon(Icons.preview, size: 20),
                    label: const Text(
                      '🚀 DEMO SUPER APPBAR',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 🚀 Indicador de caché y estado rápido
                FutureBuilder(
                  future: _getCacheStatus(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final hasCache = snapshot.data as bool;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: hasCache
                              ? const Color(0xFF00FF41).withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: hasCache
                                ? const Color(0xFF00FF41).withValues(alpha: 0.3)
                                : Colors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasCache ? Icons.flash_on : Icons.info_outline,
                              color: hasCache
                                  ? const Color(0xFF00FF41)
                                  : Colors.orange,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              hasCache
                                  ? '⚡ Caché disponible - arranque rápido'
                                  : '⚠️ Primera ejecución - se creará caché',
                              style: TextStyle(
                                color: hasCache
                                    ? const Color(0xFF00FF41)
                                    : Colors.orange,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),

                const SizedBox(height: 12),

                // Info adicional
                Text(
                  '✨ AppBar completamente personalizado',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                Text(
                  '🔥 Sin dependencias del sistema operativo',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
