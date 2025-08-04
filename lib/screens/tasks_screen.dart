import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/hacking_task.dart';
import '../utils/theme.dart';
import 'task_detail_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        return Column(
          children: [
            _buildSearchBar(taskProvider),
            _buildTabBar(),
            Expanded(child: _buildTabBarView(taskProvider)),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar(TaskProvider taskProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                taskProvider.searchTasks(value);
              },
            ),
          ),
          const SizedBox(width: 12),
          PopupMenuButton<TaskStatus?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (status) {
              taskProvider.filterByStatus(status);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('All Tasks')),
              const PopupMenuItem(
                value: TaskStatus.pending,
                child: Text('Pending'),
              ),
              const PopupMenuItem(
                value: TaskStatus.running,
                child: Text('Running'),
              ),
              const PopupMenuItem(
                value: TaskStatus.completed,
                child: Text('Completed'),
              ),
              const PopupMenuItem(
                value: TaskStatus.failed,
                child: Text('Failed'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () => _showClearDialog(taskProvider),
            tooltip: 'Clear completed tasks',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: HackomaticTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: HackomaticTheme.primaryGreen.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Running'),
          Tab(text: 'Completed'),
          Tab(text: 'Failed'),
        ],
        indicatorColor: HackomaticTheme.primaryGreen,
        labelColor: HackomaticTheme.primaryGreen,
        unselectedLabelColor: HackomaticTheme.secondaryTextColor,
      ),
    );
  }

  Widget _buildTabBarView(TaskProvider taskProvider) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildTasksList(taskProvider.tasks),
        _buildTasksList(taskProvider.runningTasks),
        _buildTasksList(taskProvider.completedTasks),
        _buildTasksList(taskProvider.failedTasks),
      ],
    );
  }

  Widget _buildTasksList(List<HackingTask> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt,
              size: 64,
              color: HackomaticTheme.secondaryTextColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: HackomaticTheme.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Run some tools or scripts to see tasks here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: HackomaticTheme.secondaryTextColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildTaskCard(task);
      },
    );
  }

  Widget _buildTaskCard(HackingTask task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewTaskDetails(task),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getTaskStatusColor(
                        task.status,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getTaskStatusColor(
                          task.status,
                        ).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      _getTaskStatusIcon(task.status),
                      color: _getTaskStatusColor(task.status),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getStatusText(task.status),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: _getTaskStatusColor(task.status),
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(task.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: HackomaticTheme.secondaryTextColor,
                        ),
                      ),
                      if (task.status == TaskStatus.running) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${task.progress}%',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: HackomaticTheme.warningColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                task.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: HackomaticTheme.secondaryTextColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (task.status == TaskStatus.running && task.progress > 0) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: task.progress / 100,
                  backgroundColor: HackomaticTheme.surfaceColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getTaskStatusColor(task.status),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (task.toolId != null) ...[
                    Icon(
                      Icons.build,
                      size: 16,
                      color: HackomaticTheme.secondaryTextColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tool',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: HackomaticTheme.secondaryTextColor,
                      ),
                    ),
                  ] else if (task.scriptId != null) ...[
                    Icon(
                      Icons.code,
                      size: 16,
                      color: HackomaticTheme.secondaryTextColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Script',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: HackomaticTheme.secondaryTextColor,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (task.status == TaskStatus.running) ...[
                    TextButton.icon(
                      onPressed: () => _stopTask(task),
                      icon: const Icon(Icons.stop, size: 16),
                      label: const Text('Stop'),
                      style: TextButton.styleFrom(
                        foregroundColor: HackomaticTheme.errorColor,
                      ),
                    ),
                  ] else if (task.status == TaskStatus.failed ||
                      task.status == TaskStatus.completed) ...[
                    TextButton.icon(
                      onPressed: () => _viewTaskDetails(task),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View'),
                      style: TextButton.styleFrom(
                        foregroundColor: HackomaticTheme.primaryGreen,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTaskStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Icons.pending;
      case TaskStatus.running:
        return Icons.play_arrow;
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.failed:
        return Icons.error;
    }
  }

  Color _getTaskStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return HackomaticTheme.secondaryTextColor;
      case TaskStatus.running:
        return HackomaticTheme.warningColor;
      case TaskStatus.completed:
        return HackomaticTheme.successColor;
      case TaskStatus.failed:
        return HackomaticTheme.errorColor;
    }
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.running:
        return 'Running';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.failed:
        return 'Failed';
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

  void _showTaskDetails(HackingTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: HackomaticTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: HackomaticTheme.secondaryTextColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _getTaskStatusIcon(task.status),
                          color: _getTaskStatusColor(task.status),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getStatusText(task.status),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: _getTaskStatusColor(task.status),
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      task.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: HackomaticTheme.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Task Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Created', _formatFullDate(task.createdAt)),
                    if (task.startedAt != null)
                      _buildInfoRow(
                        'Started',
                        _formatFullDate(task.startedAt!),
                      ),
                    if (task.completedAt != null)
                      _buildInfoRow(
                        'Completed',
                        _formatFullDate(task.completedAt!),
                      ),
                    if (task.status == TaskStatus.running)
                      _buildInfoRow('Progress', '${task.progress}%'),
                    if (task.output != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Output',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: HackomaticTheme.backgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: HackomaticTheme.primaryGreen.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              task.output!,
                              style: const TextStyle(
                                fontFamily: 'Courier',
                                color: HackomaticTheme.primaryGreen,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (task.errorMessage != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Error',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: HackomaticTheme.errorColor,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: HackomaticTheme.errorColor.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: HackomaticTheme.errorColor.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Text(
                          task.errorMessage!,
                          style: TextStyle(color: HackomaticTheme.errorColor),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: HackomaticTheme.secondaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _viewTaskDetails(HackingTask task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)),
    );
  }

  void _stopTask(HackingTask task) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    taskProvider.stopTask(task.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Stopping task: ${task.name}'),
        backgroundColor: HackomaticTheme.warningColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showClearDialog(TaskProvider taskProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Completed Tasks'),
        content: const Text(
          'This will remove all completed and failed tasks. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              taskProvider.clearCompletedTasks();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Completed tasks cleared'),
                  backgroundColor: HackomaticTheme.successColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: HackomaticTheme.errorColor,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
