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
        persona: 'Ты — передовая языковая модель Gemini 4 Argon от Google.',
        currentProject: project,
        projectItems: items,
      );

      expect(prompt, contains('Навес для авто'));
      expect(prompt, contains('Труба профильная 40х40х2 мм'));
      expect(prompt, contains('weldprice_materials'));
      expect(prompt, contains('WELDPRICE AI'));
      expect(prompt, contains('Gemini 4 Argon'));
    });

    test('availableModels contains the user requested models from Start_Antigravity_UI.bat', () {
      final modelIds = AIAssistantService.availableModels.map((m) => m['id']).toList();
      expect(modelIds, contains('gemini-4-argon'));
      expect(modelIds, contains('deepseek-r1-671b'));
      expect(modelIds, contains('claude-sonnet-5-5'));
    });
  });
}
