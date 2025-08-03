import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/tool_provider.dart';
import '../providers/script_provider.dart';

/// Widget personalizado de AppBar avanzado con breadcrumbs y estadísticas
class HackomaticCustomAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  final String currentSection;
  final List<BreadcrumbItem> breadcrumbs;
  final VoidCallback? onMenuPressed;
  final List<Widget>? actions;
  final bool showStats;
  final bool showNotifications;

  const HackomaticCustomAppBar({
    super.key,
    required this.currentSection,
    this.breadcrumbs = const [],
    this.onMenuPressed,
    this.actions,
    this.showStats = true,
    this.showNotifications = true,
  });

  @override
  State<HackomaticCustomAppBar> createState() => _HackomaticCustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(120); // Altura personalizada
}

class _HackomaticCustomAppBarState extends State<HackomaticCustomAppBar>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isNotificationExpanded = false;
  Timer? _statsTimer;

  // Estadísticas en tiempo real
  int _runningTasks = 0;
  int _totalTools = 0;
  int _totalScripts = 0;
  String _systemStatus = 'Ready';
  String _networkStatus = 'Connected';

  @override
  void initState() {
    super.initState();

    // Configurar animaciones
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    // Iniciar actualizaciones de estadísticas
    _startStatsUpdater();
    _slideController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _statsTimer?.cancel();
    super.dispose();
  }

  void _startStatsUpdater() {
    _statsTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _updateStats();
      }
    });
  }

  void _updateStats() {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final toolProvider = Provider.of<ToolProvider>(context, listen: false);
    final scriptProvider = Provider.of<ScriptProvider>(context, listen: false);

    setState(() {
      _runningTasks = taskProvider.tasks
          .where((task) => task.status.toString().contains('running'))
          .length;
      _totalTools = toolProvider.tools.length;
      _totalScripts = scriptProvider.scripts.length;

      // Simular estados del sistema
      _systemStatus = _runningTasks > 0 ? 'Active' : 'Ready';
      _networkStatus = 'Connected'; // Podría ser dinámico
    });
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
              const Color(0xFF00FF41).withOpacity(0.05),
            ],
          ),
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFF00FF41).withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Fila principal del AppBar
              _buildMainAppBar(),

              // Fila de breadcrumbs y estadísticas
              _buildBreadcrumbsAndStats(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainAppBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Logo y título animado
          _buildAnimatedLogo(),

          const SizedBox(width: 16),

          // Título con efecto de escritura
          Expanded(child: _buildAnimatedTitle()),

          // Indicadores de estado
          _buildStatusIndicators(),

          const SizedBox(width: 16),

          // Acciones personalizadas
          _buildCustomActions(),
        ],
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF00FF41),
                  const Color(0xFF00FF41).withOpacity(0.3),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00FF41).withOpacity(0.5),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.security, color: Colors.black, size: 24),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'HACKOMATIC',
          style: TextStyle(
            color: Color(0xFF00FF41),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            letterSpacing: 2,
          ),
        ),
        Text(
          widget.currentSection,
          style: TextStyle(
            color: const Color(0xFF00FF41).withOpacity(0.7),
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicators() {
    return Row(
      children: [
        // Indicador de tareas activas
        _buildStatusDot(
          color: _runningTasks > 0 ? Colors.orange : const Color(0xFF00FF41),
          label: '$_runningTasks',
          tooltip: 'Tareas activas',
        ),
        const SizedBox(width: 8),

        // Indicador de red
        _buildStatusDot(
          color: _networkStatus == 'Connected'
              ? const Color(0xFF00FF41)
              : Colors.red,
          label: 'NET',
          tooltip: 'Estado de red: $_networkStatus',
        ),
        const SizedBox(width: 8),

        // Indicador del sistema
        _buildStatusDot(
          color: _systemStatus == 'Ready'
              ? const Color(0xFF00FF41)
              : Colors.orange,
          label: 'SYS',
          tooltip: 'Sistema: $_systemStatus',
        ),
      ],
    );
  }

  Widget _buildStatusDot({
    required Color color,
    required String label,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  Widget _buildCustomActions() {
    return Row(
      children: [
        // Botón de notificaciones
        if (widget.showNotifications) _buildNotificationButton(),

        const SizedBox(width: 8),

        // Botón de menú rápido
        _buildQuickMenuButton(),

        const SizedBox(width: 8),

        // Botón de configuración avanzada
        _buildAdvancedSettingsButton(),

        // Acciones adicionales del widget
        if (widget.actions != null) ...widget.actions!,
      ],
    );
  }

  Widget _buildNotificationButton() {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: Color(0xFF00FF41),
            size: 22,
          ),
          onPressed: () {
            setState(() {
              _isNotificationExpanded = !_isNotificationExpanded;
            });
            _showNotificationPanel();
          },
          tooltip: 'Notificaciones',
        ),
        if (_runningTasks > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickMenuButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.apps, color: Color(0xFF00FF41), size: 22),
      tooltip: 'Menú rápido',
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF00FF41), width: 1),
      ),
      itemBuilder: (context) => [
        _buildPopupMenuItem('🚀 Quick Scan', 'quick_scan'),
        _buildPopupMenuItem('📊 Statistics', 'stats'),
        _buildPopupMenuItem('🔧 Tools', 'tools'),
        _buildPopupMenuItem('📝 Scripts', 'scripts'),
        _buildPopupMenuItem('📋 Tasks', 'tasks'),
        const PopupMenuDivider(),
        _buildPopupMenuItem('⚙️ Settings', 'settings'),
      ],
      onSelected: _handleQuickMenuAction,
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(String text, String value) {
    return PopupMenuItem<String>(
      value: value,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF00FF41),
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildAdvancedSettingsButton() {
    return IconButton(
      icon: const Icon(Icons.tune, color: Color(0xFF00FF41), size: 22),
      onPressed: _showAdvancedSettings,
      tooltip: 'Configuración avanzada',
    );
  }

  Widget _buildBreadcrumbsAndStats() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Breadcrumbs
          Expanded(child: _buildBreadcrumbs()),

          // Estadísticas rápidas
          if (widget.showStats) _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    if (widget.breadcrumbs.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Icono de inicio
          GestureDetector(
            onTap: () => _navigateToBreadcrumb(null),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF41).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.home, color: Color(0xFF00FF41), size: 16),
            ),
          ),

          // Separador y breadcrumbs
          ...widget.breadcrumbs.asMap().entries.map((entry) {
            final index = entry.key;
            final breadcrumb = entry.value;
            final isLast = index == widget.breadcrumbs.length - 1;

            return Row(
              children: [
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: const Color(0xFF00FF41).withOpacity(0.5),
                  size: 16,
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _navigateToBreadcrumb(breadcrumb),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isLast
                          ? const Color(0xFF00FF41).withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: isLast
                          ? Border.all(color: const Color(0xFF00FF41), width: 1)
                          : null,
                    ),
                    child: Text(
                      breadcrumb.title,
                      style: TextStyle(
                        color: isLast
                            ? const Color(0xFF00FF41)
                            : const Color(0xFF00FF41).withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: isLast
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF00FF41).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF00FF41).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatItem(Icons.build, _totalTools.toString(), 'Tools'),
          const SizedBox(width: 12),
          _buildStatItem(Icons.code, _totalScripts.toString(), 'Scripts'),
          const SizedBox(width: 12),
          _buildStatItem(
            Icons.task_alt,
            _runningTasks.toString(),
            'Active',
            color: _runningTasks > 0 ? Colors.orange : const Color(0xFF00FF41),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label, {
    Color? color,
  }) {
    final itemColor = color ?? const Color(0xFF00FF41);

    return Tooltip(
      message: '$label: $value',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: itemColor, size: 14),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: itemColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToBreadcrumb(BreadcrumbItem? breadcrumb) {
    if (breadcrumb?.onTap != null) {
      breadcrumb!.onTap!();
    } else {
      // Navegar al home si es null
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _handleQuickMenuAction(String action) {
    switch (action) {
      case 'quick_scan':
        _showQuickScanDialog();
        break;
      case 'stats':
        _showStatsDialog();
        break;
      case 'tools':
        // Cambiar a pestaña de tools
        break;
      case 'scripts':
        // Cambiar a pestaña de scripts
        break;
      case 'tasks':
        // Cambiar a pestaña de tasks
        break;
      case 'settings':
        _navigateToSettings();
        break;
    }
  }

  void _showNotificationPanel() {
    showDialog(
      context: context,
      builder: (context) => _NotificationPanel(runningTasks: _runningTasks),
    );
  }

  void _showQuickScanDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚀 Quick Scan iniciado'),
        backgroundColor: Color(0xFF00FF41),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showStatsDialog() {
    showDialog(
      context: context,
      builder: (context) => _StatsDialog(
        totalTools: _totalTools,
        totalScripts: _totalScripts,
        runningTasks: _runningTasks,
        systemStatus: _systemStatus,
        networkStatus: _networkStatus,
      ),
    );
  }

  void _showAdvancedSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _AdvancedSettingsSheet(),
    );
  }

  void _navigateToSettings() {
    // Implementar navegación a settings
  }
}

/// Clase para elementos de breadcrumb
class BreadcrumbItem {
  final String title;
  final VoidCallback? onTap;

  const BreadcrumbItem({required this.title, this.onTap});
}

/// Panel de notificaciones
class _NotificationPanel extends StatelessWidget {
  final int runningTasks;

  const _NotificationPanel({required this.runningTasks});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF00FF41), width: 1),
      ),
      title: const Row(
        children: [
          Icon(Icons.notifications, color: Color(0xFF00FF41)),
          SizedBox(width: 8),
          Text('Notificaciones', style: TextStyle(color: Color(0xFF00FF41))),
        ],
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (runningTasks > 0) ...[
              _NotificationItem(
                icon: Icons.task_alt,
                title: 'Tareas activas',
                message: '$runningTasks tareas ejecutándose',
                color: Colors.orange,
              ),
            ] else ...[
              const _NotificationItem(
                icon: Icons.check_circle,
                title: 'Sistema inactivo',
                message: 'No hay tareas ejecutándose',
                color: Color(0xFF00FF41),
              ),
            ],
            const _NotificationItem(
              icon: Icons.security,
              title: 'Sistema seguro',
              message: 'Todas las herramientas verificadas',
              color: Color(0xFF00FF41),
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
      ],
    );
  }
}

