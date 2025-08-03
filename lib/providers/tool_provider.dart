import 'package:flutter/foundation.dart';
import '../models/hacking_tool.dart';
import '../services/storage_service.dart';

class ToolProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  List<HackingTool> _tools = [];
  List<HackingTool> _filteredTools = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';

  List<HackingTool> get tools => _filteredTools;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  List<String> get categories {
    final cats = _tools.map((tool) => tool.category).toSet().toList();
    cats.insert(0, 'All');
    return cats;
  }

  ToolProvider() {
    _loadTools();
  }

  Future<void> _loadTools() async {
    _tools = await _storageService.loadTools();
    _applyFilters();
    notifyListeners();
  }

  void searchTools(String query) {
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
    _filteredTools = _tools.where((tool) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          tool.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tool.description.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory =
          _selectedCategory == 'All' || tool.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> addTool(HackingTool tool) async {
    _tools.add(tool);
    await _storageService.saveTools(_tools);
    _applyFilters();
    notifyListeners();
  }

  Future<void> removeTool(String toolId) async {
    _tools.removeWhere((tool) => tool.id == toolId);
    await _storageService.saveTools(_tools);
    _applyFilters();
    notifyListeners();
  }

  Future<void> updateTool(HackingTool updatedTool) async {
    final index = _tools.indexWhere((tool) => tool.id == updatedTool.id);
    if (index != -1) {
      _tools[index] = updatedTool;
      await _storageService.saveTools(_tools);
      _applyFilters();
      notifyListeners();
    }
  }

  HackingTool? getToolById(String id) {
    try {
      return _tools.firstWhere((tool) => tool.id == id);
    } catch (e) {
      return null;
    }
  }
}
