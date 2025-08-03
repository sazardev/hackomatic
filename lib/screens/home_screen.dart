import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tool_provider.dart';
import '../providers/script_provider.dart';
import '../providers/task_provider.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/platform_provider.dart';
import '../utils/theme.dart';
import 'tools_screen.dart';
import 'scripts_screen.dart';
import 'tasks_screen.dart';
import 'bluetooth_screen.dart';
import 'settings_screen.dart';
import 'advanced_initializer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardTab(),
    const ToolsScreen(),
    const ScriptsScreen(),
    const TasksScreen(),
    const BluetoothScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HACKOMATIC'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: HackomaticTheme.surfaceColor,
        selectedItemColor: HackomaticTheme.primaryGreen,
        unselectedItemColor: HackomaticTheme.secondaryTextColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Tools'),
          BottomNavigationBarItem(icon: Icon(Icons.code), label: 'Scripts'),
          BottomNavigationBarItem(icon: Icon(Icons.task_alt), label: 'Tasks'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bluetooth),
            label: 'Bluetooth',
          ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(context),
          const SizedBox(height: 16),
          if (Platform.isLinux) ...[
            _buildLinuxPlatformCard(context),
            const SizedBox(height: 16),
          ],
          _buildStatsRow(context),
          const SizedBox(height: 16),
          _buildQuickActions(context),
          const SizedBox(height: 16),
          _buildRecentTasks(context),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  size: 32,
                  color: HackomaticTheme.primaryGreen,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to Hackomatic',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your mobile hacking tools controller',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: HackomaticTheme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HackomaticTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: HackomaticTheme.primaryGreen.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: HackomaticTheme.warningColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Remember: Only use for authorized testing',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: HackomaticTheme.warningColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinuxPlatformCard(BuildContext context) {
    return Consumer<PlatformProvider>(
      builder: (context, platformProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.computer,
                      size: 28,
                      color: Color(0xFF00FF41),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Linux Pentesting Environment 🐧',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF00FF41),
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Optimized for penetration testing',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AdvancedInitializerScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF41),
                          foregroundColor: Colors.black,
                        ),
                        icon: const Icon(Icons.build),
                        label: const Text('Auto Setup'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => platformProvider.refresh(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF00FF41)),
                          foregroundColor: const Color(0xFF00FF41),
                        ),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                    ),
                  ],
                ),
                if (platformProvider.isReady) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF41).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF00FF41).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF00FF41),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Platform ready for pentesting',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: const Color(0xFF00FF41)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Consumer3<ToolProvider, ScriptProvider, TaskProvider>(
      builder: (context, toolProvider, scriptProvider, taskProvider, child) {
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Tools',
                toolProvider.tools.length.toString(),
                Icons.build,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                'Scripts',
                scriptProvider.scripts.length.toString(),
                Icons.code,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                'Active Tasks',
                taskProvider.runningTasks.length.toString(),
                Icons.play_arrow,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 24, color: HackomaticTheme.primaryGreen),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: HackomaticTheme.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.5,
          children: [
            _buildQuickActionButton(
              context,
              'Network Scan',
              Icons.network_check,
              () => _startNetworkScan(context),
            ),
            _buildQuickActionButton(
              context,
              'WiFi Monitor',
              Icons.wifi,
              () => _startWiFiMonitor(context),
            ),
            _buildQuickActionButton(
              context,
              'Port Scan',
              Icons.router,
              () => _startPortScan(context),
            ),
            _buildQuickActionButton(
              context,
              'Bluetooth Scan',
              Icons.bluetooth_searching,
              () => _startBluetoothScan(context),
            ),
            if (Platform.isLinux) ...[
              _buildQuickActionButton(
                context,
                'System Info',
                Icons.info,
                () => _showLinuxSystemInfo(context),
              ),
              _buildQuickActionButton(
                context,
                'Auto Setup',
                Icons.build,
                () => _openLinuxAutoSetup(context),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: HackomaticTheme.cardColor,
        foregroundColor: HackomaticTheme.primaryGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: HackomaticTheme.primaryGreen),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTasks(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final recentTasks = taskProvider.tasks.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Tasks',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (recentTasks.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No tasks yet. Start using tools to see activity here.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: HackomaticTheme.secondaryTextColor,
                      ),
                    ),
                  ),
                ),
              )
            else
              ...recentTasks.map(
                (task) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      _getTaskStatusIcon(task.status),
                      color: _getTaskStatusColor(task.status),
                    ),
                    title: Text(task.name),
                    subtitle: Text(task.description),
                    trailing: Text(
                      _formatTime(task.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: HackomaticTheme.secondaryTextColor,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  IconData _getTaskStatusIcon(status) {
    switch (status.toString()) {
      case 'TaskStatus.running':
        return Icons.play_arrow;
      case 'TaskStatus.completed':
        return Icons.check_circle;
      case 'TaskStatus.failed':
        return Icons.error;
      default:
        return Icons.pending;
    }
  }

  Color _getTaskStatusColor(status) {
    switch (status.toString()) {
      case 'TaskStatus.running':
        return HackomaticTheme.warningColor;
      case 'TaskStatus.completed':
        return HackomaticTheme.successColor;
      case 'TaskStatus.failed':
        return HackomaticTheme.errorColor;
      default:
        return HackomaticTheme.secondaryTextColor;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _startNetworkScan(BuildContext context) {
    // Navigate to tools screen with network scan tool selected
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Network scan feature coming soon!')),
    );
  }

  void _startWiFiMonitor(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('WiFi monitor feature coming soon!')),
    );
  }

  void _startPortScan(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Port scan feature coming soon!')),
    );
  }

  void _startBluetoothScan(BuildContext context) {
    final bluetoothProvider = Provider.of<BluetoothProvider>(
      context,
      listen: false,
    );
    bluetoothProvider.startScan();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Bluetooth scan started!')));
  }

  void _showLinuxSystemInfo(BuildContext context) {
    final platformProvider = Provider.of<PlatformProvider>(
      context,
      listen: false,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Row(
          children: [
            const Icon(Icons.computer, color: Color(0xFF00FF41)),
            const SizedBox(width: 8),
            const Text(
              'Linux System Info 🐧',
              style: TextStyle(color: Color(0xFF00FF41)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Platform', platformProvider.platformName),
              _buildInfoRow(
                'Status',
                platformProvider.isReady ? 'Ready ✅' : 'Not Ready ❌',
              ),
              _buildInfoRow(
                'Initialized',
                platformProvider.isInitialized ? 'Yes' : 'No',
              ),
              if (platformProvider.systemInfo.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'System Information:',
                  style: TextStyle(
                    color: Color(0xFF00FF41),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: platformProvider.systemInfo.entries
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              '${entry.key}: ${entry.value}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ],
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
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openLinuxAutoSetup(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdvancedInitializerScreen(),
      ),
    );
  }
}
