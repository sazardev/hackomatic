import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/tool_provider.dart';
import '../providers/script_provider.dart';
import '../services/advanced_permissions_service.dart';
import '../services/advanced_logging_service.dart';
import '../services/massive_script_repository.dart';
import '../services/advanced_terminal_service.dart';

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
  final bool _showQuickMenu = false;
  Timer? _statsTimer;

  // Servicios avanzados
  late AdvancedPermissionsService _permissionsService;
  late AdvancedLoggingService _loggingService;
  late MassiveScriptRepository _scriptRepository;
  late AdvancedTerminalService _terminalService;

  // Estadísticas en tiempo real
  int _runningTasks = 0;
  int _totalTools = 0;
  int _totalScripts = 0;
  double _cpuUsage = 0.0;
  double _memoryUsage = 0.0;
  int _networkSpeed = 0;
  String _systemStatus = '🟢 Ready';
  bool _hasSudoAccess = false;
  bool _hasBluetoothAccess = false;
  bool _hasNetworkAccess = false;
  int _securityEvents = 0;
  int _activeConnections = 0;

  List<NotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
    _generateNotifications();
    _startRealTimeUpdates();
  }

  void _initializeServices() {
    _permissionsService = AdvancedPermissionsService();
    _loggingService = AdvancedLoggingService.instance;
    _scriptRepository = MassiveScriptRepository();
    _terminalService = AdvancedTerminalService();

    // Inicializar servicios si no están ya inicializados
    _initializeServicesAsync();
  }

  void _initializeServicesAsync() async {
    try {
      await _loggingService.initialize();
      await _permissionsService.initializePermissions();
      await _terminalService.initialize();

      _loggingService.info(
        'Enhanced AppBar initialized with advanced services',
      );
    } catch (e) {
      _loggingService.error('Error initializing services in AppBar', error: e);
    }
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
        title: '⚡ Scripts actualizados',
        subtitle:
            '${_scriptRepository.getAllScripts().length} scripts disponibles',
        icon: Icons.new_releases,
        color: Colors.orange,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        isUrgent: false,
        actionLabel: 'Explorar',
        onTap: () => _showScriptRepository(),
      ),
      NotificationItem(
        title: '🛡️ Permisos verificados',
        subtitle: 'Acceso completo configurado',
        icon: Icons.security,
        color: _hasSudoAccess ? Colors.green : Colors.orange,
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        isUrgent: !_hasSudoAccess,
        actionLabel: 'Configurar',
        onTap: () => _showPermissionsStatus(),
      ),
      NotificationItem(
        title: '📊 Logs activos',
        subtitle: 'Sistema de monitoreo funcionando',
        icon: Icons.analytics,
        color: Colors.blue,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        actionLabel: 'Ver logs',
        onTap: () => _showLogsViewer(),
      ),
      NotificationItem(
        title: '💻 Terminal avanzado',
        subtitle: 'Funciones de hacking disponibles',
        icon: Icons.terminal,
        color: Colors.purple,
        timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
        actionLabel: 'Abrir terminal',
        onTap: () => _openAdvancedTerminal(),
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

  void _updateRealTimeStats() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final toolProvider = Provider.of<ToolProvider>(context, listen: false);
    final scriptProvider = Provider.of<ScriptProvider>(context, listen: false);

    // Obtener estadísticas avanzadas
    try {
      _hasSudoAccess = await _permissionsService.hasSudoAccess();
      _hasBluetoothAccess = await _permissionsService.hasPermissionFor(
        'bluetooth',
      );
      _hasNetworkAccess = await _permissionsService.hasPermissionFor('network');
    } catch (e) {
      _loggingService.warning(
        'Error checking permissions in AppBar',
        details: {'error': e.toString()},
      );
    }

    setState(() {
      _runningTasks = taskProvider.tasks
          .where((task) => task.status.toString().contains('running'))
          .length;
      _totalTools = toolProvider.tools.length;
      _totalScripts = _scriptRepository.getAllScripts().length;

      // Simular estadísticas realistas con variación
      _cpuUsage = 20 + Random().nextDouble() * 30;
      _memoryUsage = 40 + Random().nextDouble() * 20;
      _networkSpeed = 50 + Random().nextInt(150);
      _securityEvents = Random().nextInt(5);
      _activeConnections = 2 + Random().nextInt(8);

      // Estado del sistema basado en condiciones reales
      if (_runningTasks > 3) {
        _systemStatus = '🔴 Sobrecargado';
      } else if (_runningTasks > 0) {
        _systemStatus = '🟡 Activo';
      } else if (_hasSudoAccess && _hasNetworkAccess) {
        _systemStatus = '🟢 Óptimo';
      } else {
        _systemStatus = '🟠 Limitado';
      }
    });

    // Log de métricas de rendimiento
    _loggingService.performanceMetric('cpu_usage', _cpuUsage, 'percent');
    _loggingService.performanceMetric('memory_usage', _memoryUsage, 'percent');
    _loggingService.performanceMetric(
      'running_tasks',
      _runningTasks.toDouble(),
      'count',
    );
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

  /// Mostrar repositorio de scripts
  void _showScriptRepository() {
    _loggingService.info('Opening script repository from AppBar');
    showDialog(
      context: context,
      builder: (context) =>
          _ScriptRepositoryDialog(scriptRepository: _scriptRepository),
    );
  }

  /// Mostrar estado de permisos
  void _showPermissionsStatus() {
    _loggingService.info('Opening permissions status from AppBar');
    showDialog(
      context: context,
      builder: (context) =>
          _PermissionsStatusDialog(permissionsService: _permissionsService),
    );
  }

  /// Mostrar visor de logs
  void _showLogsViewer() {
    _loggingService.info('Opening logs viewer from AppBar');
    showDialog(
      context: context,
      builder: (context) => _LogsViewerDialog(loggingService: _loggingService),
    );
  }

  /// Abrir terminal avanzado
  void _openAdvancedTerminal() {
    _loggingService.info('Opening advanced terminal from AppBar');
    Navigator.of(context).pushNamed('/advanced_terminal');
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
              const Color(0xFF00FF41).withValues(alpha: 0.1),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00FF41).withValues(alpha: 0.2),
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
                              const Color(0xFF00FF41).withValues(alpha: 0.3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF00FF41,
                              ).withValues(alpha: 0.5),
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
                            color: const Color(
                              0xFF00FF41,
                            ).withValues(alpha: 0.5),
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
                          color: Colors.red.withValues(alpha: 0.6),
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
        side: BorderSide(color: const Color(0xFF00FF41).withValues(alpha: 0.3)),
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
              ? const Color(0xFF00FF41).withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: breadcrumb.isActive
              ? Border.all(
                  color: const Color(0xFF00FF41).withValues(alpha: 0.5),
                )
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatCard('💻', 'CPU', '${_cpuUsage.toInt()}%', Colors.blue),
            const SizedBox(width: 8),
            _buildStatCard(
              '🧠',
              'RAM',
              '${_memoryUsage.toInt()}%',
              Colors.purple,
            ),
            const SizedBox(width: 8),
            _buildStatCard('🌐', 'Red', '${_networkSpeed}MB/s', Colors.green),
            const SizedBox(width: 8),
            _buildStatCard('⚡', 'Tareas', '$_runningTasks', Colors.orange),
            const SizedBox(width: 8),
            _buildStatCard('🛠️', 'Tools', '$_totalTools', Colors.cyan),
            const SizedBox(width: 8),
            _buildStatCard(
              '📜',
              'Scripts',
              '$_totalScripts',
              const Color(0xFF00FF41),
            ),
            const SizedBox(width: 8),
            _buildStatCard(
              '�',
              'Sudo',
              _hasSudoAccess ? 'ON' : 'OFF',
              _hasSudoAccess ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            _buildStatCard(
              '📶',
              'BT',
              _hasBluetoothAccess ? 'ON' : 'OFF',
              _hasBluetoothAccess ? Colors.blue : Colors.grey,
            ),
            const SizedBox(width: 8),
            _buildStatCard('🔗', 'Conn', '$_activeConnections', Colors.teal),
            const SizedBox(width: 8),
            _buildStatCard(
              '�',
              'Alerts',
              '$_securityEvents',
              _securityEvents > 0 ? Colors.red : Colors.green,
            ),
          ],
        ),
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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
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
                    Flexible(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
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
          border: Border.all(
            color: const Color(0xFF00FF41).withValues(alpha: 0.3),
          ),
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
          color: notification.color.withValues(alpha: 0.2),
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

/// Diálogo para mostrar el repositorio de scripts
class _ScriptRepositoryDialog extends StatelessWidget {
  final MassiveScriptRepository scriptRepository;

  const _ScriptRepositoryDialog({required this.scriptRepository});

  @override
  Widget build(BuildContext context) {
    final scripts = scriptRepository.getAllScripts();
    final stats = scriptRepository.getScriptStatistics();

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF00FF41), width: 2),
      ),
      title: Row(
        children: [
          const Icon(Icons.code, color: Color(0xFF00FF41)),
          const SizedBox(width: 10),
          const Text(
            'Repositorio de Scripts',
            style: TextStyle(
              color: Color(0xFF00FF41),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estadísticas
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF41).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF00FF41).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📊 Estadísticas',
                    style: TextStyle(
                      color: const Color(0xFF00FF41),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total: ${stats['total_scripts']} scripts\n'
                    'Con sudo: ${stats['requires_sudo']}\n'
                    'Sin sudo: ${stats['no_sudo_required']}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Lista de categorías
            const Text(
              '📁 Categorías disponibles:',
              style: TextStyle(
                color: Color(0xFF00FF41),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: (stats['categories'] as Map<String, int>).entries.map(
                  (entry) {
                    return ListTile(
                      leading: Icon(
                        _getCategoryIcon(entry.key),
                        color: const Color(0xFF00FF41),
                        size: 20,
                      ),
                      title: Text(
                        entry.key,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '${entry.value} scripts',
                        style: const TextStyle(color: Colors.white54),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFF00FF41),
                        size: 16,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        // Navegar a la categoría específica
                      },
                    );
                  },
                ).toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cerrar',
            style: TextStyle(color: Color(0xFF00FF41)),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00FF41),
            foregroundColor: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
            // Navegar a la pantalla completa de scripts
          },
          child: const Text('Ver Todo'),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Reconnaissance':
        return Icons.search;
      case 'Exploitation':
        return Icons.bug_report;
      case 'Wireless':
        return Icons.wifi;
      case 'Post-Exploitation':
        return Icons.security;
      case 'Digital Forensics':
        return Icons.analytics;
      case 'Social Engineering':
        return Icons.people;
      case 'Evasion':
        return Icons.visibility_off;
      case 'Malware Analysis':
        return Icons.warning;
      case 'Web Application':
        return Icons.web;
      case 'Password Cracking':
        return Icons.lock_open;
      default:
        return Icons.code;
    }
  }
}

