import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/advanced_logging_service.dart';
import '../services/command_execution_service.dart';

/// Terminal avanzado con logging completo y funcionalidades de hacking
class AdvancedTerminalService extends ChangeNotifier {
  static const String _tag = 'AdvancedTerminalService';
  final AdvancedLoggingService _logger = AdvancedLoggingService.instance;
  final CommandExecutionService _commandService = CommandExecutionService();

  // Estado del terminal
  final List<TerminalEntry> _history = [];
  final List<String> _commandHistory = [];
  String _currentDirectory = '';
  String _currentUser = '';
  String _currentHost = '';
  Map<String, String> _environmentVariables = {};

  // Configuración del terminal
  Color _backgroundColor = const Color(0xFF0A0A0A);
  Color _textColor = const Color(0xFF00FF41);
  Color _errorColor = const Color(0xFFFF0044);
  Color _warningColor = const Color(0xFFFFAA00);
  Color _successColor = const Color(0xFF00FF41);
  double _fontSize = 14.0;
  String _fontFamily = 'monospace';

  // Control de sesión
  bool _isSessionActive = false;
  String _sessionId = '';
  DateTime? _sessionStartTime;
  int _commandCount = 0;

  // Aliases y shortcuts
  final Map<String, String> _aliases = {
    'll': 'ls -la',
    'la': 'ls -A',
    'l': 'ls -CF',
    'cls': 'clear',
    'h': 'history',
    'grep': 'grep --color=auto',
    'fgrep': 'fgrep --color=auto',
    'egrep': 'egrep --color=auto',
  };

  // Getters
  List<TerminalEntry> get history => List.unmodifiable(_history);
  List<String> get commandHistory => List.unmodifiable(_commandHistory);
  String get currentDirectory => _currentDirectory;
  String get currentUser => _currentUser;
  String get currentHost => _currentHost;
  String get prompt => '[$_currentUser@$_currentHost $_currentDirectory]\$ ';
  bool get isSessionActive => _isSessionActive;
  int get commandCount => _commandCount;

  Color get backgroundColor => _backgroundColor;
  Color get textColor => _textColor;
  Color get errorColor => _errorColor;
  Color get warningColor => _warningColor;
  Color get successColor => _successColor;
  double get fontSize => _fontSize;
  String get fontFamily => _fontFamily;

  /// Inicializar terminal
  Future<void> initialize() async {
    _logger.info('$_tag: Initializing advanced terminal');

    await _loadConfiguration();
    await _initializeEnvironment();
    await _startSession();

    _addWelcomeMessage();
    _logger.info('$_tag: Terminal initialized successfully');
  }

  /// Cargar configuración del terminal
  Future<void> _loadConfiguration() async {
    final prefs = await SharedPreferences.getInstance();

    _backgroundColor = Color(prefs.getInt('terminal_bg_color') ?? 0xFF0A0A0A);
    _textColor = Color(prefs.getInt('terminal_text_color') ?? 0xFF00FF41);
    _errorColor = Color(prefs.getInt('terminal_error_color') ?? 0xFFFF0044);
    _warningColor = Color(prefs.getInt('terminal_warning_color') ?? 0xFFFFAA00);
    _successColor = Color(prefs.getInt('terminal_success_color') ?? 0xFF00FF41);
    _fontSize = prefs.getDouble('terminal_font_size') ?? 14.0;
    _fontFamily = prefs.getString('terminal_font_family') ?? 'monospace';

    // Cargar aliases personalizados
    final customAliases = prefs.getStringList('terminal_aliases') ?? [];
    for (final alias in customAliases) {
      final parts = alias.split('=');
      if (parts.length == 2) {
        _aliases[parts[0]] = parts[1];
      }
    }

    _logger.debug('$_tag: Configuration loaded');
  }

  /// Inicializar entorno
  Future<void> _initializeEnvironment() async {
    _currentUser = Platform.environment['USER'] ?? 'user';
    _currentHost = Platform.localHostname;
    _currentDirectory = Directory.current.path;
    _environmentVariables = Map.from(Platform.environment);

    _logger.debug(
      '$_tag: Environment initialized - User: $_currentUser, Host: $_currentHost',
    );
  }

  /// Iniciar sesión de terminal
  Future<void> _startSession() async {
    _sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    _sessionStartTime = DateTime.now();
    _isSessionActive = true;
    _commandCount = 0;

    _logger.info(
      '$_tag: Terminal session started',
      details: {
        'session_id': _sessionId,
        'user': _currentUser,
        'host': _currentHost,
      },
    );
  }

