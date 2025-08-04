import 'dart:io';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import "dart:developer" as dev;

// Enum para niveles de log
enum LogLevel { debug, info, warning, error, fatal }

/// Sistema avanzado de logging y monitoreo para HACKOMATIC
class AdvancedLoggingService {
  static const String _tag = 'AdvancedLoggingService';
  static AdvancedLoggingService? _instance;

  Logger? _logger;
  Database? _database;
  File? _logFile;
  bool _isInitialized = false;

  final List<LogEntry> _memoryLogs = [];
  final int _maxMemoryLogs = 1000;

  static AdvancedLoggingService get instance {
    _instance ??= AdvancedLoggingService._internal();
    return _instance!;
  }

  AdvancedLoggingService._internal();

  /// Inicializar el sistema de logging
  Future<void> initialize() async {
    if (_isInitialized) return; // Ya está inicializado

    try {
      await _initializeLogger();
      await _initializeDatabase();
      await _initializeLogFile();

      _isInitialized = true;
      info('AdvancedLoggingService initialized successfully');
    } catch (e) {
      dev.log('Error initializing AdvancedLoggingService: $e');
      // Continuar sin fallar para permitir que la app funcione
    }
  }

  /// Configurar el logger
  Future<void> _initializeLogger() async {
    _logger = Logger(
      filter: ProductionFilter(),
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
      output: MultiOutput([
        ConsoleOutput(),
        FileOutput(file: await _getLogFile()),
      ]),
    );
  }

