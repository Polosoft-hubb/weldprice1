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

  List<AIMessage> _messages = [];
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
          text: '⚠️ Ошибка при обращении к ИИ: $errText',
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
        const SnackBar(content: Text('⚠️ Сначала откройте проект, чтобы добавить в него материалы')),
      );
      return false;
    }

    final catalog = projectProvider.projectMaterials;
    if (catalog.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Каталог материалов пуст')),
      );
      return false;
    }

    // Try finding the best matching material in the catalog using intelligent ranking
    final searchMatches = filterAndRankMaterials<MaterialModel>(
      items: catalog,
      query: item.name,
      getName: (m) => m.name,
      getCategory: (m) => m.category,
    );

    MaterialModel targetMat;
    if (searchMatches.isNotEmpty) {
      targetMat = searchMatches.first;
    } else {
      // Fallback: pick first material matching category or first in catalog
      targetMat = catalog.first;
    }

    final matToAdd = item.price != null
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

    await projectProvider.addMaterialToProject(matToAdd, item.quantity);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Добавлено в смету: ${targetMat.name} (${item.quantity} ${item.unit})'),
          backgroundColor: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    return true;
  }
}