  /// Agregar mensaje de bienvenida
  void _addWelcomeMessage() {
    final welcomeText =
        '''
╔══════════════════════════════════════════════════════════════════╗
║                        HACKOMATIC TERMINAL                       ║
║                    Advanced Penetration Testing                  ║
╠══════════════════════════════════════════════════════════════════╣
║ Session ID: $_sessionId                   ║
║ User: $_currentUser@$_currentHost                                          ║
║ Directory: $_currentDirectory                                    ║
║ Time: ${DateTime.now().toLocal()}                               ║
╚══════════════════════════════════════════════════════════════════╝

Welcome to HACKOMATIC Terminal! Type 'help' for available commands.
''';

    _addEntry(
      TerminalEntry(
        type: TerminalEntryType.system,
        content: welcomeText,
        timestamp: DateTime.now(),
        color: _successColor,
      ),
    );
  }

  /// Ejecutar comando
  Future<void> executeCommand(String command) async {
    if (command.trim().isEmpty) return;

    _logger.info('$_tag: Executing command', details: {'command': command});

    // Agregar comando al historial
    _commandHistory.add(command);
    _commandCount++;

    // Mostrar comando en terminal
    _addEntry(
      TerminalEntry(
        type: TerminalEntryType.command,
        content: '$prompt$command',
        timestamp: DateTime.now(),
        color: _textColor,
      ),
    );

    // Procesar comando
    await _processCommand(command.trim());
    notifyListeners();
  }

  /// Procesar comando
  Future<void> _processCommand(String command) async {
    try {
      // Verificar comandos internos primero
      if (await _handleInternalCommand(command)) {
        return;
      }

      // Expandir aliases
      command = _expandAliases(command);

      // Ejecutar comando del sistema
      final result = await _commandService.executeCommand(command);

      // Mostrar resultado
      if (result.success) {
        if (result.output.isNotEmpty) {
          _addEntry(
            TerminalEntry(
              type: TerminalEntryType.output,
              content: result.output,
              timestamp: DateTime.now(),
              color: _textColor,
              executionTime: result.executionTime?.inMilliseconds.toDouble(),
            ),
          );
        }

        _logger.performanceMetric(
          'command_execution_time',
          result.executionTime?.inMilliseconds.toDouble() ?? 0.0,
          'milliseconds',
        );
      } else {
        _addEntry(
          TerminalEntry(
            type: TerminalEntryType.error,
            content: result.error,
            timestamp: DateTime.now(),
            color: _errorColor,
            executionTime: result.executionTime?.inMilliseconds.toDouble(),
          ),
        );

        _logger.error(
          '$_tag: Command execution failed',
          details: {'command': command, 'error': result.error},
        );
      }
    } catch (e) {
      _addEntry(
        TerminalEntry(
          type: TerminalEntryType.error,
          content: 'Error: $e',
          timestamp: DateTime.now(),
          color: _errorColor,
        ),
      );

      _logger.error(
        '$_tag: Exception during command execution',
        error: e,
        details: {'command': command},
      );
    }
  }

  /// Manejar comandos internos
  Future<bool> _handleInternalCommand(String command) async {
    final parts = command.split(' ');
    final cmd = parts[0].toLowerCase();

    switch (cmd) {
      case 'help':
        _showHelp();
        return true;

      case 'clear':
        _clearTerminal();
        return true;

      case 'history':
        _showHistory();
        return true;

      case 'alias':
        if (parts.length > 1) {
          _addAlias(parts.sublist(1).join(' '));
        } else {
          _showAliases();
        }
        return true;

      case 'env':
        _showEnvironment();
        return true;

      case 'pwd':
        _addEntry(
          TerminalEntry(
            type: TerminalEntryType.output,
            content: _currentDirectory,
            timestamp: DateTime.now(),
            color: _textColor,
          ),
        );
        return true;

      case 'cd':
        if (parts.length > 1) {
          await _changeDirectory(parts[1]);
        } else {
          await _changeDirectory(
            _environmentVariables['HOME'] ?? '/home/$_currentUser',
          );
        }
        return true;

      case 'session':
        _showSessionInfo();
        return true;

      case 'theme':
        if (parts.length > 1) {
          _changeTheme(parts[1]);
        } else {
          _showThemes();
        }
        return true;

      case 'log':
        if (parts.length > 1) {
          await _handleLogCommand(parts.sublist(1));
        } else {
          _showLogHelp();
        }
        return true;

      case 'hack':
        _showHackCommands();
        return true;

      default:
        return false;
    }
  }

