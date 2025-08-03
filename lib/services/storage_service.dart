import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hacking_tool.dart';
import '../models/hacking_script.dart';
import '../models/hacking_task.dart';

class StorageService {
  static const String _toolsKey = 'hackomatic_tools';
  static const String _scriptsKey = 'hackomatic_scripts';
  static const String _tasksKey = 'hackomatic_tasks';

  // Tools
  Future<List<HackingTool>> loadTools() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final toolsJson = prefs.getString(_toolsKey);

      if (toolsJson == null) {
        return _getDefaultTools();
      }

      final List<dynamic> decoded = json.decode(toolsJson);
      return decoded.map((tool) => HackingTool.fromJson(tool)).toList();
    } catch (e) {
      return _getDefaultTools();
    }
  }

  Future<void> saveTools(List<HackingTool> tools) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final toolsJson = json.encode(
        tools.map((tool) => tool.toJson()).toList(),
      );
      await prefs.setString(_toolsKey, toolsJson);
    } catch (e) {
      // Handle error silently or log it
    }
  }

  // Scripts
  Future<List<HackingScript>> loadScripts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scriptsJson = prefs.getString(_scriptsKey);

      if (scriptsJson == null) {
        return _getDefaultScripts();
      }

      final List<dynamic> decoded = json.decode(scriptsJson);
      return decoded.map((script) => HackingScript.fromJson(script)).toList();
    } catch (e) {
      return _getDefaultScripts();
    }
  }

  Future<void> saveScripts(List<HackingScript> scripts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scriptsJson = json.encode(
        scripts.map((script) => script.toJson()).toList(),
      );
      await prefs.setString(_scriptsKey, scriptsJson);
    } catch (e) {
      // Handle error silently or log it
    }
  }

  // Tasks
  Future<List<HackingTask>> loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getString(_tasksKey);

      if (tasksJson == null) {
        return [];
      }

      final List<dynamic> decoded = json.decode(tasksJson);
      return decoded.map((task) => HackingTask.fromJson(task)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveTasks(List<HackingTask> tasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = json.encode(
        tasks.map((task) => task.toJson()).toList(),
      );
      await prefs.setString(_tasksKey, tasksJson);
    } catch (e) {
      // Handle error silently or log it
    }
  }

  // Default data
  List<HackingTool> _getDefaultTools() {
    return [
      HackingTool(
        id: 'nmap',
        name: 'Nmap',
        description: 'Network exploration tool and security/port scanner',
        category: 'Network Scanning',
        iconName: 'router',
        command: 'nmap',
        parameters: [
          ToolParameter(
            name: 'target',
            label: 'Target IP/Hostname',
            type: 'text',
            required: true,
            placeholder: '192.168.1.1 or example.com',
          ),
          ToolParameter(
            name: 'scan_type',
            label: 'Scan Type',
            type: 'select',
            options: ['-sS', '-sT', '-sU', '-sA', '-sF'],
            defaultValue: '-sS',
          ),
          ToolParameter(
            name: 'ports',
            label: 'Ports',
            type: 'text',
            placeholder: '1-1000 or 80,443,8080',
          ),
        ],
        isInstalled: true,
      ),
      HackingTool(
        id: 'netcat',
        name: 'Netcat',
        description: 'Network utility for reading/writing network connections',
        category: 'Network Tools',
        iconName: 'device_hub',
        command: 'nc',
        parameters: [
          ToolParameter(
            name: 'host',
            label: 'Host',
            type: 'text',
            required: true,
          ),
          ToolParameter(
            name: 'port',
            label: 'Port',
            type: 'number',
            required: true,
          ),
          ToolParameter(name: 'listen', label: 'Listen Mode', type: 'boolean'),
        ],
        isInstalled: true,
      ),
      HackingTool(
        id: 'aircrack',
        name: 'Aircrack-ng',
        description: 'WiFi security auditing tools suite',
        category: 'WiFi Hacking',
        iconName: 'wifi',
        command: 'aircrack-ng',
        requiresRoot: true,
        parameters: [
          ToolParameter(
            name: 'interface',
            label: 'Wireless Interface',
            type: 'text',
            required: true,
            defaultValue: 'wlan0',
          ),
          ToolParameter(
            name: 'mode',
            label: 'Mode',
            type: 'select',
            options: ['monitor', 'managed', 'scan'],
            defaultValue: 'monitor',
          ),
        ],
        isInstalled: false,
      ),
      HackingTool(
        id: 'hydra',
        name: 'Hydra',
        description: 'Password cracking tool for various protocols',
        category: 'Password Attacks',
        iconName: 'lock',
        command: 'hydra',
        parameters: [
          ToolParameter(
            name: 'target',
            label: 'Target',
            type: 'text',
            required: true,
          ),
          ToolParameter(
            name: 'protocol',
            label: 'Protocol',
            type: 'select',
            options: ['ssh', 'ftp', 'telnet', 'http-get', 'http-post', 'mysql'],
            defaultValue: 'ssh',
          ),
          ToolParameter(
            name: 'username',
            label: 'Username',
            type: 'text',
            required: true,
          ),
          ToolParameter(
            name: 'wordlist',
            label: 'Password Wordlist',
            type: 'text',
            placeholder: '/path/to/wordlist.txt',
          ),
        ],
        isInstalled: false,
      ),
      HackingTool(
        id: 'sqlmap',
        name: 'SQLMap',
        description: 'Automatic SQL injection and database takeover tool',
        category: 'Web Application',
        iconName: 'bug_report',
        command: 'sqlmap',
        parameters: [
          ToolParameter(
            name: 'url',
            label: 'Target URL',
            type: 'text',
            required: true,
            placeholder: 'http://example.com/page.php?id=1',
          ),
          ToolParameter(
            name: 'data',
            label: 'POST Data',
            type: 'text',
            placeholder: 'param1=value1&param2=value2',
          ),
          ToolParameter(
            name: 'cookie',
            label: 'Cookie',
            type: 'text',
            placeholder: 'JSESSIONID=abc123',
          ),
        ],
        isInstalled: false,
      ),
      HackingTool(
        id: 'gobuster',
        name: 'Gobuster',
        description: 'Directory/file & DNS busting tool',
        category: 'Web Application',
        iconName: 'folder_open',
        command: 'gobuster',
        parameters: [
          ToolParameter(
            name: 'url',
            label: 'Target URL',
            type: 'text',
            required: true,
            placeholder: 'http://example.com',
          ),
          ToolParameter(
            name: 'wordlist',
            label: 'Wordlist',
            type: 'text',
            required: true,
            placeholder: '/usr/share/wordlists/dirb/common.txt',
          ),
          ToolParameter(
            name: 'extensions',
            label: 'File Extensions',
            type: 'text',
            placeholder: 'php,html,txt',
          ),
        ],
        isInstalled: false,
      ),
    ];
  }

  List<HackingScript> _getDefaultScripts() {
    return [
      HackingScript(
        id: 'quick_network_scan',
        name: 'Escaneo Rápido de Red',
        description: 'Escaneo automático de la red local (auto-detecta tu red)',
        category: 'Network Scanning',
        scriptPath: 'assets/scripts/quick_network_scan.sh',
        author: 'Hackomatic Team',
        createdAt: DateTime.now(),
        parameters: [], // Sin parámetros - todo automático
      ),
      HackingScript(
        id: 'auto_port_scan',
        name: 'Escaneo de Puertos Automático',
        description: 'Escanea puertos comunes en el gateway automáticamente',
        category: 'Network Scanning',
        scriptPath: 'assets/scripts/auto_port_scan.sh',
        author: 'Hackomatic Team',
        createdAt: DateTime.now(),
        parameters: [], // Sin parámetros - auto-detecta gateway
      ),
      HackingScript(
        id: 'wifi_discovery',
        name: 'Descubrimiento WiFi',
        description: 'Escanea redes WiFi disponibles automáticamente',
        category: 'WiFi Hacking',
        scriptPath: 'assets/scripts/wifi_discovery.sh',
        author: 'Hackomatic Team',
        createdAt: DateTime.now(),
        parameters: [], // Auto-detecta interfaz WiFi
      ),
      HackingScript(
        id: 'network_info',
        name: 'Información de Red',
        description: 'Muestra información completa de tu configuración de red',
        category: 'Network Scanning',
        scriptPath: 'assets/scripts/network_info.sh',
        author: 'Hackomatic Team',
        createdAt: DateTime.now(),
        parameters: [], // Todo automático
      ),
      HackingScript(
        id: 'auto_web_scan',
        name: 'Escaneo Web Automático',
        description: 'Escanea el router/gateway en busca de servicios web',
        category: 'Web Application',
        scriptPath: 'assets/scripts/auto_web_scan.sh',
        author: 'Hackomatic Team',
        createdAt: DateTime.now(),
        parameters: [], // Auto-detecta gateway como objetivo
      ),
      HackingScript(
        id: 'device_discovery',
        name: 'Descubrimiento de Dispositivos',
        description: 'Encuentra todos los dispositivos en tu red local',
        category: 'Network Scanning',
        scriptPath: 'assets/scripts/device_discovery.sh',
        author: 'Hackomatic Team',
        createdAt: DateTime.now(),
        parameters: [], // Auto-detecta red
      ),
      // Scripts opcionales con parámetros mínimos
      HackingScript(
        id: 'custom_target_scan',
        name: 'Escaneo de Objetivo Personalizado',
        description: 'Escanea un objetivo específico que tú elijas',
        category: 'Network Scanning',
        scriptPath: 'assets/scripts/custom_target_scan.sh',
        author: 'Hackomatic Team',
        createdAt: DateTime.now(),
        parameters: [
          ScriptParameter(
            name: 'target',
            label: 'IP o Dominio',
            type: 'text',
            required: true,
            defaultValue: '192.168.1.1',
            description: 'IP o dominio a escanear',
          ),
        ],
      ),
    ];
  }
}