  /// Inicializar base de datos para logs
  Future<void> _initializeDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/hackomatic_logs.db';

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE logs (
            id TEXT PRIMARY KEY,
            timestamp INTEGER,
            level TEXT,
            category TEXT,
            message TEXT,
            details TEXT,
            session_id TEXT,
            user_id TEXT,
            device_info TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE performance_metrics (
            id TEXT PRIMARY KEY,
            timestamp INTEGER,
            metric_name TEXT,
            metric_value REAL,
            metric_unit TEXT,
            session_id TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE security_events (
            id TEXT PRIMARY KEY,
            timestamp INTEGER,
            event_type TEXT,
            severity TEXT,
            description TEXT,
            source_ip TEXT,
            user_agent TEXT,
            session_id TEXT
          )
        ''');
      },
    );
  }

  /// Obtener archivo de log
  Future<File> _getLogFile() async {
    final directory = await getApplicationDocumentsDirectory();
    _logFile = File('${directory.path}/hackomatic.log');
    return _logFile!;
  }

  /// Inicializar archivo de log
  Future<void> _initializeLogFile() async {
    _logFile = await _getLogFile();

    if (!await _logFile!.exists()) {
      await _logFile!.create(recursive: true);
    }

    // Rotar log si es muy grande (>10MB)
    final stats = await _logFile!.stat();
    if (stats.size > 10 * 1024 * 1024) {
      await _rotateLogFile();
    }
  }

  /// Rotar archivo de log
  Future<void> _rotateLogFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupFile = File('${directory.path}/hackomatic_$timestamp.log');

    await _logFile!.copy(backupFile.path);
    await _logFile!.writeAsString('');

    info('Log file rotated. Backup created: ${backupFile.path}');
  }

  /// Log de información
  void info(String message, {Map<String, dynamic>? details, String? category}) {
    try {
      _log(LogLevel.info, message, details: details, category: category);
    } catch (e) {
      dev.log('[INFO] $message');
    }
  }

  /// Log de debug
  void debug(
    String message, {
    Map<String, dynamic>? details,
    String? category,
  }) {
    try {
      _log(LogLevel.debug, message, details: details, category: category);
    } catch (e) {
      dev.log('[DEBUG] $message');
    }
  }

  /// Log de warning
  void warning(
    String message, {
    Map<String, dynamic>? details,
    String? category,
  }) {
    try {
      _log(LogLevel.warning, message, details: details, category: category);
    } catch (e) {
      dev.log('[WARNING] $message');
    }
  }

  /// Log de error
  void error(
    String message, {
    Map<String, dynamic>? details,
    String? category,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (error != null) {
      details ??= {};
      details['error'] = error.toString();
      if (stackTrace != null) {
        details['stackTrace'] = stackTrace.toString();
      }
    }
    try {
      _log(LogLevel.error, message, details: details, category: category);
    } catch (e) {
      dev.log('[ERROR] $message');
    }
  }

  /// Log crítico
  void critical(
    String message, {
    Map<String, dynamic>? details,
    String? category,
  }) {
    try {
      _log(LogLevel.fatal, message, details: details, category: category);
    } catch (e) {
      dev.log('[CRITICAL] $message');
    }
  }

  /// Log de evento de seguridad
  void securityEvent(
    String eventType,
    String description, {
    String severity = 'medium',
    String? sourceIp,
    String? userAgent,
    Map<String, dynamic>? details,
  }) {
    final event = SecurityEvent(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      eventType: eventType,
      severity: severity,
      description: description,
      sourceIp: sourceIp,
      userAgent: userAgent,
      sessionId: _getCurrentSessionId(),
    );

    _logSecurityEvent(event);
    _log(
      LogLevel.warning,
      'SECURITY EVENT: $eventType - $description',
      details: details,
      category: 'SECURITY',
    );
  }

  /// Log de métricas de rendimiento
  void performanceMetric(String metricName, double value, String unit) {
    final metric = PerformanceMetric(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      metricName: metricName,
      metricValue: value,
      metricUnit: unit,
      sessionId: _getCurrentSessionId(),
    );

    _logPerformanceMetric(metric);
    debug('PERFORMANCE: $metricName = $value $unit', category: 'PERFORMANCE');
  }

  /// Log interno
  void _log(
    LogLevel level,
    String message, {
    Map<String, dynamic>? details,
    String? category,
  }) {
    final logEntry = LogEntry(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      level: level,
      category: category ?? 'GENERAL',
      message: message,
      details: details,
      sessionId: _getCurrentSessionId(),
      userId: _getCurrentUserId(),
      deviceInfo: _getDeviceInfo(),
    );

    // Agregar a memoria
    _memoryLogs.add(logEntry);
    if (_memoryLogs.length > _maxMemoryLogs) {
      _memoryLogs.removeAt(0);
    }

    // Log al archivo y consola (solo si está inicializado)
    if (_logger != null) {
      switch (level) {
        case LogLevel.debug:
          _logger!.d(message);
          break;
        case LogLevel.info:
          _logger!.i(message);
          break;
        case LogLevel.warning:
          _logger!.w(message);
          break;
        case LogLevel.error:
          _logger!.e(message);
          break;
        case LogLevel.fatal:
          _logger!.f(message);
          break;
      }
    } else {
      // Fallback a print si el logger no está inicializado
      dev.log('[$level] $message');
    }

    // Guardar en base de datos (async)
    _saveToDatabase(
      logEntry.level,
      logEntry.message,
      logEntry.category,
      logEntry.details ?? {},
    );
  }

  /// Guardar log en base de datos
  Future<void> _saveToDatabase(
    LogLevel level,
    String message,
    String? className,
    Map<String, dynamic> metadata,
  ) async {
    try {
      if (_database == null) {
        // Si la base de datos no está inicializada, no hacer nada
        return;
      }

      await _database!.insert('logs', {
        'id': _generateId(),
        'timestamp': DateTime.now().toIso8601String(),
        'level': level.toString().split('.').last,
        'message': message,
        'className': className,
        'metadata': metadata.isNotEmpty ? json.encode(metadata) : null,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Solo imprimir el error, no intentar guardarlo en la base de datos
      // para evitar recursión infinita
      dev.log('Error saving log to database: $e');
    }
  }

  /// Generar ID único para logs
  String _generateId() {
    return const Uuid().v4();
  }

  /// Guardar evento de seguridad
  Future<void> _logSecurityEvent(SecurityEvent event) async {
    try {
      if (_database != null) {
        await _database!.insert('security_events', event.toMap());
      }
    } catch (e) {
      dev.log('Error saving security event: $e');
    }
  }

  /// Guardar métrica de rendimiento
  Future<void> _logPerformanceMetric(PerformanceMetric metric) async {
    try {
      if (_database != null) {
        await _database!.insert('performance_metrics', metric.toMap());
      }
    } catch (e) {
      dev.log('Error saving performance metric: $e');
    }
  }

  /// Obtener logs recientes
  Future<List<LogEntry>> getRecentLogs({
    int limit = 100,
    String? category,
    LogLevel? level,
  }) async {
    String where = '';
    List<dynamic> whereArgs = [];

    if (category != null) {
      where += 'category = ?';
      whereArgs.add(category);
    }

    if (level != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'level = ?';
      whereArgs.add(level.toString());
    }

    if (_database == null) {
      return [];
    }

    final maps = await _database!.query(
      'logs',
      where: where.isEmpty ? null : where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps.map((map) => LogEntry.fromMap(map)).toList();
  }

  /// Obtener eventos de seguridad
  Future<List<SecurityEvent>> getSecurityEvents({int limit = 50}) async {
    if (_database == null) {
      return [];
    }

    final maps = await _database!.query(
      'security_events',
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps.map((map) => SecurityEvent.fromMap(map)).toList();
  }

  /// Obtener métricas de rendimiento
  Future<List<PerformanceMetric>> getPerformanceMetrics({
    int limit = 100,
    String? metricName,
  }) async {
    if (_database == null) {
      return [];
    }

    String? where;
    List<dynamic>? whereArgs;

    if (metricName != null) {
      where = 'metric_name = ?';
      whereArgs = [metricName];
    }

    final maps = await _database!.query(
      'performance_metrics',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps.map((map) => PerformanceMetric.fromMap(map)).toList();
  }

  /// Obtener estadísticas de logs
  Future<Map<String, int>> getLogStatistics() async {
    if (_database == null) {
      return {};
    }

    final result = await _database!.rawQuery(
      '''
      SELECT level, COUNT(*) as count
      FROM logs
      WHERE timestamp > ?
      GROUP BY level
    ''',
      [DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch],
    );

    final stats = <String, int>{};
    for (final row in result) {
      stats[row['level'] as String] = row['count'] as int;
    }

    return stats;
  }

  /// Exportar logs
  Future<String> exportLogs({DateTime? fromDate, DateTime? toDate}) async {
    String where = '';
    List<dynamic> whereArgs = [];

    if (fromDate != null) {
      where += 'timestamp >= ?';
      whereArgs.add(fromDate.millisecondsSinceEpoch);
    }

    if (toDate != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'timestamp <= ?';
      whereArgs.add(toDate.millisecondsSinceEpoch);
    }

    if (_database == null) {
      return json.encode({'error': 'Database not initialized'});
    }

    final logs = await _database!.query(
      'logs',
      where: where.isEmpty ? null : where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'timestamp ASC',
    );

    final export = {
      'export_info': {
        'timestamp': DateTime.now().toIso8601String(),
        'from_date': fromDate?.toIso8601String(),
        'to_date': toDate?.toIso8601String(),
        'total_logs': logs.length,
      },
      'logs': logs,
    };

    return jsonEncode(export);
  }

  /// Limpiar logs antiguos
  Future<void> cleanOldLogs({int daysToKeep = 30}) async {
    if (_database == null) {
      return;
    }

    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

    await _database!.delete(
      'logs',
      where: 'timestamp < ?',
      whereArgs: [cutoffDate.millisecondsSinceEpoch],
    );

    await _database!.delete(
      'security_events',
      where: 'timestamp < ?',
      whereArgs: [cutoffDate.millisecondsSinceEpoch],
    );

    await _database!.delete(
      'performance_metrics',
      where: 'timestamp < ?',
      whereArgs: [cutoffDate.millisecondsSinceEpoch],
    );

    info('Cleaned logs older than $daysToKeep days');
  }

  /// Obtener ID de sesión actual
  String _getCurrentSessionId() {
    // Implementar lógica para obtener ID de sesión
    return 'session_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Obtener ID de usuario actual
  String _getCurrentUserId() {
    // Implementar lógica para obtener ID de usuario
    return Platform.environment['USER'] ?? 'unknown';
  }

  /// Obtener información del dispositivo
  String _getDeviceInfo() {
    return '${Platform.operatingSystem}_${Platform.operatingSystemVersion}';
  }
}

/// Clase para entrada de log
class LogEntry {
  final String id;
  final DateTime timestamp;
  final LogLevel level;
  final String category;
  final String message;
  final Map<String, dynamic>? details;
  final String sessionId;
  final String userId;
  final String deviceInfo;

  LogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.category,
    required this.message,
    this.details,
    required this.sessionId,
    required this.userId,
    required this.deviceInfo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'level': level.toString(),
      'category': category,
      'message': message,
      'details': details != null ? jsonEncode(details) : null,
      'session_id': sessionId,
      'user_id': userId,
      'device_info': deviceInfo,
    };
  }

  factory LogEntry.fromMap(Map<String, dynamic> map) {
    return LogEntry(
      id: map['id'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      level: _parseLogLevel(map['level']),
      category: map['category'],
      message: map['message'],
      details: map['details'] != null ? jsonDecode(map['details']) : null,
      sessionId: map['session_id'],
      userId: map['user_id'],
      deviceInfo: map['device_info'],
    );
  }

  static LogLevel _parseLogLevel(String level) {
    switch (level) {
      case 'Level.debug':
        return LogLevel.debug;
      case 'Level.info':
        return LogLevel.info;
      case 'Level.warning':
        return LogLevel.warning;
      case 'Level.error':
        return LogLevel.error;
      case 'Level.fatal':
        return LogLevel.fatal;
      default:
        return LogLevel.info;
    }
  }
}

/// Clase para eventos de seguridad
class SecurityEvent {
  final String id;
  final DateTime timestamp;
  final String eventType;
  final String severity;
  final String description;
  final String? sourceIp;
  final String? userAgent;
  final String sessionId;

  SecurityEvent({
    required this.id,
    required this.timestamp,
    required this.eventType,
    required this.severity,
    required this.description,
    this.sourceIp,
    this.userAgent,
    required this.sessionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'event_type': eventType,
      'severity': severity,
      'description': description,
      'source_ip': sourceIp,
      'user_agent': userAgent,
      'session_id': sessionId,
    };
  }

  factory SecurityEvent.fromMap(Map<String, dynamic> map) {
    return SecurityEvent(
      id: map['id'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      eventType: map['event_type'],
      severity: map['severity'],
      description: map['description'],
      sourceIp: map['source_ip'],
      userAgent: map['user_agent'],
      sessionId: map['session_id'],
    );
  }
}

/// Clase para métricas de rendimiento
class PerformanceMetric {
  final String id;
  final DateTime timestamp;
  final String metricName;
  final double metricValue;
  final String metricUnit;
  final String sessionId;

  PerformanceMetric({
    required this.id,
    required this.timestamp,
    required this.metricName,
    required this.metricValue,
    required this.metricUnit,
    required this.sessionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'metric_name': metricName,
      'metric_value': metricValue,
      'metric_unit': metricUnit,
      'session_id': sessionId,
    };
  }

  factory PerformanceMetric.fromMap(Map<String, dynamic> map) {
    return PerformanceMetric(
      id: map['id'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      metricName: map['metric_name'],
      metricValue: map['metric_value'],
      metricUnit: map['metric_unit'],
      sessionId: map['session_id'],
    );
  }
}

/// Output personalizado para archivo
class FileOutput extends LogOutput {
  final File file;

  FileOutput({required this.file});

  @override
  void output(OutputEvent event) {
    final timestamp = DateTime.now().toIso8601String();
    final lines = event.lines.map((line) => '[$timestamp] $line').join('\n');
    file.writeAsStringSync('$lines\n', mode: FileMode.append);
  }
}
