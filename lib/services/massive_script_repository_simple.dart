import '../models/hacking_script.dart';
import 'command_execution_service.dart';
import 'advanced_logging_service.dart';

/// Repositorio simplificado temporal de scripts
class MassiveScriptRepository {
  final CommandExecutionService _commandService;
  final AdvancedLoggingService _loggingService;

  MassiveScriptRepository({
    CommandExecutionService? commandService,
    AdvancedLoggingService? loggingService,
  }) : _commandService = commandService ?? CommandExecutionService(),
       _loggingService = loggingService ?? AdvancedLoggingService.instance;

  List<HackingScript> getAllScripts() {
    return [
      HackingScript(
        id: 'reconnaissance_001',
        name: 'Nmap Network Scan',
        description: 'Escaneo básico de red usando Nmap',
        category: 'Reconnaissance',
        scriptPath: 'scripts/reconnaissance/nmap_scan.sh',
        parameters: [],
        author: 'HACKOMATIC',
        createdAt: DateTime.now(),
        difficulty: 'Beginner',
        command: 'nmap -sP 192.168.1.0/24',
        tags: ['network', 'scan', 'discovery'],
        requiresSudo: false,
        estimatedTime: 30,
      ),
      HackingScript(
        id: 'reconnaissance_002',
        name: 'Port Scanner',
        description: 'Escaneo de puertos con Nmap',
        category: 'Reconnaissance',
        scriptPath: 'scripts/reconnaissance/port_scan.sh',
        parameters: [],
        author: 'HACKOMATIC',
        createdAt: DateTime.now(),
        difficulty: 'Intermediate',
        command: 'nmap -sS -O -A target',
        tags: ['ports', 'scan', 'fingerprint'],
        requiresSudo: true,
        estimatedTime: 120,
      ),
      HackingScript(
        id: 'wireless_001',
        name: 'WiFi Monitor Mode',
        description: 'Activar modo monitor en interfaz WiFi',
        category: 'Wireless',
        scriptPath: 'scripts/wireless/monitor_mode.sh',
        parameters: [],
        author: 'HACKOMATIC',
        createdAt: DateTime.now(),
        difficulty: 'Advanced',
        command: 'iwconfig wlan0 mode monitor',
        tags: ['wifi', 'monitor', 'wireless'],
        requiresSudo: true,
        estimatedTime: 15,
      ),
    ];
  }

  List<HackingScript> getScriptsByCategory(String category) {
    return getAllScripts()
        .where((script) => script.category == category)
        .toList();
  }

  List<HackingScript> getScriptsByDifficulty(String difficulty) {
    return getAllScripts()
        .where((script) => script.difficulty == difficulty)
        .toList();
  }

  List<HackingScript> searchScripts(String query) {
    final lowerQuery = query.toLowerCase();
    return getAllScripts().where((script) {
      return script.name.toLowerCase().contains(lowerQuery) ||
          script.description.toLowerCase().contains(lowerQuery) ||
          script.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  Future<Map<String, dynamic>> executeScript(HackingScript script) async {
    try {
      String command = script.command;

      _loggingService.info('Executing script: ${script.name}');

      final result = await _commandService.executeCommand(command);

      _loggingService.info(
        'Script execution completed',
        details: {
          'script': script.name,
          'success': result.success,
          'output': result.output,
        },
      );

      return {
        'success': result.success,
        'output': result.output,
        'error': result.error,
        'execution_time': result.executionTime,
        'script_name': script.name,
      };
    } catch (e) {
      _loggingService.error(
        'Script execution failed',
        details: {'error': e.toString()},
      );
      return {
        'success': false,
        'error': e.toString(),
        'script_name': script.name,
      };
    }
  }

  Map<String, dynamic> getRepositoryStats() {
    final allScripts = getAllScripts();
    final totalCount = allScripts.length;
    final requiresSudoCount = allScripts.where((s) => s.requiresSudo).length;

    final Map<String, int> categoryStats = {};
    final Map<String, int> difficultyStats = {};

    for (final script in allScripts) {
      categoryStats[script.category] =
          (categoryStats[script.category] ?? 0) + 1;
      difficultyStats[script.difficulty] =
          (difficultyStats[script.difficulty] ?? 0) + 1;
    }

    return {
      'total_scripts': totalCount,
      'requires_sudo': requiresSudoCount,
      'categories': categoryStats,
      'difficulties': difficultyStats,
      'available_categories': categoryStats.keys.toList(),
    };
  }
}
