import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/tool_provider.dart';
import '../providers/script_provider.dart';

/// 🚀 SUPER APPBAR PERSONALIZADO MEJORADO
/// Sin dependencias del sistema operativo - 100% custom
class EnhancedHackomaticAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  final String currentSection;
  final List<EnhancedBreadcrumbItem> breadcrumbs;
  final VoidCallback? onMenuPressed;
  final bool showRealTimeStats;
  final bool showNotifications;
  final bool showQuickActions;

  const EnhancedHackomaticAppBar({
    super.key,
    required this.currentSection,
    this.breadcrumbs = const [],
    this.onMenuPressed,
    this.showRealTimeStats = true,
    this.showNotifications = true,
    this.showQuickActions = true,
  });

  @override
  State<EnhancedHackomaticAppBar> createState() =>
      _EnhancedHackomaticAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(150); // Más alto para más funciones
}

class EnhancedBreadcrumbItem {
  final String title;
  final String route;
  final IconData icon;
  final bool isActive;
  final VoidCallback? onTap;
  final Color? color;
  final String? subtitle;

  EnhancedBreadcrumbItem({
    required this.title,
    required this.route,
    required this.icon,
    this.isActive = false,
    this.onTap,
    this.color,
    this.subtitle,
  });
}

class NotificationItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final DateTime timestamp;
  final VoidCallback? onTap;
  final bool isUrgent;
  final String? actionLabel;

  NotificationItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.timestamp,
    this.onTap,
    this.isUrgent = false,
    this.actionLabel,
  });
}

