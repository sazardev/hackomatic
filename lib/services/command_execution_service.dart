import 'dart:io';
import 'dart:async';
import '../models/hacking_task.dart';
import '../models/hacking_tool.dart';
import '../models/hacking_script.dart';

class CommandExecutionService {
  static final CommandExecutionService _instance =
      CommandExecutionService._internal();
  factory CommandExecutionService() => _instance;
  CommandExecutionService._internal();

  final Map<String, Process> _runningProcesses = {};
  final Map<String, StreamController<String>> _outputControllers = {};

  Future<HackingTask> executeToolCommand(
    HackingTool tool,
    Map<String, dynamic> parameters,
  ) async {
    final taskId = DateTime.now().millisecondsSinceEpoch.toString();

    // Create task
    final task = HackingTask(
      id: taskId,
      name: 'Running ${tool.name}',
      description: 'Executing ${tool.name} with provided parameters',
      status: TaskStatus.pending,
      createdAt: DateTime.now(),
      toolId: tool.id,
      parameters: parameters,
    );

    // Build command
    final command = _buildToolCommand(tool, parameters);

    // Execute command asynchronously
    _executeCommandAsync(taskId, command, tool.requiresRoot);

    return task.copyWith(status: TaskStatus.running, startedAt: DateTime.now());
  }

  Future<HackingTask> executeScript(
    HackingScript script,
    Map<String, dynamic> parameters,
  ) async {
    final taskId = DateTime.now().millisecondsSinceEpoch.toString();

    // Create task
    final task = HackingTask(
      id: taskId,
      name: 'Running ${script.name}',
      description: 'Executing script: ${script.name}',
      status: TaskStatus.pending,
      createdAt: DateTime.now(),
      scriptId: script.id,
      parameters: parameters,
    );

    // Build script command
    final command = _buildScriptCommand(script, parameters);

    // Execute script asynchronously
    _executeCommandAsync(taskId, command, false);

    return task.copyWith(status: TaskStatus.running, startedAt: DateTime.now());
  }

  Future<void> _executeCommandAsync(
    String taskId,
    String command,
    bool requiresRoot,
  ) async {
    try {
      // Create output stream controller
      _outputControllers[taskId] = StreamController<String>.broadcast();

      // Add sudo if root required
      final finalCommand = requiresRoot ? 'sudo $command' : command;

      // Split command for Process.start
      final parts = finalCommand.split(' ');
      final executable = parts.first;
      final arguments = parts.skip(1).toList();

      // Start process
      final process = await Process.start(
        executable,
        arguments,
        runInShell: true,
      );

      _runningProcesses[taskId] = process;

      // Listen to stdout
      process.stdout
          .transform(const SystemEncoding().decoder)
          .listen(
            (data) {
              _outputControllers[taskId]?.add(data);
            },
            onError: (error) {
              _outputControllers[taskId]?.addError(error);
            },
          );

      // Listen to stderr
      process.stderr
          .transform(const SystemEncoding().decoder)
          .listen(
            (data) {
              _outputControllers[taskId]?.add('ERROR: $data');
            },
            onError: (error) {
              _outputControllers[taskId]?.addError(error);
            },
          );

      // Wait for process to complete
      final exitCode = await process.exitCode;

      // Clean up
      _runningProcesses.remove(taskId);

      if (exitCode == 0) {
        _outputControllers[taskId]?.add('\n\nCommand completed successfully!');
      } else {
        _outputControllers[taskId]?.add(
          '\n\nCommand failed with exit code: $exitCode',
        );
      }

      _outputControllers[taskId]?.close();
    } catch (e) {
      _outputControllers[taskId]?.addError('Failed to execute command: $e');
      _outputControllers[taskId]?.close();
      _runningProcesses.remove(taskId);
    }
  }

  Stream<String>? getTaskOutput(String taskId) {
    return _outputControllers[taskId]?.stream;
  }

  void stopTask(String taskId) {
    final process = _runningProcesses[taskId];
    if (process != null) {
      process.kill();
      _runningProcesses.remove(taskId);
      _outputControllers[taskId]?.add('\n\nTask stopped by user');
      _outputControllers[taskId]?.close();
    }
  }

  bool isTaskRunning(String taskId) {
    return _runningProcesses.containsKey(taskId);
  }

  String _buildToolCommand(HackingTool tool, Map<String, dynamic> parameters) {
    String command = tool.command;

    for (final param in tool.parameters) {
      final value = parameters[param.name];
      if (value != null && value.toString().isNotEmpty) {
        if (param.type == 'boolean' && value == true) {
          command += ' --${param.name}';
        } else if (param.type != 'boolean') {
          // Handle different parameter formats
          if (param.name == 'target' && tool.id == 'nmap') {
            command += ' $value';
          } else if (param.name == 'ports' && value.toString().isNotEmpty) {
            command += ' -p $value';
          } else if (param.name == 'scan_type') {
            command += ' $value';
          } else {
            command += ' --${param.name} $value';
          }
        }
      }
    }

    return command;
  }

  String _buildScriptCommand(
    HackingScript script,
    Map<String, dynamic> parameters,
  ) {
    String command = 'bash ${script.scriptPath}';

    // Add parameters as positional arguments
    for (final param in script.parameters) {
      final value = parameters[param.name];
      if (value != null && value.toString().isNotEmpty) {
        command += ' "$value"';
      } else {
        command += ' ""';
      }
    }

    return command;
  }

  void dispose() {
    // Kill all running processes
    for (final process in _runningProcesses.values) {
      process.kill();
    }
    _runningProcesses.clear();

    // Close all stream controllers
    for (final controller in _outputControllers.values) {
      controller.close();
    }
    _outputControllers.clear();
  }
}