  /// Expandir aliases
  String _expandAliases(String command) {
    final parts = command.split(' ');
    final cmd = parts[0];

    if (_aliases.containsKey(cmd)) {
      parts[0] = _aliases[cmd]!;
      return parts.join(' ');
    }

    return command;
  }

  /// Agregar entrada al terminal
  void _addEntry(TerminalEntry entry) {
    _history.add(entry);

    // Limitar historial a 1000 entradas
    if (_history.length > 1000) {
      _history.removeAt(0);
    }
  }

  /// Mostrar ayuda
  void _showHelp() {
    final helpText = '''
HACKOMATIC Terminal - Available Commands:

System Commands:
  help          - Show this help message
  clear         - Clear terminal screen
  history       - Show command history
  pwd           - Show current directory
  cd [dir]      - Change directory
  env           - Show environment variables
  session       - Show session information

Terminal Commands:
  alias [name=cmd] - Create alias or show all aliases
  theme [name]     - Change theme or show available themes
  log [options]    - Manage logs (show, export, clear)

Hacking Commands:
  hack             - Show available hacking tools
  nmap [options]   - Network scanning
  gobuster [opts]  - Directory/DNS bruteforcing
  nikto [target]   - Web vulnerability scanner
  hydra [options]  - Login bruteforcer
  sqlmap [url]     - SQL injection scanner

Navigation:
  Use ↑/↓ arrows for command history
  Use Tab for auto-completion
  Use Ctrl+C to interrupt commands
  Use Ctrl+L to clear screen

Type any Linux command to execute it directly.
''';

    _addEntry(
      TerminalEntry(
        type: TerminalEntryType.info,
        content: helpText,
        timestamp: DateTime.now(),
        color: _successColor,
      ),
    );
  }

  /// Limpiar terminal
  void _clearTerminal() {
    _history.clear();
    _addWelcomeMessage();
    _logger.debug('$_tag: Terminal cleared');
  }

  /// Mostrar historial
  void _showHistory() {
    final historyText = _commandHistory
        .asMap()
        .entries
        .map((entry) => '${entry.key + 1}: ${entry.value}')
        .join('\n');

    _addEntry(
      TerminalEntry(
        type: TerminalEntryType.info,
        content: 'Command History:\n$historyText',
        timestamp: DateTime.now(),
        color: _textColor,
      ),
    );
  }

  /// Agregar alias
  void _addAlias(String aliasDefinition) {
    final parts = aliasDefinition.split('=');
    if (parts.length == 2) {
      final name = parts[0].trim();
      final command = parts[1].trim();
      _aliases[name] = command;

      _addEntry(
        TerminalEntry(
          type: TerminalEntryType.success,
          content: 'Alias added: $name -> $command',
          timestamp: DateTime.now(),
          color: _successColor,
        ),
      );

      _saveAliases();
      _logger.info(
        '$_tag: Alias added',
        details: {'name': name, 'command': command},
      );
    } else {
      _addEntry(
        TerminalEntry(
          type: TerminalEntryType.error,
          content: 'Invalid alias format. Use: alias name=command',
          timestamp: DateTime.now(),
          color: _errorColor,
        ),
      );
    }
  }

  /// Mostrar aliases
  void _showAliases() {
    final aliasText = _aliases.entries
        .map((entry) => '${entry.key} -> ${entry.value}')
        .join('\n');

    _addEntry(
      TerminalEntry(
        type: TerminalEntryType.info,
        content: 'Current Aliases:\n$aliasText',
        timestamp: DateTime.now(),
        color: _textColor,
      ),
    );
  }

  /// Mostrar variables de entorno
  void _showEnvironment() {
    final envText = _environmentVariables.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('\n');

    _addEntry(
      TerminalEntry(
        type: TerminalEntryType.info,
        content: 'Environment Variables:\n$envText',
        timestamp: DateTime.now(),
        color: _textColor,
      ),
    );
  }

  /// Cambiar directorio
  Future<void> _changeDirectory(String path) async {
    try {
      final dir = Directory(path);
      if (await dir.exists()) {
        Directory.current = dir;
        _currentDirectory = dir.path;

        _addEntry(
          TerminalEntry(
            type: TerminalEntryType.success,
            content: 'Changed directory to: $path',
            timestamp: DateTime.now(),
            color: _successColor,
          ),
        );
      } else {
        _addEntry(
          TerminalEntry(
            type: TerminalEntryType.error,
            content: 'Directory not found: $path',
            timestamp: DateTime.now(),
            color: _errorColor,
          ),
        );
      }
    } catch (e) {
      _addEntry(
        TerminalEntry(
          type: TerminalEntryType.error,
          content: 'Error changing directory: $e',
          timestamp: DateTime.now(),
          color: _errorColor,
        ),
      );
    }
  }

