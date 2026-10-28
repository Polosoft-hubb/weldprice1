import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ai_message.dart';
import '../models/project.dart';
import '../models/project_item.dart';
import '../models/material.dart';
import '../services/ai_assistant_service.dart';
import '../utils/search_utils.dart';
import 'project_provider.dart';

class AIAssistantProvider extends ChangeNotifier {
  final AIAssistantService _service = AIAssistantService.instance;

  final List<AIMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _apiKey = '';
  String _selectedModel = AIAssistantService.defaultModel;

  List<AIMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get apiKey => _apiKey;
  String get selectedModel => _selectedModel;
  bool get hasApiKey => _apiKey.trim().isNotEmpty;

  String get selectedModelName {
    final match = AIAssistantService.availableModels.firstWhere(
      (m) => m['id'] == _selectedModel,
      orElse: () => {'name': _selectedModel, 'shortName': _selectedModel},
    );
    return match['shortName'] ?? match['name'] ?? _selectedModel;
  }

  AIAssistantProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _apiKey = await _service.getApiKey();
    _selectedModel = await _service.getSelectedModel();
    notifyListeners();
  }

  Future<void> setApiKey(String key) async {
    _apiKey = key.trim();
    await _service.saveApiKey(_apiKey);
    notifyListeners();
  }

  Future<void> setSelectedModel(String modelId) async {
    _selectedModel = modelId;
    await _service.saveSelectedModel(modelId);
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> sendMessage(
    String userPrompt, {
    ProjectModel? currentProject,
    List<ProjectItemModel>? projectItems,
    List<MaterialModel>? availableMaterials,
  }) async {
    final trimmed = userPrompt.trim();
    if (trimmed.isEmpty || _isLoading) return;

    final userMessage = AIMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: trimmed,
      isUser: true,
    );

    _messages.add(userMessage);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final aiResponse = await _service.sendMessage(
        history: _messages,
        userPrompt: trimmed,
        currentProject: currentProject,
        projectItems: projectItems,
        availableMaterials: availableMaterials,
        modelOverride: _selectedModel,
      );

      _messages.add(aiResponse);
    } catch (e) {
      final errText = e.toString().replaceFirst('Exception: ', '');
      _errorMessage = errText;
      _messages.add(
        AIMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: 'Ошибка при обращении к ИИ: $errText',
          isUser: false,
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a suggested material to the active project estimate
  Future<bool> addSuggestedMaterialToProject({
    required BuildContext context,
    required SuggestedMaterialItem item,
  }) async {
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    final currentProject = projectProvider.selectedProject;
    if (currentProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала выберите проект, чтобы добавить в него материалы')),
      );
      return false;
    }

    final catalog = projectProvider.projectMaterials;

    // Try finding the best matching material in the catalog using intelligent ranking
    final searchMatches = catalog.isNotEmpty
        ? filterAndRankMaterials<MaterialModel>(
            items: catalog,
            query: item.name,
            getName: (m) => m.name,
            getCategory: (m) => m.category,
          )
        : <MaterialModel>[];

    MaterialModel matToAdd;
    if (searchMatches.isNotEmpty) {
      final targetMat = searchMatches.first;
      matToAdd = item.price != null
          ? MaterialModel(
              id: targetMat.id,
              name: targetMat.name,
              url: targetMat.url,
              unit: targetMat.unit,
              price: item.price!,
              category: targetMat.category,
              weight: targetMat.weight,
            )
          : targetMat;
    } else {
      // Consumables, fasteners or custom items not present in the metal catalog
      // Add with their EXACT name, unit, and price (never replace with Armatura!)
      final customId = 'custom_${DateTime.now().millisecondsSinceEpoch}_${item.name.hashCode.abs()}';
      double price = item.price ?? 0.0;
      if (price <= 0.0) {
        final lower = item.name.toLowerCase();
        if (lower.contains('электрод')) {
          price = 450.0;
        } else if (lower.contains('диск')) {
          price = 50.0;
        } else if (lower.contains('грунтовк') || lower.contains('эмал') || lower.contains('краск')) {
          price = 400.0;
        } else if (lower.contains('болт') || lower.contains('анкер') || lower.contains('саморез')) {
          price = 35.0;
        } else if (lower.contains('петл')) {
          price = 250.0;
        }
      }

      matToAdd = MaterialModel(
        id: customId,
        name: item.name,
        url: '',
        unit: item.unit.isNotEmpty ? item.unit : 'шт',
        price: price,
        category: 'Расходные материалы',
        weight: 0.0,
      );
    }

    await projectProvider.addMaterialToProject(matToAdd, item.quantity);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Добавлено в смету: ${matToAdd.name} (${item.quantity} ${matToAdd.unit})'),
          backgroundColor: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    return true;
  }
}
