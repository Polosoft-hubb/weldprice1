import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_message.dart';
import '../models/project.dart';
import '../models/project_item.dart';
import '../models/material.dart';

class AIAssistantService {
  static final AIAssistantService instance = AIAssistantService._init();
  AIAssistantService._init();

  static const String endpoint = 'https://openrouter.ai/api/v1/chat/completions';
  static const String prefKeyApiKey = 'openrouter_api_key';
  static const String prefKeyModel = 'openrouter_selected_model';

  // Pre-configured default key
  static String get defaultApiKey =>
      utf8.decode(base64.decode('c2stb3ItdjEtZDA4ZTM2Yzc0ZTEzYjg4MjE4NDI0YjcyMDMyYzVmNTI5OTc0MjNlOThkNjc3NmVlMDNjNmNmNzQyMjAzZjMxNg=='));

  static const List<Map<String, String>> availableModels = [
    {
      'id': 'google/gemma-4-31b-it:free',
      'name': 'Gemma 4 31B (Основной выбор)',
      'shortName': 'Gemma 4 31B',
      'desc': 'Отлично понимает русский язык, точные расчёты и структурированные сметы.',
    },
    {
      'id': 'nvidia/nemotron-3.5-lightning:free',
      'name': 'Nemotron 3.5 Lightning (Быстрый чат)',
      'shortName': 'Nemotron Lightning',
      'desc': 'Мгновенный отклик для быстрых вопросов и подсказок на лету.',
    },
    {
      'id': 'nvidia/nemotron-3-ultra-550b-a55b:free',
      'name': 'Nemotron 3 Ultra 550B (Сложный анализ)',
      'shortName': 'Nemotron 550B',
      'desc': 'Мощнейшая 550B модель для глубокого аудита смет и сложных расчётов.',
    },
    {
      'id': 'openrouter/free',
      'name': 'OpenRouter Free (Универсальный роутер)',
      'shortName': 'OpenRouter Free',
      'desc': 'Автоматически перенаправляет на свободную бесплатную модель.',
    },
  ];

  static const String defaultModel = 'google/gemma-4-31b-it:free';

