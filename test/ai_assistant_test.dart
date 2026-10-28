import 'package:flutter_test/flutter_test.dart';
import 'package:metall_estimate/services/ai_assistant_service.dart';
import 'package:metall_estimate/models/project.dart';
import 'package:metall_estimate/models/project_item.dart';

void main() {
  group('AIAssistantService', () {
    test('buildSystemPrompt includes project details and items', () {
      final service = AIAssistantService.instance;
      final project = ProjectModel(
        id: 1,
        name: 'Навес для авто',
        createdAt: DateTime.now(),
        status: 'in_progress',
        phone: '+7 999 123-45-67',
        address: 'ул. Ленина 10',
        isPaintingEnabled: true,
        paintPrice: 500,
        paintConsumption: 0.25,
        paintingWorkPrice: 300,
      );

      final items = [
        ProjectItemModel(
          projectId: 1,
          materialId: 'mat-1',
          name: 'Труба профильная 40х40х2 мм',
          quantity: 24,
          unit: 'пог. м',
          price: 150,
          weight: 2.3,
        ),
      ];

      final prompt = service.buildSystemPrompt(
        currentProject: project,
        projectItems: items,
      );

      expect(prompt, contains('Навес для авто'));
      expect(prompt, contains('Труба профильная 40х40х2 мм'));
      expect(prompt, contains('weldprice_materials'));
      expect(prompt, contains('WELDPRICE AI'));
    });

    test('availableModels contains the user requested free models', () {
      final modelIds = AIAssistantService.availableModels.map((m) => m['id']).toList();
      expect(modelIds, contains('google/gemma-4-31b-it:free'));
      expect(modelIds, contains('nvidia/nemotron-3-ultra-550b-a55b:free'));
      expect(modelIds, contains('nvidia/nemotron-3.5-lightning:free'));
      expect(modelIds, contains('openrouter/free'));
    });
  });
}
