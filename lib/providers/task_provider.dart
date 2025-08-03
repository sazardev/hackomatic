import 'package:flutter/foundation.dart';
import '../models/hacking_task.dart';
import '../models/hacking_tool.dart';
import '../models/hacking_script.dart';
import '../services/storage_service.dart';
import '../services/command_execution_service.dart';

class TaskProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  final CommandExecutionService _commandService = CommandExecutionService();
  List<HackingTask> _tasks = [];
  String _searchQuery = '';
  TaskStatus? _statusFilter;

  List<HackingTask> get tasks => _getFilteredTasks();
  String get searchQuery => _searchQuery;
  TaskStatus? get statusFilter => _statusFilter;

  List<HackingTask> get runningTasks {
    return _tasks.where((task) => task.status == TaskStatus.running).toList();
  }

  List<HackingTask> get completedTasks {
    return _tasks.where((task) => task.status == TaskStatus.completed).toList();
  }

  List<HackingTask> get failedTasks {
    return _tasks.where((task) => task.status == TaskStatus.failed).toList();
  }

  TaskProvider() {
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    _tasks = await _storageService.loadTasks();
    notifyListeners();
  }

  List<HackingTask> _getFilteredTasks() {
    return _tasks.where((task) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          task.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          task.description.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus =
          _statusFilter == null || task.status == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void searchTasks(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void filterByStatus(TaskStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  Future<void> addTask(HackingTask task) async {
    _tasks.add(task);
    await _storageService.saveTasks(_tasks);
    notifyListeners();
  }

  Future<void> removeTask(String taskId) async {
    _tasks.removeWhere((task) => task.id == taskId);
    await _storageService.saveTasks(_tasks);
    notifyListeners();
  }

  Future<void> updateTask(HackingTask updatedTask) async {
    final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      await _storageService.saveTasks(_tasks);
      notifyListeners();
    }
  }

  Future<void> startTask(String taskId) async {
    final task = getTaskById(taskId);
    if (task != null && task.status == TaskStatus.pending) {
      final updatedTask = task.copyWith(
        status: TaskStatus.running,
        startedAt: DateTime.now(),
      );
      await updateTask(updatedTask);
    }
  }

  Future<void> completeTask(String taskId, {String? output}) async {
    final task = getTaskById(taskId);
    if (task != null && task.status == TaskStatus.running) {
      final updatedTask = task.copyWith(
        status: TaskStatus.completed,
        completedAt: DateTime.now(),
        progress: 100,
        output: output,
      );
      await updateTask(updatedTask);
    }
  }

  Future<void> failTask(String taskId, String errorMessage) async {
    final task = getTaskById(taskId);
    if (task != null && task.status == TaskStatus.running) {
      final updatedTask = task.copyWith(
        status: TaskStatus.failed,
        completedAt: DateTime.now(),
        errorMessage: errorMessage,
      );
      await updateTask(updatedTask);
    }
  }

  Future<void> updateTaskProgress(String taskId, int progress) async {
    final task = getTaskById(taskId);
    if (task != null && task.status == TaskStatus.running) {
      final updatedTask = task.copyWith(progress: progress);
      await updateTask(updatedTask);
    }
  }

  HackingTask? getTaskById(String id) {
    try {
      return _tasks.firstWhere((task) => task.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearCompletedTasks() async {
    _tasks.removeWhere(
      (task) =>
          task.status == TaskStatus.completed ||
          task.status == TaskStatus.failed,
    );
    await _storageService.saveTasks(_tasks);
    notifyListeners();
  }

  // Tool execution
  Future<HackingTask> executeToolCommand(
    HackingTool tool,
    Map<String, dynamic> parameters,
  ) async {
    final task = await _commandService.executeToolCommand(tool, parameters);
    await addTask(task);

    // Monitor the task output
    _monitorTaskExecution(task.id);

    return task;
  }

  // Script execution
  Future<HackingTask> executeScript(
    HackingScript script,
    Map<String, dynamic> parameters,
  ) async {
    final task = await _commandService.executeScript(script, parameters);
    await addTask(task);

    // Monitor the task output
    _monitorTaskExecution(task.id);

    return task;
  }

  void _monitorTaskExecution(String taskId) {
    final outputStream = _commandService.getTaskOutput(taskId);
    if (outputStream != null) {
      String accumulatedOutput = '';

      outputStream.listen(
        (output) {
          accumulatedOutput += output;

          // Update task with partial output
          final task = getTaskById(taskId);
          if (task != null) {
            final updatedTask = task.copyWith(output: accumulatedOutput);
            updateTask(updatedTask);
          }
        },
        onDone: () {
          // Task completed successfully
          completeTask(taskId, output: accumulatedOutput);
        },
        onError: (error) {
          // Task failed
          failTask(taskId, error.toString());
        },
      );
    }
  }

  void stopTask(String taskId) {
    _commandService.stopTask(taskId);

    // Update task status
    final task = getTaskById(taskId);
    if (task != null && task.status == TaskStatus.running) {
      final updatedTask = task.copyWith(
        status: TaskStatus.failed,
        completedAt: DateTime.now(),
        errorMessage: 'Task stopped by user',
      );
      updateTask(updatedTask);
    }
  }

  Stream<String>? getTaskOutputStream(String taskId) {
    return _commandService.getTaskOutput(taskId);
  }

  // Método público para refrescar tareas
  Future<void> refreshTasks() async {
    await _loadTasks();
  }
}
