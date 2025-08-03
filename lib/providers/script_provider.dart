import 'package:flutter/foundation.dart';
import '../models/hacking_script.dart';
import '../services/storage_service.dart';
import '../services/tool_detection_service.dart';

class ScriptProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  final ToolDetectionService _detectionService = ToolDetectionService();
  List<HackingScript> _scripts = [];
  List<HackingScript> _filteredScripts = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';

  List<HackingScript> get scripts => _filteredScripts;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  List<String> get categories {
    final cats = _scripts.map((script) => script.category).toSet().toList();
    cats.insert(0, 'All');
    return cats;
  }

  List<HackingScript> get favoriteScripts {
    return _scripts.where((script) => script.isFavorite).toList();
  }

  ScriptProvider() {
    _loadScripts();
  }

  Future<void> _loadScripts() async {
    _scripts = await _storageService.loadScripts();
    _applyFilters();
    notifyListeners();
  }

  void searchScripts(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredScripts = _scripts.where((script) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          script.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          script.description.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory =
          _selectedCategory == 'All' || script.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> addScript(HackingScript script) async {
    _scripts.add(script);
    await _storageService.saveScripts(_scripts);
    _applyFilters();
    notifyListeners();
  }

  Future<void> removeScript(String scriptId) async {
    _scripts.removeWhere((script) => script.id == scriptId);
    await _storageService.saveScripts(_scripts);
    _applyFilters();
    notifyListeners();
  }

  Future<void> updateScript(HackingScript updatedScript) async {
    final index = _scripts.indexWhere(
      (script) => script.id == updatedScript.id,
    );
    if (index != -1) {
      _scripts[index] = updatedScript;
      await _storageService.saveScripts(_scripts);
      _applyFilters();
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String scriptId) async {
    final index = _scripts.indexWhere((script) => script.id == scriptId);
    if (index != -1) {
      final script = _scripts[index];
      final updatedScript = HackingScript(
        id: script.id,
        name: script.name,
        description: script.description,
        category: script.category,
        scriptPath: script.scriptPath,
        parameters: script.parameters,
        author: script.author,
        createdAt: script.createdAt,
        isFavorite: !script.isFavorite,
      );
      await updateScript(updatedScript);
    }
  }

  HackingScript? getScriptById(String id) {
    try {
      return _scripts.firstWhere((script) => script.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getAutoParameters(HackingScript script) async {
    final networkInfo = await _detectionService.getAutoDetectedNetworkInfo();
    final parameters = <String, dynamic>{};

    // Auto-fill parameters based on script type and parameter names
    for (final param in script.parameters) {
      switch (param.name.toLowerCase()) {
        case 'network':
          parameters[param.name] =
              networkInfo['network_range'] ?? '192.168.1.0/24';
          break;
        case 'target':
          parameters[param.name] = await _detectionService.getRandomTarget();
          break;
        case 'interface':
          if (script.category.toLowerCase().contains('wifi')) {
            parameters[param.name] = networkInfo['wifi_interface'] ?? 'wlan0';
          } else {
            parameters[param.name] =
                networkInfo['ethernet_interface'] ?? 'eth0';
          }
          break;
        case 'channel':
          parameters[param.name] = '6'; // Default WiFi channel
          break;
        case 'url':
          parameters[param.name] =
              'http://${networkInfo['gateway'] ?? '192.168.1.1'}';
          break;
        case 'wordlist':
          parameters[param.name] = '/usr/share/wordlists/dirb/common.txt';
          break;
        case 'scan_type':
          parameters[param.name] = '-sS';
          break;
        case 'port_range':
          parameters[param.name] = '1-1000';
          break;
        case 'bssid':
          parameters[param.name] = '00:11:22:33:44:55'; // Placeholder
          break;
        default:
          // Use default value if available
          if (param.defaultValue != null) {
            parameters[param.name] = param.defaultValue;
          }
      }
    }

    return parameters;
  }
}
