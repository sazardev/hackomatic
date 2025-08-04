import 'dart:io';
import 'dart:async';
import '../models/hacking_task.dart';
import '../models/hacking_tool.dart';
import '../models/hacking_script.dart';
import 'network_detection_service.dart';
import 'dart:developer' as dev;

class CommandExecutionService {
  static final CommandExecutionService _instance =
      CommandExecutionService._internal();
  factory CommandExecutionService() => _instance;
  CommandExecutionService._internal();

  final Map<String, Process> _runningProcesses = {};
  final Map<String, StreamController<String>> _outputControllers = {};
  final NetworkDetectionService _networkService = NetworkDetectionService();

  // Platform detection
  bool get isAndroid => Platform.isAndroid;
  bool get isLinux => Platform.isLinux;

  /// Ejecuta un comando simple y devuelve el resultado
  Future<CommandResult> executeCommand(String command) async {
    try {
      final List<String> commandParts = command.split(' ');
      final String executable = commandParts.first;
      final List<String> arguments = commandParts.skip(1).toList();

      final ProcessResult result = await Process.run(
        executable,
        arguments,
        runInShell: true,
      );

      return CommandResult(
        success: result.exitCode == 0,
        exitCode: result.exitCode,
        stdout: result.stdout.toString(),
        stderr: result.stderr.toString(),
      );
    } catch (e) {
      return CommandResult(
        success: false,
        exitCode: -1,
        stdout: '',
        stderr: e.toString(),
      );
    }
  }

  Future<HackingTask> executeToolCommand(
    HackingTool tool,
    Map<String, dynamic> parameters,
  ) async {
    final taskId = DateTime.now().millisecondsSinceEpoch.toString();

    // Auto-populate parameters with network detection
    final autoParameters = await _getAutoPopulatedParameters(
      tool.parameters,
      parameters,
    );

    // Create task
    final task = HackingTask(
      id: taskId,
      name: 'Execute ${tool.name}',
      description: tool.description,
      status: TaskStatus.pending,
      createdAt: DateTime.now(),
      toolId: tool.id,
      parameters: autoParameters,
    );

    // Build command with auto-populated parameters and platform handling
    final command = await _buildToolCommand(tool, autoParameters);

    // Execute command asynchronously
    _executeCommandAsync(taskId, command, tool.requiresRoot);

    return task.copyWith(status: TaskStatus.running, startedAt: DateTime.now());
  }

  Future<HackingTask> executeScript(
    HackingScript script,
    Map<String, dynamic> parameters,
  ) async {
    final taskId = DateTime.now().millisecondsSinceEpoch.toString();

    // Auto-populate script parameters with intelligent detection
    final autoParameters = await _getAutoPopulatedScriptParameters(
      script.parameters,
      parameters,
    );

    // Create task
    final task = HackingTask(
      id: taskId,
      name: 'Running ${script.name}',
      description: 'Executing script: ${script.name}',
      status: TaskStatus.pending,
      createdAt: DateTime.now(),
      scriptId: script.id,
      parameters: autoParameters,
    );

    // Build script command with platform-specific handling
    final command = await _buildScriptCommand(script, autoParameters);

    // Execute script asynchronously
    _executeCommandAsync(taskId, command, false);

    return task.copyWith(status: TaskStatus.running, startedAt: DateTime.now());
  }