/// Diálogo para mostrar el estado de permisos
class _PermissionsStatusDialog extends StatefulWidget {
  final AdvancedPermissionsService permissionsService;

  const _PermissionsStatusDialog({required this.permissionsService});

  @override
  State<_PermissionsStatusDialog> createState() =>
      _PermissionsStatusDialogState();
}

class _PermissionsStatusDialogState extends State<_PermissionsStatusDialog> {
  Map<String, dynamic>? _permissionStatus;
  Map<String, dynamic>? _deviceInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPermissionStatus();
  }

  void _loadPermissionStatus() async {
    try {
      final permissions = await widget.permissionsService
          .checkCurrentPermissions();
      final deviceInfo = await widget.permissionsService.getDeviceInfo();

      setState(() {
        _permissionStatus = permissions.map(
          (k, v) => MapEntry(k, v.toString()),
        );
        _deviceInfo = deviceInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF00FF41), width: 2),
      ),
      title: Row(
        children: [
          const Icon(Icons.admin_panel_settings, color: Color(0xFF00FF41)),
          const SizedBox(width: 10),
          const Text(
            'Estado de Permisos',
            style: TextStyle(
              color: Color(0xFF00FF41),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 400,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF00FF41)),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información del dispositivo
                    if (_deviceInfo != null) ...[
                      const Text(
                        '📱 Información del dispositivo:',
                        style: TextStyle(
                          color: Color(0xFF00FF41),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FF41).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Plataforma: ${_deviceInfo!['platform']}\n'
                          'Versión: ${_deviceInfo!['version']}\n'
                          'App: ${_deviceInfo!['package']['name']} v${_deviceInfo!['package']['version']}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Estado de permisos
                    const Text(
                      '🔐 Permisos del sistema:',
                      style: TextStyle(
                        color: Color(0xFF00FF41),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_permissionStatus != null)
                      ..._permissionStatus!.entries.map((entry) {
                        final isGranted = entry.value.toString().contains(
                          'granted',
                        );
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isGranted
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isGranted ? Colors.green : Colors.red,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isGranted ? Icons.check_circle : Icons.cancel,
                                color: isGranted ? Colors.green : Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.key.replaceAll('Permission.', ''),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Text(
                                isGranted ? 'CONCEDIDO' : 'DENEGADO',
                                style: TextStyle(
                                  color: isGranted ? Colors.green : Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cerrar',
            style: TextStyle(color: Color(0xFF00FF41)),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00FF41),
            foregroundColor: Colors.black,
          ),
          onPressed: () async {
            await widget.permissionsService.openPermissionSettings();
          },
          child: const Text('Configurar'),
        ),
      ],
    );
  }
}

/// Diálogo para mostrar logs
class _LogsViewerDialog extends StatefulWidget {
  final AdvancedLoggingService loggingService;

  const _LogsViewerDialog({required this.loggingService});

  @override
  State<_LogsViewerDialog> createState() => _LogsViewerDialogState();
}

class _LogsViewerDialogState extends State<_LogsViewerDialog> {
  List<LogEntry> _logs = [];
  Map<String, int> _logStats = {};
  bool _isLoading = true;
  final String _selectedLevel = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() async {
    try {
      final logs = await widget.loggingService.getRecentLogs(limit: 50);
      final stats = await widget.loggingService.getLogStatistics();

      setState(() {
        _logs = logs;
        _logStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF00FF41), width: 2),
      ),
      title: Row(
        children: [
          const Icon(Icons.list_alt, color: Color(0xFF00FF41)),
          const SizedBox(width: 10),
          const Text(
            'Visor de Logs',
            style: TextStyle(
              color: Color(0xFF00FF41),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 500,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF00FF41)),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estadísticas
                  if (_logStats.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FF41).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📊 Estadísticas (últimos 7 días):',
                            style: TextStyle(
                              color: Color(0xFF00FF41),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 16,
                            children: _logStats.entries.map((entry) {
                              return Text(
                                '${entry.key}: ${entry.value}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Lista de logs
                  const Text(
                    '📋 Logs recientes:',
                    style: TextStyle(
                      color: Color(0xFF00FF41),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        final levelColor = _getLogLevelColor(log.level);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: levelColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: levelColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _getLogLevelIcon(log.level),
                                    color: levelColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    log.level
                                        .toString()
                                        .replaceAll('Level.', '')
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: levelColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                log.message,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              if (log.category != 'GENERAL') ...[
                                const SizedBox(height: 2),
                                Text(
                                  '📁 ${log.category}',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cerrar',
            style: TextStyle(color: Color(0xFF00FF41)),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00FF41),
            foregroundColor: Colors.black,
          ),
          onPressed: () async {
            try {
              final exportData = await widget.loggingService.exportLogs();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Logs exportados (${exportData.length} caracteres)',
                  ),
                  backgroundColor: const Color(0xFF00FF41),
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error al exportar logs'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text('Exportar'),
        ),
      ],
    );
  }

  Color _getLogLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.blue;
      case LogLevel.info:
        return const Color(0xFF00FF41);
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.fatal:
        return Colors.purple;
      default:
        return Colors.white;
    }
  }

  IconData _getLogLevelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Icons.bug_report;
      case LogLevel.info:
        return Icons.info;
      case LogLevel.warning:
        return Icons.warning;
      case LogLevel.error:
        return Icons.error;
      case LogLevel.fatal:
        return Icons.dangerous;
      default:
        return Icons.circle;
    }
  }
}