  /// Mostrar información de sesión
  void _showSessionInfo() {
    final duration = _sessionStartTime != null
        ? DateTime.now().difference(_sessionStartTime!)
        : Duration.zero;

    final sessionInfo =
        '''
Session Information:
  Session ID: $_sessionId
  Started: ${_sessionStartTime?.toLocal()}
  Duration: ${duration.inHours}h ${duration.inMinutes.remainder(60)}m ${duration.inSeconds.remainder(60)}s
  Commands executed: $_commandCount
  User: $_currentUser
  Host: $_currentHost
  Current directory: $_currentDirectory
''';

    _addEntry(
      TerminalEntry(
        type: TerminalEntryType.info,
        content: sessionInfo,
        timestamp: DateTime.now(),
        color: _successColor,
      ),
    );
  }

  /// Cambiar tema
  void _changeTheme(String themeName) {
    switch (themeName.toLowerCase()) {
      case 'dark':
        _backgroundColor = const Color(0xFF0A0A0A);
        _textColor = const Color(0xFF00FF41);
        break;
      case 'blue':
        _backgroundColor = const Color(0xFF001122);
        _textColor = const Color(0xFF00AAFF);
        break;
      case 'amber':
        _backgroundColor = const Color(0xFF221100);
        _textColor = const Color(0xFFFFAA00);
        break;
      case 'red':
        _backgroundColor = const Color(0xFF220000);
        _textColor = const Color(0xFFFF4444);
        break;
      default:
        _addEntry(
          TerminalEntry(
            type: TerminalEntryType.error,
            content: 'Unknown theme: $themeName',
            timestamp: DateTime.now(),
            color: _errorColor,
          ),
        );
        return;
    }

    _saveConfiguration();
    notifyListeners();

    _addEntry(
      TerminalEntry(
        type: TerminalEntryType.success,
        content: 'Theme changed to: $themeName',
        timestamp: DateTime.now(),
        color: _successColor,
      ),
    );
  }

  /// Mostrar temas disponibles
  void _showThemes() {
    const themesText = '''
Available Themes:
  dark   - Green on black (default)
  blue   - Blue on dark blue
  amber  - Amber on dark yellow
  red    - Red on dark red

Usage: theme [name]
''';

    _addEntry(
      TerminalEntry(
        type: TerminalEntryType.info,
        content: themesText,
        timestamp: DateTime.now(),
        color: _textColor,
      ),
    );
  }

  /// Manejar comandos de log
  Future<void> _handleLogCommand(List<String> args) async {
    if (args.isEmpty) {
      _showLogHelp();
      return;
    }

    switch (args[0].toLowerCase()) {
      case 'show':
        await _showLogs();
        break;
      case 'export':
        await _exportLogs();
        break;
      case 'clear':
        await _clearLogs();
        break;
      case 'stats':
        await _showLogStats();
        break;
      default:
        _showLogHelp();
    }
  }

  /// Mostrar ayuda de logs
  void _showLogHelp() {
    const logHelpText = '''
Log Management Commands:
  log show     - Show recent logs
  log export   - Export logs to file
  log clear    - Clear old logs
  log stats    - Show log statistics
''';

    _addEntry(
      TerminalEntry(
        type: TerminalEntryType.info,
        content: logHelpText,
        timestamp: DateTime.now(),
        color: _textColor,
      ),
    );
  }

  /// Mostrar logs recientes
  Future<void> _showLogs() async {
    try {
      final logs = await _logger.getRecentLogs(limit: 20);
      final logsText = logs
          .map(
            (log) =>
                '[${log.timestamp.toLocal()}] ${log.level}: ${log.message}',
          )
          .join('\n');

      _addEntry(
        TerminalEntry(
          type: TerminalEntryType.info,
          content: 'Recent Logs:\n$logsText',
          timestamp: DateTime.now(),
          color: _textColor,
        ),
      );
    } catch (e) {
      _addEntry(
        TerminalEntry(
          type: TerminalEntryType.error,
          content: 'Error retrieving logs: $e',
          timestamp: DateTime.now(),
          color: _errorColor,
        ),
      );
    }
  }