  // Auto-populate parameters for tools
  Future<Map<String, dynamic>> _getAutoPopulatedParameters(
    List<dynamic> parameterDefinitions,
    Map<String, dynamic> userParameters,
  ) async {
    final autoConfig = await _networkService.getAutoScanConfig();
    final finalParameters = Map<String, dynamic>.from(userParameters);

    for (final param in parameterDefinitions) {
      final paramName = param.name ?? '';

      // Skip if user already provided value
      if (finalParameters.containsKey(paramName) &&
          finalParameters[paramName] != null &&
          finalParameters[paramName].toString().isNotEmpty) {
        continue;
      }

      // Auto-populate based on parameter name and type
      switch (paramName.toLowerCase()) {
        case 'target':
        case 'ip':
        case 'host':
          finalParameters[paramName] = autoConfig['gateway'];
          break;
        case 'network':
        case 'range':
        case 'subnet':
          finalParameters[paramName] = autoConfig['network_range'];
          break;
        case 'interface':
        case 'iface':
          finalParameters[paramName] = autoConfig['active_interface'];
          break;
        case 'ports':
        case 'port':
          finalParameters[paramName] = autoConfig['port_range'];
          break;
        case 'url':
        case 'website':
          finalParameters[paramName] = autoConfig['target_url'];
          break;
        case 'wordlist':
        case 'dictionary':
          finalParameters[paramName] = autoConfig['wordlist_path'];
          break;
        case 'output':
        case 'file':
          finalParameters[paramName] =
              '/tmp/hackomatic_${DateTime.now().millisecondsSinceEpoch}.txt';
          break;
        default:
          // Set reasonable defaults based on type
          if (param.defaultValue != null) {
            finalParameters[paramName] = param.defaultValue;
          }
      }
    }

    return finalParameters;
  }

  // Auto-populate parameters for scripts (which may have zero parameters)
  Future<Map<String, dynamic>> _getAutoPopulatedScriptParameters(
    List<dynamic> parameterDefinitions,
    Map<String, dynamic> userParameters,
  ) async {
    // For scripts with no parameters, return empty map
    if (parameterDefinitions.isEmpty) {
      return {};
    }

    // Use same logic as tools for scripts that do have parameters
    return await _getAutoPopulatedParameters(
      parameterDefinitions,
      userParameters,
    );
  }

