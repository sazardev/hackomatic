import 'package:flutter/material.dart';
import '../widgets/enhanced_custom_app_bar.dart';

/// 🚀 PANTALLA DE DEMOSTRACIÓN DEL SUPER APPBAR
/// Muestra todas las funcionalidades avanzadas del nuevo AppBar personalizado
class AppBarDemoScreen extends StatefulWidget {
  const AppBarDemoScreen({super.key});

  @override
  State<AppBarDemoScreen> createState() => _AppBarDemoScreenState();
}

class _AppBarDemoScreenState extends State<AppBarDemoScreen> {
  int _currentDemo = 0;

  final List<String> _demoSections = [
    'Dashboard Principal',
    'Herramientas Avanzadas',
    'Scripts de Penetración',
    'Análisis de Red',
    'Monitoreo de Sistema',
    'Terminal Integrada',
  ];

  final List<List<EnhancedBreadcrumbItem>> _demoBreadcrumbs = [
    // Dashboard
    [
      EnhancedBreadcrumbItem(
        title: 'Home',
        route: '/',
        icon: Icons.home,
        isActive: false,
        color: Colors.blue,
      ),
      EnhancedBreadcrumbItem(
        title: 'Dashboard',
        route: '/dashboard',
        icon: Icons.dashboard,
        isActive: true,
        color: Colors.green,
        subtitle: 'Vista principal',
      ),
    ],
    // Herramientas
    [
      EnhancedBreadcrumbItem(
        title: 'Home',
        route: '/',
        icon: Icons.home,
        isActive: false,
      ),
      EnhancedBreadcrumbItem(
        title: 'Tools',
        route: '/tools',
        icon: Icons.build,
        isActive: false,
        color: Colors.orange,
      ),
      EnhancedBreadcrumbItem(
        title: 'Avanzadas',
        route: '/tools/advanced',
        icon: Icons.engineering,
        isActive: true,
        color: Colors.red,
        subtitle: 'Herramientas pro',
      ),
    ],
    // Scripts
    [
      EnhancedBreadcrumbItem(
        title: 'Home',
        route: '/',
        icon: Icons.home,
        isActive: false,
      ),
      EnhancedBreadcrumbItem(
        title: 'Scripts',
        route: '/scripts',
        icon: Icons.code,
        isActive: false,
        color: Colors.purple,
      ),
      EnhancedBreadcrumbItem(
        title: 'Penetración',
        route: '/scripts/pentest',
        icon: Icons.security,
        isActive: true,
        color: Colors.pink,
        subtitle: 'Pentesting',
      ),
    ],
    // Análisis de Red
    [
      EnhancedBreadcrumbItem(
        title: 'Home',
        route: '/',
        icon: Icons.home,
        isActive: false,
      ),
      EnhancedBreadcrumbItem(
        title: 'Network',
        route: '/network',
        icon: Icons.network_check,
        isActive: false,
        color: Colors.cyan,
      ),
      EnhancedBreadcrumbItem(
        title: 'Análisis',
        route: '/network/analysis',
        icon: Icons.analytics,
        isActive: true,
        color: Colors.teal,
        subtitle: 'Análisis de red',
      ),
    ],
    // Monitoreo
    [
      EnhancedBreadcrumbItem(
        title: 'Home',
        route: '/',
        icon: Icons.home,
        isActive: false,
      ),
      EnhancedBreadcrumbItem(
        title: 'System',
        route: '/system',
        icon: Icons.computer,
        isActive: false,
        color: Colors.indigo,
      ),
      EnhancedBreadcrumbItem(
        title: 'Monitor',
        route: '/system/monitor',
        icon: Icons.monitor,
        isActive: true,
        color: Colors.deepPurple,
        subtitle: 'Monitoreo live',
      ),
    ],
    // Terminal
    [
      EnhancedBreadcrumbItem(
        title: 'Home',
        route: '/',
        icon: Icons.home,
        isActive: false,
      ),
      EnhancedBreadcrumbItem(
        title: 'Terminal',
        route: '/terminal',
        icon: Icons.terminal,
        isActive: true,
        color: Colors.green,
        subtitle: 'Terminal integrada',
      ),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: EnhancedHackomaticAppBar(
        currentSection: _demoSections[_currentDemo],
        breadcrumbs: _demoBreadcrumbs[_currentDemo],
        showRealTimeStats: true,
        showNotifications: true,
        showQuickActions: true,
        onMenuPressed: () {
          _showMenuDemo();
        },
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
          ),
        ),
        child: Column(
          children: [
            // Panel de control de demostración
            _buildDemoControls(),

            // Contenido principal
            Expanded(child: _buildDemoContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoControls() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF41).withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.play_circle_fill,
                color: const Color(0xFF00FF41),
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                '🚀 DEMO del Super AppBar Personalizado',
                style: TextStyle(
                  color: const Color(0xFF00FF41),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            'Navegación actual: ${_demoSections[_currentDemo]}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 15),
          Text(
            '✨ Funcionalidades Activas:',
            style: TextStyle(
              color: const Color(0xFF00FF41),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFeatureChip('🔔', 'Notificaciones'),
              _buildFeatureChip('📊', 'Estadísticas Tiempo Real'),
              _buildFeatureChip('🍞', 'Breadcrumbs Dinámicos'),
              _buildFeatureChip('⚡', 'Acciones Rápidas'),
              _buildFeatureChip('🎨', 'Animaciones Fluidas'),
              _buildFeatureChip('📱', 'Touch Feedback'),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _previousDemo,
                  icon: const Icon(Icons.skip_previous),
                  label: const Text('Anterior'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF41).withOpacity(0.2),
                    foregroundColor: const Color(0xFF00FF41),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _nextDemo,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Siguiente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF41),
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF00FF41).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            '🔥 AppBar Sin Dependencias del Sistema',
            'Este AppBar está completamente construido desde cero, sin usar ningún elemento del toolbar del sistema operativo. Todo es custom y controlado por la app.',
            Icons.no_sim,
            Colors.red,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            '🍞 Breadcrumbs Inteligentes',
            'Navegación visual con breadcrumbs que muestran la ruta actual, íconos personalizados, colores y subtítulos. Completamente interactivos con animaciones.',
            Icons.navigation,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            '📊 Estadísticas en Tiempo Real',
            'CPU, RAM, velocidad de red, tareas activas, herramientas instaladas. Todo actualizado cada segundo con animaciones suaves.',
            Icons.analytics,
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            '🔔 Sistema de Notificaciones',
            'Panel de notificaciones deslizable con acciones rápidas, timestamps, prioridades y feedback háptico. Completamente touchable.',
            Icons.notifications_active,
            Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            '⚡ Menú de Acciones Rápidas',
            'Acceso instantáneo a configuración, terminal, actualización, estadísticas detalladas y ayuda. Todo con animaciones fluidas.',
            Icons.flash_on,
            Colors.purple,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            '🎨 Animaciones Avanzadas',
            'Logo rotando, pulsos, rebotes, deslizamientos. Múltiples controladores de animación trabajando en conjunto para una experiencia fluida.',
            Icons.animation,
            Colors.pink,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _previousDemo() {
    setState(() {
      _currentDemo = (_currentDemo - 1) % _demoSections.length;
    });
  }

  void _nextDemo() {
    setState(() {
      _currentDemo = (_currentDemo + 1) % _demoSections.length;
    });
  }

  void _showMenuDemo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: const Color(0xFF00FF41).withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Icon(Icons.menu, color: const Color(0xFF00FF41)),
            const SizedBox(width: 10),
            const Text('Menú Principal', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          '🚀 Este es el menú personalizado del AppBar.\n\n'
          '✨ Completamente independiente del sistema operativo.\n\n'
          '⚡ Con acciones rápidas y navegación fluida.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cerrar',
              style: TextStyle(color: const Color(0xFF00FF41)),
            ),
          ),
        ],
      ),
    );
  }
}