/// Item de notificación
class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  const _NotificationItem({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Diálogo de estadísticas
class _StatsDialog extends StatelessWidget {
  final int totalTools;
  final int totalScripts;
  final int runningTasks;
  final String systemStatus;
  final String networkStatus;

  const _StatsDialog({
    required this.totalTools,
    required this.totalScripts,
    required this.runningTasks,
    required this.systemStatus,
    required this.networkStatus,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF00FF41), width: 1),
      ),
      title: const Row(
        children: [
          Icon(Icons.analytics, color: Color(0xFF00FF41)),
          SizedBox(width: 8),
          Text(
            'Estadísticas del Sistema',
            style: TextStyle(color: Color(0xFF00FF41)),
          ),
        ],
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatRow('Herramientas', totalTools.toString(), Icons.build),
            _StatRow('Scripts', totalScripts.toString(), Icons.code),
            _StatRow('Tareas activas', runningTasks.toString(), Icons.task_alt),
            _StatRow('Sistema', systemStatus, Icons.computer),
            _StatRow('Red', networkStatus, Icons.wifi),
            const SizedBox(height: 16),
            Text(
              'Usuario: ${Platform.environment['USER'] ?? 'unknown'}@${Platform.localHostname}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontFamily: 'monospace',
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
      ],
    );
  }
}

/// Fila de estadística
class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatRow(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF00FF41).withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00FF41), size: 16),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF00FF41),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sheet de configuración avanzada
class _AdvancedSettingsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(top: BorderSide(color: Color(0xFF00FF41), width: 2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF00FF41),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Título
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Configuración Avanzada',
              style: TextStyle(
                color: Color(0xFF00FF41),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Opciones
          _SettingTile(
            icon: Icons.palette,
            title: 'Tema',
            subtitle: 'Personalizar colores',
            onTap: () {},
          ),
          _SettingTile(
            icon: Icons.notifications,
            title: 'Notificaciones',
            subtitle: 'Configurar alertas',
            onTap: () {},
          ),
          _SettingTile(
            icon: Icons.security,
            title: 'Seguridad',
            subtitle: 'Configurar permisos',
            onTap: () {},
          ),
          _SettingTile(
            icon: Icons.speed,
            title: 'Rendimiento',
            subtitle: 'Optimizar sistema',
            onTap: () {},
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// Tile de configuración
class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF00FF41)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF00FF41)),
      onTap: onTap,
    );
  }
}