  Future<void> _executeCommandAsync(
    String taskId,
    String command,
    bool requiresRoot,
  ) async {
    try {
      // Create output stream controller
      _outputControllers[taskId] = StreamController<String>.broadcast();

      // Platform-specific command execution
      final platformCommand = await _getPlatformSpecificCommand(
        command,
        requiresRoot,
      );

      // Add initial status
      _outputControllers[taskId]?.add('🚀 Starting command execution...\n');
      _outputControllers[taskId]?.add(
        '📱 Platform: ${isAndroid ? 'Android' : 'Linux'}\n',
      );
      _outputControllers[taskId]?.add('💻 Command: $platformCommand\n');
      _outputControllers[taskId]?.add('⚡ Executing...\n\n');

      Process process;

      if (isAndroid) {
        // Android-specific execution
        process = await _executeOnAndroid(platformCommand);
      } else {
        // Linux/Desktop execution
        process = await _executeOnLinux(platformCommand);
      }

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
              _outputControllers[taskId]?.add('⚠️ ERROR: $data');
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
        _outputControllers[taskId]?.add(
          '\n\n✅ Command completed successfully!',
        );
      } else {
        _outputControllers[taskId]?.add(
          '\n\n❌ Command failed with exit code: $exitCode',
        );
      }

      _outputControllers[taskId]?.close();
    } catch (e) {
      _outputControllers[taskId]?.addError('💥 Failed to execute command: $e');
      _outputControllers[taskId]?.close();
      _runningProcesses.remove(taskId);
    }
  }

  // Platform-specific command preparation with enhanced Android/Linux support
  Future<String> _getPlatformSpecificCommand(
    String command,
    bool requiresRoot,
  ) async {
    if (isAndroid) {
      // Android handling with better root detection and busybox support
      if (requiresRoot) {
        // Try different methods for root access
        final rootMethods = ['su -c', 'sudo', 'doas'];
        for (final method in rootMethods) {
          try {
            final testResult = await Process.run('which', [
              method.split(' ')[0],
            ]);
            if (testResult.exitCode == 0) {
              return '$method "$command"';
            }
          } catch (e) {
            continue;
          }
        }
        // Fallback to su -c
        return 'su -c "$command"';
      }

      // For Android, ensure we're using available tools
      return await _adaptCommandForAndroid(command);
    } else {
      // Linux handling with better privilege escalation
      if (requiresRoot) {
        // Check available privilege escalation methods
        final rootMethods = ['sudo', 'doas', 'su -c'];
        for (final method in rootMethods) {
          try {
            final testResult = await Process.run('which', [
              method.split(' ')[0],
            ]);
            if (testResult.exitCode == 0) {
              if (method == 'su -c') {
                return 'su -c "$command"';
              } else {
                return '$method $command';
              }
            }
          } catch (e) {
            continue;
          }
        }
        // Fallback to sudo
        return 'sudo $command';
      }
      return command;
    }
  }

  // Adapt commands for Android environment
  Future<String> _adaptCommandForAndroid(String command) async {
    // Replace Linux-specific commands with Android alternatives
    var adaptedCommand = command;

    // Common substitutions for Android
    final substitutions = {
      'arp-scan': 'ip neigh show', // arp-scan may not be available
      'iwconfig': 'iw dev', // iwconfig may not be available
      'netstat': 'ss', // netstat may not be available
      'dig': 'nslookup', // dig may not be available
    };

    for (final entry in substitutions.entries) {
      if (adaptedCommand.contains(entry.key)) {
        // Check if the original command is available
        try {
          final whichResult = await Process.run('which', [entry.key]);
          if (whichResult.exitCode != 0) {
            // Replace with alternative
            adaptedCommand = adaptedCommand.replaceAll(entry.key, entry.value);
          }
        } catch (e) {
          // If we can't check, use the alternative
          adaptedCommand = adaptedCommand.replaceAll(entry.key, entry.value);
        }
      }
    }

    return adaptedCommand;
  }

  // Enhanced Android-specific process execution
  Future<Process> _executeOnAndroid(String command) async {
    try {
      // For Android, use shell with better environment setup
      final androidCommand = await _setupAndroidEnvironment(command);
      return await Process.start(
        'sh',
        ['-c', androidCommand],
        runInShell: false,
        environment: await _getAndroidEnvironment(),
      );
    } catch (e) {
      // Fallback to basic shell execution
      return await Process.start('sh', ['-c', command], runInShell: false);
    }
  }

  // Enhanced Linux-specific process execution
  Future<Process> _executeOnLinux(String command) async {
    try {
      // For better command parsing and execution
      if (command.contains('|') ||
          command.contains('&&') ||
          command.contains(';')) {
        // Complex command with pipes or operators - use shell
        return await Process.start('bash', ['-c', command], runInShell: true);
      } else {
        // Simple command - parse and execute directly for better control
        final parts = _parseCommand(command);
        final executable = parts.first;
        final arguments = parts.skip(1).toList();

        return await Process.start(executable, arguments, runInShell: false);
      }
    } catch (e) {
      // Fallback to shell execution
      return await Process.start('bash', ['-c', command], runInShell: true);
    }
  }

  // Setup Android environment for better tool execution
  Future<String> _setupAndroidEnvironment(String command) async {
    // Add common Android paths to ensure tools are found
    final pathAdditions = [
      '/system/bin',
      '/system/xbin',
      '/data/local/bin',
      '/sbin',
    ];

    final currentPath = Platform.environment['PATH'] ?? '';
    final newPath = '$currentPath:${pathAdditions.join(':')}';

    // Return command with PATH setup
    return 'export PATH="$newPath"; $command';
  }

  // Get Android-specific environment variables
  Future<Map<String, String>> _getAndroidEnvironment() async {
    final env = Map<String, String>.from(Platform.environment);

    // Add Android-specific paths
    final currentPath = env['PATH'] ?? '';
    env['PATH'] = '$currentPath:/system/bin:/system/xbin:/data/local/bin:/sbin';

    // Set other useful variables
    env['ANDROID_ROOT'] = '/system';
    env['ANDROID_DATA'] = '/data';

    return env;
  }

  // Parse command into executable and arguments
  List<String> _parseCommand(String command) {
    final parts = <String>[];
    var current = '';
    var inQuotes = false;
    var quoteChar = '';

    for (var i = 0; i < command.length; i++) {
      final char = command[i];

      if ((char == '"' || char == "'") && !inQuotes) {
        inQuotes = true;
        quoteChar = char;
      } else if (char == quoteChar && inQuotes) {
        inQuotes = false;
        quoteChar = '';
      } else if (char == ' ' && !inQuotes) {
        if (current.isNotEmpty) {
          parts.add(current);
          current = '';
        }
      } else {
        current += char;
      }
    }

    if (current.isNotEmpty) {
      parts.add(current);
    }

    return parts.isEmpty ? ['echo', 'No command'] : parts;
  }

  Stream<String>? getTaskOutput(String taskId) {
    return _outputControllers[taskId]?.stream;
  }

  void stopTask(String taskId) {
    final process = _runningProcesses[taskId];
    if (process != null) {
      process.kill();
      _runningProcesses.remove(taskId);
      _outputControllers[taskId]?.add('\n\n🛑 Task stopped by user');
      _outputControllers[taskId]?.close();
    }
  }

  bool isTaskRunning(String taskId) {
    return _runningProcesses.containsKey(taskId);
  }

  Future<String> _buildToolCommand(
    HackingTool tool,
    Map<String, dynamic> parameters,
  ) async {
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

  Future<String> _buildScriptCommand(
    HackingScript script,
    Map<String, dynamic> parameters,
  ) async {
    // Platform-specific script execution with better path handling
    final scriptPath = await _resolveScriptPath(script.scriptPath);

    // For our auto-intelligent scripts, most have zero parameters
    if (script.parameters.isEmpty) {
      // Execute script with platform-appropriate shell
      if (isAndroid) {
        return 'sh "$scriptPath"';
      } else {
        return 'bash "$scriptPath"';
      }
    }

    // For scripts with parameters, build command with them
    String command = isAndroid ? 'sh "$scriptPath"' : 'bash "$scriptPath"';

    // Add parameters as positional arguments
    for (final param in script.parameters) {
      final value = parameters[param.name];
      if (value != null && value.toString().isNotEmpty) {
        command += ' "${value.toString()}"';
      } else {
        command += ' ""';
      }
    }

    return command;
  }

  // Resolve script path for different platforms
  Future<String> _resolveScriptPath(String scriptPath) async {
    // If it's already an absolute path, use it
    if (scriptPath.startsWith('/')) {
      return scriptPath;
    }

    // For Android, we might need to copy scripts to accessible location
    if (isAndroid) {
      return await _prepareScriptForAndroid(scriptPath);
    }

    // For Linux, resolve relative to assets
    if (scriptPath.startsWith('assets/')) {
      // In production, assets might be in different location
      final currentDir = Directory.current.path;
      return '$currentDir/$scriptPath';
    }

    return scriptPath;
  }

  // Prepare script for Android execution
  Future<String> _prepareScriptForAndroid(String scriptPath) async {
    try {
      // Android might need scripts in app's data directory
      final appDir = Directory(
        '/data/data/com.example.hackomatic/files/scripts',
      );
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }

      final scriptName = scriptPath.split('/').last;
      final targetPath = '${appDir.path}/$scriptName';

      // If script already exists in target location, use it
      final targetFile = File(targetPath);
      if (await targetFile.exists()) {
        return targetPath;
      }

      // Otherwise, return original path and hope it's accessible
      return scriptPath;
    } catch (e) {
      dev.log('Error preparing script for Android: $e');
      return scriptPath;
    }
  }

  // Get system information for debugging
  Future<Map<String, dynamic>> getSystemInfo() async {
    final info = <String, dynamic>{};

    info['platform'] = Platform.operatingSystem;
    info['version'] = Platform.operatingSystemVersion;
    info['is_android'] = isAndroid;
    info['is_linux'] = isLinux;

    // Network information
    info['network'] = await _networkService.getAutoScanConfig();

    // Available tools
    info['available_tools'] = await _networkService.getAvailableTools();

    return info;
  }

  // Test command execution capability
  Future<bool> testCommandExecution() async {
    try {
      final testCommand = isAndroid ? 'echo "test"' : 'echo "test"';
      final result = await Process.run('sh', ['-c', testCommand]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
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

/// Resultado de la ejecución de un comando
class CommandResult {
  final bool success;
  final int exitCode;
  final String stdout;
  final String stderr;
  final Duration? executionTime;

  CommandResult({
    required this.success,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    this.executionTime,
  });

  // Alias para compatibilidad
  String get output => stdout;
  String get error => stderr;

  @override
  String toString() {
    return 'CommandResult(success: $success, exitCode: $exitCode, stdout: $stdout, stderr: $stderr)';
  }
}
