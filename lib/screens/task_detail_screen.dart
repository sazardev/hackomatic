import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/hacking_task.dart';
import '../providers/task_provider.dart';
import '../utils/theme.dart';

class TaskDetailScreen extends StatefulWidget {
  final HackingTask task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Auto-scroll to bottom when new output arrives
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task.name),
        actions: [
          if (widget.task.status == TaskStatus.running)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _stopTask,
              tooltip: 'Stop Task',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          final currentTask =
              taskProvider.getTaskById(widget.task.id) ?? widget.task;

          return Column(
            children: [
              _buildTaskHeader(currentTask),
              Expanded(child: _buildTaskOutput(currentTask, taskProvider)),
              if (currentTask.status == TaskStatus.running)
                _buildTaskActions(currentTask, taskProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTaskHeader(HackingTask task) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusIcon(task.status),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getStatusText(task.status),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _getStatusColor(task.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              task.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: HackomaticTheme.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildTaskInfo(task),
            if (task.status == TaskStatus.running && task.progress > 0)
              _buildProgressBar(task),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(TaskStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case TaskStatus.pending:
        icon = Icons.schedule;
        color = HackomaticTheme.warningColor;
        break;
      case TaskStatus.running:
        icon = Icons.play_circle;
        color = HackomaticTheme.primaryGreen;
        break;
      case TaskStatus.completed:
        icon = Icons.check_circle;
        color = HackomaticTheme.successColor;
        break;
      case TaskStatus.failed:
        icon = Icons.error;
        color = HackomaticTheme.errorColor;
        break;
    }

    return Icon(icon, color: color, size: 32);
  }

  Widget _buildTaskInfo(HackingTask task) {
    return Column(
      children: [
        _buildInfoRow('Created', _formatDateTime(task.createdAt)),
        if (task.startedAt != null)
          _buildInfoRow('Started', _formatDateTime(task.startedAt!)),
        if (task.completedAt != null)
          _buildInfoRow('Completed', _formatDateTime(task.completedAt!)),
        if (task.toolId != null) _buildInfoRow('Tool', task.toolId!),
        if (task.scriptId != null) _buildInfoRow('Script', task.scriptId!),
        if (task.parameters.isNotEmpty)
          _buildInfoRow('Parameters', task.parameters.length.toString()),
      ],
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

  Widget _buildProgressBar(HackingTask task) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              'Progress: ${task.progress}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: task.progress / 100,
          backgroundColor: HackomaticTheme.surfaceColor,
          valueColor: AlwaysStoppedAnimation<Color>(
            _getStatusColor(task.status),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskOutput(HackingTask task, TaskProvider taskProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Output',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (task.status == TaskStatus.running)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HackomaticTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: HackomaticTheme.primaryGreen.withOpacity(0.3),
                ),
              ),
              child: task.status == TaskStatus.running
                  ? _buildLiveOutput(task, taskProvider)
                  : _buildStaticOutput(task),
            ),
          ),
          if (task.errorMessage != null) _buildErrorSection(task),
        ],
      ),
    );
  }

  Widget _buildLiveOutput(HackingTask task, TaskProvider taskProvider) {
    return StreamBuilder<String>(
      stream: taskProvider.getTaskOutputStream(task.id),
      builder: (context, snapshot) {
        String output = task.output ?? '';

        if (snapshot.hasData) {
          // This would accumulate in real implementation
          output += snapshot.data!;
        }

        return SingleChildScrollView(
          controller: _scrollController,
          child: Text(
            output.isEmpty ? 'Waiting for output...' : output,
            style: const TextStyle(
              fontFamily: 'Courier',
              color: HackomaticTheme.primaryGreen,
              fontSize: 12,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStaticOutput(HackingTask task) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Text(
        task.output ?? 'No output available',
        style: const TextStyle(
          fontFamily: 'Courier',
          color: HackomaticTheme.primaryGreen,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildErrorSection(HackingTask task) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HackomaticTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HackomaticTheme.errorColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Error',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: HackomaticTheme.errorColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            task.errorMessage!,
            style: TextStyle(
              fontFamily: 'Courier',
              color: HackomaticTheme.errorColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskActions(HackingTask task, TaskProvider taskProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HackomaticTheme.surfaceColor,
        border: Border(
          top: BorderSide(color: HackomaticTheme.primaryGreen.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _stopTask,
              icon: const Icon(Icons.stop),
              label: const Text('Stop Task'),
              style: OutlinedButton.styleFrom(
                foregroundColor: HackomaticTheme.errorColor,
                side: BorderSide(color: HackomaticTheme.errorColor),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ),
        ],
      ),
    );
  }

  void _stopTask() {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    taskProvider.stopTask(widget.task.id);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task stopped'),
        backgroundColor: HackomaticTheme.warningColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
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

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return HackomaticTheme.warningColor;
      case TaskStatus.running:
        return HackomaticTheme.primaryGreen;
      case TaskStatus.completed:
        return HackomaticTheme.successColor;
      case TaskStatus.failed:
        return HackomaticTheme.errorColor;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