class _EnhancedHackomaticAppBarState extends State<EnhancedHackomaticAppBar>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _rotateController;
  late AnimationController _bounceController;

  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _bounceAnimation;

  bool _showNotifications = false;
  bool _showQuickMenu = false;
  Timer? _statsTimer;

  // Estadísticas en tiempo real
  int _runningTasks = 0;
  int _totalTools = 0;
  int _totalScripts = 0;
  double _cpuUsage = 0.0;
  double _memoryUsage = 0.0;
  int _networkSpeed = 0;
  String _systemStatus = '🟢 Ready';

  List<NotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateNotifications();
    _startRealTimeUpdates();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _rotateController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(_rotateController);

    _bounceAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _slideController.forward();
    _bounceController.forward();
  }

  void _generateNotifications() {
    _notifications = [
      NotificationItem(
        title: '🔥 Sistema optimizado',
        subtitle: 'Rendimiento mejorado en un 43%',
        icon: Icons.speed,
        color: Colors.green,
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        actionLabel: 'Ver detalles',
        onTap: () => _showNotificationDetail('Sistema optimizado'),
      ),
      NotificationItem(
        title: '⚡ Nueva herramienta detectada',
        subtitle: 'Nmap 7.95 disponible',
        icon: Icons.new_releases,
        color: Colors.orange,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        isUrgent: true,
        actionLabel: 'Instalar',
        onTap: () => _showNotificationDetail('Nueva herramienta'),
      ),
      NotificationItem(
        title: '🛡️ Análisis completado',
        subtitle: '3 vulnerabilidades encontradas',
        icon: Icons.security,
        color: Colors.red,
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        isUrgent: true,
        actionLabel: 'Revisar',
        onTap: () => _showNotificationDetail('Análisis de seguridad'),
      ),
    ];
  }

  void _startRealTimeUpdates() {
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateRealTimeStats();
      }
    });
  }

  void _updateRealTimeStats() {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final toolProvider = Provider.of<ToolProvider>(context, listen: false);
    final scriptProvider = Provider.of<ScriptProvider>(context, listen: false);

    setState(() {
      _runningTasks = taskProvider.tasks
          .where((task) => task.status.toString().contains('running'))
          .length;
      _totalTools = toolProvider.tools.length;
      _totalScripts = scriptProvider.scripts.length;

      // Simular estadísticas realistas
      _cpuUsage = 20 + Random().nextDouble() * 30;
      _memoryUsage = 40 + Random().nextDouble() * 20;
      _networkSpeed = 50 + Random().nextInt(150);

      _systemStatus = _runningTasks > 0 ? '🟡 Activo' : '🟢 Listo';
    });
  }

  void _showNotificationDetail(String title) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.touch_app, color: Colors.white),
            const SizedBox(width: 10),
            Text('📱 Abriendo: $title'),
          ],
        ),
        backgroundColor: const Color(0xFF00FF41),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'VER',
          textColor: Colors.black,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _rotateController.dispose();
    _bounceController.dispose();
    _statsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: widget.preferredSize.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0A0A0A),
              const Color(0xFF1A1A1A),
              const Color(0xFF00FF41).withOpacity(0.1),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00FF41).withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildMainHeader(),
              _buildBreadcrumbsRow(),
              _buildStatsRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainHeader() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Logo animado
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: AnimatedBuilder(
                  animation: _rotateAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotateAnimation.value,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF00FF41),
                              const Color(0xFF00FF41).withOpacity(0.3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00FF41).withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.security,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          const SizedBox(width: 16),

          // Título principal con estado
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      'HACKOMATIC',
                      style: TextStyle(
                        color: const Color(0xFF00FF41),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: const Color(0xFF00FF41).withOpacity(0.5),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _systemStatus,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                Text(
                  widget.currentSection,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // Notificaciones con badge
          _buildNotificationButton(),

          const SizedBox(width: 10),

          // Menú rápido
          _buildQuickMenuButton(),
        ],
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Stack(
      children: [
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            setState(() {
              _showNotifications = !_showNotifications;
            });
            _showNotificationPanel();
          },
          icon: Icon(
            _showNotifications
                ? Icons.notifications_active
                : Icons.notifications,
            color: _showNotifications
                ? const Color(0xFF00FF41)
                : Colors.white70,
          ),
        ),
        if (_notifications.any((n) => n.isUrgent))
          Positioned(
            right: 8,
            top: 8,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.6),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildQuickMenuButton() {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: _showQuickMenu ? const Color(0xFF00FF41) : Colors.white70,
      ),
      onSelected: (value) {
        HapticFeedback.selectionClick();
        _handleQuickAction(value);
      },
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: const Color(0xFF00FF41).withOpacity(0.3)),
      ),
      itemBuilder: (context) => [
        _buildPopupMenuItem('refresh', '🔄 Actualizar', Icons.refresh),
        _buildPopupMenuItem('settings', '⚙️ Configuración', Icons.settings),
        _buildPopupMenuItem('terminal', '💻 Terminal', Icons.terminal),
        _buildPopupMenuItem('stats', '📊 Estadísticas', Icons.analytics),
        _buildPopupMenuItem('help', '❓ Ayuda', Icons.help),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    String value,
    String text,
    IconData icon,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00FF41), size: 20),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  void _handleQuickAction(String action) {
    switch (action) {
      case 'refresh':
        _bounceController.reset();
        _bounceController.forward();
        break;
      case 'settings':
        _showSettingsPanel();
        break;
      case 'terminal':
        _openTerminal();
        break;
      case 'stats':
        _showStatsDetail();
        break;
      case 'help':
        _showHelp();
        break;
    }
  }

  Widget _buildBreadcrumbsRow() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.home, color: const Color(0xFF00FF41), size: 16),
          const SizedBox(width: 8),

          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.breadcrumbs.length,
              separatorBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white30,
                  size: 12,
                ),
              ),
              itemBuilder: (context, index) {
                final breadcrumb = widget.breadcrumbs[index];
                return _buildBreadcrumbItem(breadcrumb);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbItem(EnhancedBreadcrumbItem breadcrumb) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        breadcrumb.onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: breadcrumb.isActive
              ? const Color(0xFF00FF41).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: breadcrumb.isActive
              ? Border.all(color: const Color(0xFF00FF41).withOpacity(0.5))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              breadcrumb.icon,
              color: breadcrumb.isActive
                  ? const Color(0xFF00FF41)
                  : Colors.white54,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              breadcrumb.title,
              style: TextStyle(
                color: breadcrumb.isActive
                    ? const Color(0xFF00FF41)
                    : Colors.white54,
                fontSize: 12,
                fontWeight: breadcrumb.isActive
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    if (!widget.showRealTimeStats) return const SizedBox.shrink();

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              '💻',
              'CPU',
              '${_cpuUsage.toInt()}%',
              Colors.blue,
            ),
          ),
          Expanded(
            child: _buildStatCard(
              '🧠',
              'RAM',
              '${_memoryUsage.toInt()}%',
              Colors.purple,
            ),
          ),
          Expanded(
            child: _buildStatCard(
              '🌐',
              'Red',
              '${_networkSpeed}MB/s',
              Colors.green,
            ),
          ),
          Expanded(
            child: _buildStatCard(
              '⚡',
              'Tareas',
              '$_runningTasks',
              Colors.orange,
            ),
          ),
          Expanded(
            child: _buildStatCard('🛠️', 'Tools', '$_totalTools', Colors.cyan),
          ),
          Expanded(
            child: _buildStatCard(
              '📜',
              'Scripts',
              '$_totalScripts',
              Colors.pink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String emoji, String label, String value, Color color) {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (_bounceAnimation.value * 0.2),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 10)),
                    const SizedBox(width: 2),
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNotificationPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF41),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '🔔 Notificaciones Activas',
                style: TextStyle(
                  color: const Color(0xFF00FF41),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...(_notifications.map(
              (notification) => _buildNotificationTile(notification),
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(NotificationItem notification) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: notification.color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(notification.icon, color: notification.color, size: 20),
      ),
      title: Text(
        notification.title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            notification.subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            _formatTimestamp(notification.timestamp),
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
      trailing: notification.actionLabel != null
          ? ElevatedButton(
              onPressed: notification.onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF41),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                notification.actionLabel!,
                style: const TextStyle(fontSize: 10),
              ),
            )
          : null,
      onTap: notification.onTap,
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else {
      return 'Hace ${difference.inDays}d';
    }
  }

  void _showSettingsPanel() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚙️ Abriendo configuración avanzada...'),
        backgroundColor: Color(0xFF00FF41),
      ),
    );
  }

  void _openTerminal() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('💻 Iniciando terminal integrada...'),
        backgroundColor: Color(0xFF00FF41),
      ),
    );
  }

  void _showStatsDetail() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📊 Mostrando estadísticas detalladas...'),
        backgroundColor: Color(0xFF00FF41),
      ),
    );
  }

  void _showHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('❓ Abriendo centro de ayuda...'),
        backgroundColor: Color(0xFF00FF41),
      ),
    );
  }
}