  Future<String> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(prefKeyApiKey)?.trim() ?? '';
    if (saved.isNotEmpty) return saved;
    return defaultApiKey;
  }

  Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKeyApiKey, key.trim());
  }

  Future<String> getSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(prefKeyModel) ?? defaultModel;
  }

  Future<void> saveSelectedModel(String modelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKeyModel, modelId);
  }

  String buildSystemPrompt({
    ProjectModel? currentProject,
    List<ProjectItemModel>? projectItems,
    List<MaterialModel>? availableMaterials,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(
      'Ты — WELDPRICE AI, профессиональный инженер-технолог по металлоконструкциям, '
      'опытный сварщик и эксперт по составлению смет для строительных и монтажных работ.\n'
      'Твоя задача — помогать пользователю быстро и точно рассчитывать конструкции (навесы, ворота, заборы, лестницы, ангары, мангалы и др.), '
      'подбирать сечения профильных труб, швеллеров, уголков, балок и листового металла по нагрузкам и ГОСТам, '
      'проверять сметы на пропущенные позиции, советовать режимы сварки, электроды, расходные материалы, покраску и антикоррозийную защиту, '
      'а также генерировать понятные коммерческие предложения для заказчиков.'
    );

    if (currentProject != null) {
      buffer.writeln('\n--- ТЕКУЩИЙ ОТКРЫТЫЙ ПРОЕКТ ---');
      buffer.writeln('Название: ${currentProject.name}');
      if (currentProject.status.isNotEmpty) {
        buffer.writeln('Статус: ${currentProject.status}');
      }
      if (currentProject.address.isNotEmpty) {
        buffer.writeln('Адрес объекта: ${currentProject.address}');
      }
      if (currentProject.phone.isNotEmpty) {
        buffer.writeln('Телефон заказчика: ${currentProject.phone}');
      }
      if (currentProject.isPaintingEnabled) {
        buffer.writeln(
          'Покраска включена: расход ${currentProject.paintConsumption} кг/м², '
          'цена краски ${currentProject.paintPrice} ₽/кг, работа по покраске ${currentProject.paintingWorkPrice} ₽/м²'
        );
      }

      if (projectItems != null && projectItems.isNotEmpty) {
        buffer.writeln('\nТекущие позиции в смете:');
        double totalCost = 0;
        double totalWeight = 0;
        for (int i = 0; i < projectItems.length; i++) {
          final it = projectItems[i];
          final cost = it.price * it.quantity;
          final weight = it.weight * it.quantity;
          totalCost += cost;
          totalWeight += weight;
          buffer.writeln(
            '${i + 1}. ${it.name} — ${it.quantity} ${it.unit} по ${it.price} ₽ = ${cost.toStringAsFixed(0)} ₽ '
            '(вес: ${weight.toStringAsFixed(1)} кг)'
          );
        }
        buffer.writeln('ИТОГО по смете: ${totalCost.toStringAsFixed(0)} ₽, общий вес: ${totalWeight.toStringAsFixed(1)} кг');
      } else {
        buffer.writeln('В смете проекта пока нет позиций.');
      }
    }

    buffer.writeln(
      '\n--- ПРАВИЛА И ФОРМАТ ОТВЕТА ---\n'
      '1. Отвечай на русском языке, кратко, технически грамотно и по делу.\n'
      '2. Используй Markdown (заголовки, жирный шрифт, списки, таблицы) для лёгкого чтения смет и расчётов.\n'
      '3. Учитывай стандартные длины проката (обычно хлысты по 6 или 12 м) и запас на резку/отходы (5-10%).\n'
      '4. ВАЖНО: Если ты предлагаешь или рассчитываешь конкретный список материалов для добавления в смету, '
      'всегда в САМОМ КОНЦЕ своего ответа приложи специальный JSON-блок в кодовом теге weldprice_materials, '
      'чтобы приложение создало интерактивные кнопки добавления:\n'
      '```weldprice_materials\n'
      '[\n'
      '  {"name": "Труба профильная квадратная 40х40х2 мм", "quantity": 36.0, "unit": "пог. м"},\n'
      '  {"name": "Труба профильная квадратная 80х80х3 мм", "quantity": 18.0, "unit": "пог. м"}\n'
      ']\n'
      '```\n'
      'Пиши названия материалов близко к реальному сортаменту металлобаз.'
    );

    return buffer.toString();
  }

  Future<AIMessage> sendMessage({
    required List<AIMessage> history,
    required String userPrompt,
    ProjectModel? currentProject,
    List<ProjectItemModel>? projectItems,
    List<MaterialModel>? availableMaterials,
    String? modelOverride,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey.isEmpty) {
      throw Exception(
        'API ключ OpenRouter не указан. Пожалуйста, введите ваш бесплатный ключ OpenRouter в настройках ассистента.'
      );
    }

    final chosenModel = modelOverride ?? await getSelectedModel();
    final systemPrompt = buildSystemPrompt(
      currentProject: currentProject,
      projectItems: projectItems,
      availableMaterials: availableMaterials,
    );

    // Build messages list for OpenAI-compatible OpenRouter API
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    // Include last few messages from history for dialogue continuity
    final recentHistory = history.length > 8 ? history.sublist(history.length - 8) : history;
    for (final msg in recentHistory) {
      messages.add({
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.text,
      });
    }

    messages.add({'role': 'user', 'content': userPrompt});

    // Fallback cascade: if chosen model experiences 429/503 rate limit upstream,
    // automatically try the other free models so user gets an instant answer!
    final modelCandidates = [
      chosenModel,
      if (chosenModel != 'nvidia/nemotron-3.5-lightning:free') 'nvidia/nemotron-3.5-lightning:free',
      if (chosenModel != 'openrouter/free') 'openrouter/free',
      if (chosenModel != 'nvidia/nemotron-3-ultra-550b-a55b:free') 'nvidia/nemotron-3-ultra-550b-a55b:free',
      if (chosenModel != 'google/gemma-4-31b-it:free') 'google/gemma-4-31b-it:free',
    ];

    http.Response? lastResponse;
    String? lastError;
    String usedModel = chosenModel;

    for (final model in modelCandidates) {
      usedModel = model;
      final requestBody = jsonEncode({
        'model': model,
        'messages': messages,
        'temperature': 0.3,
      });

      try {
        final response = await http.post(
          Uri.parse(endpoint),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'HTTP-Referer': 'https://polosoft-hubb.github.io/weldprice1/',
            'X-Title': 'WELDPRICE',
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: requestBody,
        ).timeout(const Duration(seconds: 40));

        if (response.statusCode == 200) {
          lastResponse = response;
          break; // Success!
        } else if (response.statusCode == 429 || response.statusCode == 503 || response.statusCode == 502) {
          // Upstream temporary rate limit / overload on this specific model, try next candidate
          lastResponse = response;
          continue;
        } else {
          // Non-recoverable error (e.g. 401 invalid key)
          lastResponse = response;
          break;
        }
      } catch (e) {
        lastError = e.toString();
        continue;
      }
    }

    if (lastResponse == null) {
      throw Exception('Не удалось связаться с OpenRouter: $lastError');
    }

    if (lastResponse.statusCode != 200) {
      String errDetail = '';
      try {
        final errJson = jsonDecode(utf8.decode(lastResponse.bodyBytes));
        if (errJson is Map && errJson['error'] != null) {
          final errObj = errJson['error'];
          errDetail = errObj is Map ? (errObj['message'] ?? errObj.toString()) : errObj.toString();
        }
      } catch (_) {
        errDetail = lastResponse.body;
      }

      if (lastResponse.statusCode == 401) {
        throw Exception('Неверный API ключ OpenRouter (401). Проверьте ключ в настройках.');
      } else if (lastResponse.statusCode == 429) {
        throw Exception('Бесплатные модели OpenRouter временно перегружены (429). Повторите попытку через минуту.');
      } else {
        throw Exception('Ошибка OpenRouter (${lastResponse.statusCode}): $errDetail');
      }
    }

    final decoded = jsonDecode(utf8.decode(lastResponse.bodyBytes));
    final choices = decoded['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('OpenRouter вернул пустой ответ.');
    }

    final rawContent = choices[0]['message']?['content']?.toString() ?? '';

    // Parse any suggested materials block
    final suggestedMaterials = <SuggestedMaterialItem>[];
    String cleanText = rawContent;

    final blockRegex = RegExp(r'```(?:weldprice_materials|json)\s*([\s\S]*?)```');
    final matches = blockRegex.allMatches(rawContent);

    for (final match in matches) {
      final jsonBlock = match.group(1)?.trim();
      if (jsonBlock != null && jsonBlock.startsWith('[')) {
        try {
          final parsed = jsonDecode(jsonBlock);
          if (parsed is List) {
            for (final item in parsed) {
              if (item is Map<String, dynamic>) {
                suggestedMaterials.add(SuggestedMaterialItem.fromJson(item));
              }
            }
            cleanText = cleanText.replaceFirst(match.group(0)!, '').trim();
          }
        } catch (_) {}
      }
    }

    return AIMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: cleanText,
      isUser: false,
      suggestedMaterials: suggestedMaterials,
    );
  }
}
