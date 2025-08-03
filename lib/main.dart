import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/advanced_initializer_screen.dart';
import 'screens/appbar_demo_screen.dart';
import 'providers/tool_provider.dart';
import 'providers/script_provider.dart';
import 'providers/task_provider.dart';
import 'providers/bluetooth_provider.dart';
import 'providers/platform_provider.dart';
import 'services/linux_auto_setup_service.dart';
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
      ],
      child: MaterialApp(
        title: 'Hackomatic',
        theme: HackomaticTheme.darkTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const HackomaticInitializer(),
          '/home': (context) => const HomeScreen(),
          '/linux-setup': (context) => const AdvancedInitializerScreen(),
          '/appbar-demo': (context) => const AppBarDemoScreen(),
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
  bool _checkingLinuxSetup = false;
  bool _showLinuxOnboarding = false;

  @override
  void initState() {
    super.initState();
    // Defer initialization until after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    // First initialize platform
    final platformProvider = Provider.of<PlatformProvider>(
      context,
      listen: false,
    );
    await platformProvider.initialize();

    // Check if this is Linux and needs onboarding
    if (Platform.isLinux && mounted) {
      setState(() {
        _checkingLinuxSetup = true;
      });

      final linuxSetup = LinuxAutoSetupService();

      // Check if setup is already complete
      final isSetupComplete = linuxSetup.isSetupComplete;

      if (!isSetupComplete) {
        setState(() {
          _showLinuxOnboarding = true;
          _checkingLinuxSetup = false;
        });
        return;
      }

      setState(() {
        _checkingLinuxSetup = false;
      });
    }

    // Trigger rebuild after initialization is complete
    if (mounted) {
      setState(() {});
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
                        const Color(0xFF00FF41).withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00FF41).withOpacity(0.5),
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
                        color: const Color(0xFF00FF41).withOpacity(0.5),
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
                      side: BorderSide(
                        color: const Color(0xFF00FF41),
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
