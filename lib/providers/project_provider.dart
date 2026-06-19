import 'package:flutter/foundation.dart';
import '../models/material.dart';
import '../models/project.dart';
import '../models/project_item.dart';
import '../models/part_item.dart';
import '../services/database_helper.dart';
import '../services/scraper_service.dart';

class ProjectProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ScraperService _scraperService = ScraperService.instance;

  List<ProjectModel> _projects = [];
  List<MaterialModel> _projectMaterials = []; // Project-specific materials
  List<MaterialModel> _searchResults = [];
  List<PartItem> _projectParts = [];
  ProjectModel? _selectedProject;
  
  DateTime? _lastUpdateDate;
  bool _isScraping = false;
  String? _scrapingError;

  // Getters
  List<ProjectModel> get projects => _projects;
  List<MaterialModel> get projectMaterials => _projectMaterials;
  List<MaterialModel> get searchResults => _searchResults;
  List<PartItem> get projectParts => _projectParts;
  ProjectModel? get selectedProject => _selectedProject;
  DateTime? get lastUpdateDate => _lastUpdateDate;
  bool get isScraping => _isScraping;
  String? get scrapingError => _scrapingError;

  // Initial loading
  Future<void> initializeApp() async {
    await loadProjects();
    await loadLastUpdateDate();
  }

  Future<void> loadProjects() async {
    _projects = await _dbHelper.getAllProjects();
    if (_selectedProject != null) {
      final updated = _projects.firstWhere(
        (p) => (p.id as num).toInt() == (_selectedProject!.id as num).toInt(),
        orElse: () => _selectedProject!,
      );
      _selectedProject = updated;
    }
    notifyListeners();
  }

  Future<void> loadProjectMaterials(int projectId) async {
    _projectMaterials = await _dbHelper.getProjectMaterials(projectId);
    _searchResults = List.from(_projectMaterials);
    notifyListeners();
  }

  Future<void> loadLastUpdateDate() async {
    _lastUpdateDate = await _scraperService.getLastUpdateDate();
    notifyListeners();
  }

  // Search materials
  void filterMaterials(String query, {String category = 'Все'}) {
    List<MaterialModel> temp = List.from(_projectMaterials);
    
    // Apply category filter if it is not 'Все'
    if (category != 'Все') {
      temp = temp.where((m) => m.category == category).toList();
    }
    
    // Apply search query filter if it is not empty
    if (query.isNotEmpty) {
      // Split the search query into lowercase non-empty words/tokens
      final tokens = query
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((token) => token.isNotEmpty)
          .toList();

      if (tokens.isNotEmpty) {
        temp = temp.where((m) {
          final nameLower = m.name.toLowerCase();
          final categoryLower = m.category.toLowerCase();
          
          // Verify that EVERY token matches either the name or the category
          return tokens.every((token) =>
              nameLower.contains(token) || categoryLower.contains(token));
        }).toList();
      }
    }
    
    _searchResults = temp;
    notifyListeners();
  }

  // Selection
  Future<void> selectProject(int projectId) async {
    final project = await _dbHelper.getProjectById(projectId);
    _selectedProject = project;
    await loadProjectMaterials(projectId);
    await loadProjectParts(projectId);
    notifyListeners();
  }

  void deselectProject() {
    _selectedProject = null;
    _projectMaterials = [];
    _searchResults = [];
    _projectParts = [];
    notifyListeners();
  }

  // CRUD Projects
  Future<void> createProject(String name) async {
    final newProj = ProjectModel(
      name: name,
      createdAt: DateTime.now(),
      complexity: 2.5,
      items: const [],
    );
    final created = await _dbHelper.createProject(newProj);
    
    await loadProjects();
    
    if (created.id != null) {
      final newId = (created.id as num).toInt();
      await selectProject(newId);
      // Run automatic background sync for this specific project
      _runAutomaticWebSync(newId);
    }
  }

  Future<void> deleteProject(int projectId) async {
    await _dbHelper.deleteProject(projectId);
    if (_selectedProject?.id == projectId) {
      _selectedProject = null;
    }
    await loadProjects();
  }

  Future<void> updateComplexity(double complexity) async {
    if (_selectedProject == null || _selectedProject!.id == null) return;
    final projectId = (_selectedProject!.id as num).toInt();
    await _dbHelper.updateProjectComplexity(projectId, complexity);
    
    await loadProjects();
    await selectProject(projectId);
  }

  // CRUD Project Items (Specification)
  Future<void> addMaterialToProject(MaterialModel material, double quantity) async {
    if (_selectedProject == null || _selectedProject!.id == null) return;
    final projectId = (_selectedProject!.id as num).toInt();

    final item = ProjectItemModel(
      projectId: projectId,
      materialId: material.id,
      name: material.name,
      quantity: quantity,
      unit: material.unit,
      price: material.price,
      paintingArea: ProjectItemModel.estimateAreaFromName(material.name, material.unit),
    );

    await _dbHelper.addProjectItem(item);
    
    await loadProjects();
    await selectProject(projectId);
  }

  Future<void> updateItemQuantity(int itemId, double quantity) async {
    if (_selectedProject == null || _selectedProject!.id == null) return;
    final projectId = (_selectedProject!.id as num).toInt();
    
    await _dbHelper.updateProjectItemQuantity(itemId, quantity);
    
    await loadProjects();
    await selectProject(projectId);
  }

  Future<void> updateItemPaintingArea(int itemId, double area) async {
    if (_selectedProject == null || _selectedProject!.id == null) return;
    final projectId = (_selectedProject!.id as num).toInt();
    
    await _dbHelper.updateProjectItemPaintingArea(itemId, area);
    
    await loadProjects();
    await selectProject(projectId);
  }

  Future<void> updatePaintingSettings({
    bool? enabled,
    double? price,
    double? consumption,
    double? workPrice,
    double? canWeight,
  }) async {
    if (_selectedProject == null || _selectedProject!.id == null) return;
    final projectId = (_selectedProject!.id as num).toInt();

    final currentEnabled = enabled ?? _selectedProject!.isPaintingEnabled;
    final currentPrice = price ?? _selectedProject!.paintPrice;
    final currentConsumption = consumption ?? _selectedProject!.paintConsumption;
    final currentWorkPrice = workPrice ?? _selectedProject!.paintingWorkPrice;
    final currentCanWeight = canWeight ?? _selectedProject!.paintCanWeight;

    await _dbHelper.updateProjectPaintingSettings(
      projectId,
      enabled: currentEnabled,
      price: currentPrice,
      consumption: currentConsumption,
      workPrice: currentWorkPrice,
      canWeight: currentCanWeight,
    );

    await loadProjects();
    await selectProject(projectId);
  }

  Future<void> removeItemFromProject(int itemId) async {
    if (_selectedProject == null || _selectedProject!.id == null) return;
    final projectId = (_selectedProject!.id as num).toInt();

    await _dbHelper.deleteProjectItem(itemId);
    
    await loadProjects();
    await selectProject(projectId);
  }

  // Web Scraping / Synchronization (Project Specific)
  Future<void> syncPrices() async {
    if (_selectedProject == null || _selectedProject!.id == null) return;
    final projectId = (_selectedProject!.id as num).toInt();

    _isScraping = true;
    _scrapingError = null;
    notifyListeners();

    try {
      // 1. Scrape newest template prices
      await _scraperService.scrapeAndUpdatePrices();
      final updatedTemplates = await _dbHelper.getAllMaterials();
      
      // 2. Batch update this specific project's materials list
      await _dbHelper.updateProjectMaterialsBatch(projectId, updatedTemplates);
      
      // 3. Reload databases and view
      await loadProjectMaterials(projectId);
      await loadProjects();
      await selectProject(projectId);
      await loadLastUpdateDate();
      
      _isScraping = false;
      notifyListeners();
    } catch (e) {
      _isScraping = false;
      _scrapingError = "Не удалось автоматически обновить цены. Возможно CORS блокировка в браузере или отсутствует подключение к интернету.";
      notifyListeners();
    }
  }

  Future<void> _runAutomaticWebSync(int projectId) async {
    try {
      await _scraperService.scrapeAndUpdatePrices();
      final updatedTemplates = await _dbHelper.getAllMaterials();
      
      await _dbHelper.updateProjectMaterialsBatch(projectId, updatedTemplates);
      
      if (_selectedProject != null && (_selectedProject!.id as num).toInt() == projectId) {
        await loadProjectMaterials(projectId);
        await loadProjects();
        await selectProject(projectId);
        await loadLastUpdateDate();
      }
    } catch (e) {
      print("Automatic web sync failed: $e. Using current database prices.");
    }
  }

  // Edit Project Material Manually
  Future<void> updateMaterialPrice(String materialId, double newPrice) async {
    if (_selectedProject == null || _selectedProject!.id == null) return;
    final projectId = (_selectedProject!.id as num).toInt();

    await _dbHelper.updateProjectMaterialPrice(projectId, materialId, newPrice);
    
    // Reload local list and project items
    await loadProjectMaterials(projectId);
    await loadProjects();
    await selectProject(projectId);
  }

  Future<void> addCustomMaterial(String name, String category, String unit, double price) async {
    if (_selectedProject == null || _selectedProject!.id == null) return;
    final projectId = (_selectedProject!.id as num).toInt();

    final customMat = MaterialModel(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      url: '',
      unit: unit,
      price: price,
      category: category,
    );

    await _dbHelper.addGlobalMaterial(customMat);
    await _dbHelper.addProjectMaterial(projectId, customMat);
    
    // Reload local list and project
    await loadProjectMaterials(projectId);
    await loadProjects();
    await selectProject(projectId);
  }

  // --- Project Parts Management ---
  Future<void> loadProjectParts(int projectId) async {
    _projectParts = await _dbHelper.getProjectParts(projectId);
    notifyListeners();
  }

  Future<void> addProjectPart(PartItem part) async {
    if (_selectedProject == null || _selectedProject!.id == null) return;
    final projectId = (_selectedProject!.id as num).toInt();
    _projectParts.add(part);
    await _dbHelper.saveProjectParts(projectId, _projectParts);
    notifyListeners();
  }

  Future<void> updateProjectPart(PartItem part) async {
    if (_selectedProject == null || _selectedProject!.id == null) return;
    final projectId = (_selectedProject!.id as num).toInt();
    final index = _projectParts.indexWhere((p) => p.id == part.id);
    if (index != -1) {
      _projectParts[index] = part;
      await _dbHelper.saveProjectParts(projectId, _projectParts);
      notifyListeners();
    }
  }

  Future<void> deleteProjectPart(String partId) async {
    if (_selectedProject == null || _selectedProject!.id == null) return;
    final projectId = (_selectedProject!.id as num).toInt();
    _projectParts.removeWhere((p) => p.id == partId);
    await _dbHelper.saveProjectParts(projectId, _projectParts);
    notifyListeners();
  }
}