  /// Exportar logs
  Future<void> _exportLogs() async {
    try {
      final exportData = await _logger.exportLogs();
      // Aquí podrías guardar en un archivo

      _addEntry(
        TerminalEntry(
          type: TerminalEntryType.success,
          content:
              'Logs exported successfully (${exportData.length} characters)',
          timestamp: DateTime.now(),
          color: _successColor,
        ),
      );
    } catch (e) {
      _addEntry(
        TerminalEntry(
          type: TerminalEntryType.error,
          content: 'Error exporting logs: $e',
          timestamp: DateTime.now(),
          color: _errorColor,
        ),
      );
    }
  }

  /// Limpiar logs antiguos
  Future<void> _clearLogs() async {
    try {
      await _logger.cleanOldLogs();

      _addEntry(
        TerminalEntry(
          type: TerminalEntryType.success,
          content: 'Old logs cleared successfully',
          timestamp: DateTime.now(),
          color: _successColor,
        ),
      );
    } catch (e) {
      _addEntry(
        TerminalEntry(
          type: TerminalEntryType.error,
          content: 'Error clearing logs: $e',
          timestamp: DateTime.now(),
          color: _errorColor,
        ),
      );
    }
  }

  /// Mostrar estadísticas de logs
  Future<void> _showLogStats() async {
    try {
      final stats = await _logger.getLogStatistics();
      final statsText = stats.entries
          .map((entry) => '${entry.key}: ${entry.value}')
          .join('\n');

      _addEntry(
        TerminalEntry(
          type: TerminalEntryType.info,
          content: 'Log Statistics:\n$statsText',
          timestamp: DateTime.now(),
          color: _textColor,
        ),
      );
    } catch (e) {
      _addEntry(
        TerminalEntry(
          type: TerminalEntryType.error,
          content: 'Error retrieving log statistics: $e',
          timestamp: DateTime.now(),
          color: _errorColor,
        ),
      );
    }
  }

  /// Mostrar comandos de hacking
  void _showHackCommands() {
    const hackText = '''
Available Hacking Tools:

Reconnaissance:
  nmap -sn [range]     - Network discovery
  nmap -sV [target]    - Service detection
  nmap -A [target]     - Aggressive scan
  dig [domain]         - DNS lookup
  whois [domain]       - Domain information

Web Application:
  gobuster dir -u [url] -w [wordlist]  - Directory enumeration
  nikto -h [target]                    - Web vulnerability scan
  sqlmap -u [url]                      - SQL injection test
  curl -I [url]                        - HTTP headers

Wireless:
  iwlist scan                          - WiFi scan
  airmon-ng start [interface]          - Monitor mode
  airodump-ng [interface]              - Capture packets

Password Attacks:
  hydra -l [user] -P [pass] [target] [service]  - Brute force
  john [hashfile]                               - Password cracking

Use 'help' for general terminal commands.
''';

    _addEntry(
      TerminalEntry(
        type: TerminalEntryType.info,
        content: hackText,
        timestamp: DateTime.now(),
        color: _successColor,
      ),
    );
  }

  /// Guardar configuración
  Future<void> _saveConfiguration() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('terminal_bg_color', _backgroundColor.toARGB32());
    await prefs.setInt('terminal_text_color', _textColor.toARGB32());
    await prefs.setInt('terminal_error_color', _errorColor.toARGB32());
    await prefs.setInt('terminal_warning_color', _warningColor.toARGB32());
    await prefs.setInt('terminal_success_color', _successColor.toARGB32());
    await prefs.setDouble('terminal_font_size', _fontSize);
    await prefs.setString('terminal_font_family', _fontFamily);
  }

  /// Guardar aliases
  Future<void> _saveAliases() async {
    final prefs = await SharedPreferences.getInstance();
    final aliasesList = _aliases.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .toList();
    await prefs.setStringList('terminal_aliases', aliasesList);
  }

  /// Terminar sesión
  void endSession() {
    _isSessionActive = false;
    _logger.info(
      '$_tag: Terminal session ended',
      details: {
        'session_id': _sessionId,
        'duration_minutes': _sessionStartTime != null
            ? DateTime.now().difference(_sessionStartTime!).inMinutes
            : 0,
        'commands_executed': _commandCount,
      },
    );
  }
}

/// Tipos de entrada del terminal
enum TerminalEntryType {
  command,
  output,
  error,
  warning,
  success,
  info,
  system,
}

/// Entrada del terminal
class TerminalEntry {
  final TerminalEntryType type;
  final String content;
  final DateTime timestamp;
  final Color color;
  final double? executionTime;

  TerminalEntry({
    required this.type,
    required this.content,
    required this.timestamp,
    required this.color,
    this.executionTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'color': color.toARGB32(),
      'execution_time': executionTime,
    };
  }
}
