import 'package:flutter/foundation.dart';
import '../models/hacking_script.dart';
import '../services/storage_service.dart';
import '../services/network_detection_service.dart';

class ScriptProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  final NetworkDetectionService _networkService = NetworkDetectionService();
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
    final networkInfo = await _networkService.getAutoScanConfig();
    final parameters = <String, dynamic>{};

    // Auto-fill parameters based on script type and parameter names
    for (final param in script.parameters) {
      switch (param.name.toLowerCase()) {
        case 'target':
        case 'ip':
        case 'host':
          parameters[param.name] = networkInfo['gateway'];
          break;
        case 'network':
        case 'range':
          parameters[param.name] = networkInfo['network_range'];
          break;
        case 'interface':
          if (script.category.toLowerCase().contains('wifi')) {
            parameters[param.name] = networkInfo['wifi_interface'];
          } else {
            parameters[param.name] = networkInfo['active_interface'];
          }
          break;
        case 'channel':
          parameters[param.name] = '6'; // Default WiFi channel
          break;
        case 'url':
          parameters[param.name] = networkInfo['target_url'];
          break;
        case 'wordlist':
          parameters[param.name] = networkInfo['wordlist_path'];
          break;
        case 'scan_type':
          parameters[param.name] = '-sS';
          break;
        case 'port_range':
        case 'ports':
          parameters[param.name] = networkInfo['port_range'];
          break;
        case 'bssid':
          parameters[param.name] = '00:11:22:33:44:55'; // Placeholder
          break;
        default:
          // Use default value if available
          if (param.defaultValue != null) {
            parameters[param.name] = param.defaultValue;
          } else {
            // Intelligent fallback based on network detection
            parameters[param.name] = networkInfo['gateway'];
          }
      }
    }

    return parameters;
  }

  // Método público para refrescar scripts
  Future<void> refreshScripts() async {
    await _loadScripts();
  }
}
