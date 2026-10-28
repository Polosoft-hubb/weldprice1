import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/ai_message.dart';
import '../models/project.dart';
import '../providers/ai_assistant_provider.dart';
import '../providers/project_provider.dart';
import '../services/ai_assistant_service.dart';

class AIAssistantSheet extends StatefulWidget {
  const AIAssistantSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AIAssistantSheet(),
    );
  }

  @override
  State<AIAssistantSheet> createState() => _AIAssistantSheetState();
}

class _AIAssistantSheetState extends State<AIAssistantSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<Map<String, String>> _quickSuggestions = const [
    {
      'title': '🏗️ Навес 6х4 м: стойки, фермы, обрешетка',
      'prompt': 'Рассчитай металл для односкатного навеса 6х4 метра: столбы, фермы, обрешетка с запасом на раскрой.',
    },
    {
      'title': '🚪 Каркас калитки 1х2 м и распашные ворота',
      'prompt': 'Сколько нужно профильной трубы на каркас калитки 1х2 метра и какие петли и замок лучше взять?',
    },
    {
      'title': '📏 Подбор трубы на забор из профнастила',
      'prompt': 'Какую трубу выбрать на стойки и лаги забора высотой 2 метра из профлиста, и какой шаг столбов делать?',
    },
    {
      'title': '📐 Расчет шага и сечений стропильных ферм',
      'prompt': 'Какой оптимальный шаг и уклон ферм делать при перекрытии пролета 6 метров из профильной трубы?',
    },
    {
      'title': '⚡ Расход электродов и сварочной смеси',
      'prompt': 'Сколько электродов (кг) и отрезных дисков требуется на 1 тонну типовых легких металлоконструкций?',
    },
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final aiProvider = Provider.of<AIAssistantProvider>(context, listen: false);
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);

    _textController.clear();
    aiProvider.sendMessage(
      trimmed,
      currentProject: projectProvider.selectedProject,
      projectItems: projectProvider.selectedProject?.items,
      availableMaterials: projectProvider.projectMaterials,
    );

    _scrollToBottom();
  }

  void _showModelSelectionDialog(BuildContext context) {
    final aiProvider = Provider.of<AIAssistantProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Row(
          children: [
            Icon(Icons.tune, color: Color(0xFFFF4081)),
            SizedBox(width: 8),
            Text('Выбор модели ИИ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: AIAssistantService.availableModels.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white12),
            itemBuilder: (ctx, i) {
              final model = AIAssistantService.availableModels[i];
              final isSelected = model['id'] == aiProvider.selectedModel;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        model['name']!,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFFFF4081) : Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle, color: Color(0xFFFF4081), size: 18),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    model['desc']!,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ),
                onTap: () {
                  aiProvider.setSelectedModel(model['id']!);
                  Navigator.of(dlgCtx).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlgCtx).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;

    return Consumer2<AIAssistantProvider, ProjectProvider>(
      builder: (context, aiProvider, projectProvider, _) {
        final currentProject = projectProvider.selectedProject;
        final selectedModelInfo = AIAssistantService.availableModels.firstWhere(
          (m) => m['id'] == aiProvider.selectedModel,
          orElse: () => {
            'id': aiProvider.selectedModel,
            'name': aiProvider.selectedModel,
            'shortName': aiProvider.selectedModel,
            'desc': '',
          },
        );

        return Container(
          height: screenHeight * 0.90,
          margin: EdgeInsets.only(bottom: bottomInset),
          decoration: const BoxDecoration(
            color: Color(0xFF141414),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              // Top drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4081).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFFFF4081),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'WELDPRICE AI',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          InkWell(
                            onTap: () => _showModelSelectionDialog(context),
                            borderRadius: BorderRadius.circular(4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  selectedModelInfo['shortName'] ?? aiProvider.selectedModel,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFFF4081),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, color: Color(0xFFFF4081), size: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Actions: Clear Chat & Close
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white70, size: 22),
                      tooltip: 'Очистить историю',
                      onPressed: () {
                        aiProvider.clearChat();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 22),
                      tooltip: 'Закрыть',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Active Project Context Banner (if project selected)
              if (currentProject != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.folder_outlined, size: 16, color: Color(0xFFFF4081)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Проект: ${currentProject.name} (${currentProject.items.length} позиций)',
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              const Divider(color: Colors.white12, height: 1),

              // Chat Messages List
              Expanded(
                child: aiProvider.messages.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: aiProvider.messages.length + (aiProvider.isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == aiProvider.messages.length) {
                            return _buildLoadingBubble();
                          }
                          final msg = aiProvider.messages[index];
                          return _buildMessageBubble(context, msg);
                        },
                      ),
              ),

              // Quick Action Buttons Bar (Project & Workshop actions)
              _buildQuickActionButtons(context, projectProvider, aiProvider),

              const SizedBox(height: 8),

              // Input bar
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E1E),
                  border: Border(top: BorderSide(color: Colors.white10)),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          maxLines: 4,
                          minLines: 1,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) {
                            _sendMessage(_textController.text);
                            _focusNode.requestFocus();
                          },
                          decoration: InputDecoration(
                            hintText: 'Задайте вопрос по смете или металлу...',
                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                            filled: true,
                            fillColor: const Color(0xFF141414),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: Colors.white12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: Colors.white12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: Color(0xFFFF4081)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4081),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                        ),
                        icon: aiProvider.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 20),
                        onPressed: aiProvider.isLoading
                            ? null
                            : () => _sendMessage(_textController.text),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF4081).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 40,
              color: Color(0xFFFF4081),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Инженерный ИИ-Сметчик',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Помогу рассчитать металлоконструкцию, подобрать профильные трубы, рассчитать вес и найти ошибки в смете.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Примеры запросов:',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ..._quickSuggestions.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  side: const BorderSide(color: Colors.white12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: const Color(0xFF1A1A1A),
                ),
                onPressed: () => _sendMessage(item['prompt']!),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['title']!,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white38),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, AIMessage msg) {
    final isUser = msg.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.88,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFFFF4081).withOpacity(0.2) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
          border: Border.all(
            color: isUser ? const Color(0xFFFF4081).withOpacity(0.4) : Colors.white12,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with role and copy button
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUser ? Icons.person : Icons.auto_awesome,
                  size: 14,
                  color: isUser ? const Color(0xFFFF4081) : const Color(0xFFFF4081),
                ),
                const SizedBox(width: 6),
                Text(
                  isUser ? 'Вы' : 'WELDPRICE AI',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white60,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: msg.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Текст скопирован'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.copy, size: 14, color: Colors.white38),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Text Body
            MarkdownBody(
              data: msg.text,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                code: const TextStyle(
                  backgroundColor: Color(0xFF121212),
                  color: Color(0xFFFF80AB),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
                codeblockDecoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                tableBorder: TableBorder.all(color: Colors.white24, width: 1),
                tableHead: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                tableBody: const TextStyle(color: Colors.white70),
                listBullet: const TextStyle(color: Color(0xFFFF4081)),
              ),
            ),

            // Suggested Materials Interactive Cards
            if (msg.suggestedMaterials.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(color: Colors.white12),
              const SizedBox(height: 6),
              const Row(
                children: [
                  Icon(Icons.playlist_add_check, color: Color(0xFFFF4081), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Рекомендуемые позиции для сметы:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...msg.suggestedMaterials.map((mat) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181818),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mat.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              mat.price != null && mat.price! > 0
                                  ? 'Количество: ${mat.quantity} ${mat.unit} • ${mat.price!.toStringAsFixed(0)} ₽'
                                  : 'Количество: ${mat.quantity} ${mat.unit}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('В смету', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4081),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          final aiProvider = Provider.of<AIAssistantProvider>(context, listen: false);
                          aiProvider.addSuggestedMaterialToProject(
                            context: context,
                            item: mat,
                          );
                        },
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 8, right: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFFF4081),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'WELDPRICE AI считает...',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButtons(
    BuildContext context,
    ProjectProvider projectProvider,
    AIAssistantProvider aiProvider,
  ) {
    if (aiProvider.isLoading) return const SizedBox.shrink();

    final currentProject = projectProvider.selectedProject;
    final projects = projectProvider.projects;

    final actions = <_ActionItem>[];

    // 1. Смета проекта
    if (currentProject != null) {
      actions.add(
        _ActionItem(
          icon: Icons.receipt_long_rounded,
          label: 'Смета',
          badge: '${currentProject.items.length}',
          color: const Color(0xFFFF4081),
          onTap: () {
            final itemsDesc = currentProject.items.isNotEmpty
                ? currentProject.items
                    .map((it) => '• ${it.name} — ${it.quantity} ${it.unit} (${it.price.toStringAsFixed(0)} ₽, вес: ${it.totalWeight.toStringAsFixed(1)} кг)')
                    .join('\n')
                : 'В смете пока нет добавленных позиций.';
            final prompt =
                'Проанализируй смету проекта "${currentProject.name}":\n'
                '- Позиций: ${currentProject.items.length}\n'
                '- Стоимость материалов: ${currentProject.materialsCost.toStringAsFixed(0)} ₽\n'
                '- Работы: ${currentProject.workCost.toStringAsFixed(0)} ₽\n'
                '- Расходники (5%): ${currentProject.consumablesCost.toStringAsFixed(0)} ₽\n'
                '${currentProject.isPaintingEnabled ? "- Покраска: ${currentProject.totalPaintingCost.toStringAsFixed(0)} ₽\n" : ""}'
                '- Итого клиенту: ${currentProject.totalPrice.toStringAsFixed(0)} ₽\n'
                '- Общий расчетный вес: ${currentProject.totalWeight.toStringAsFixed(1)} кг\n\n'
                'Состав сметы:\n$itemsDesc\n\n'
                'Дай профессиональную оценку: всё ли учтено, нет ли ошибок в расчетах и какие позиции или работы нужно предусмотреть?';
            _sendMessage(prompt);
          },
        ),
      );
    } else {
      actions.add(
        _ActionItem(
          icon: Icons.receipt_long_rounded,
          label: 'Смета',
          color: const Color(0xFFFF4081),
          onTap: () {
            _sendMessage('Как правильно составить смету на металлоконструкцию: структура затрат, коэффициенты на работу и непредвиденные расходы?');
          },
        ),
      );
    }

    // 2. Материалы
    if (currentProject != null) {
      actions.add(
        _ActionItem(
          icon: Icons.inventory_2_outlined,
          label: 'Материалы',
          badge: '${currentProject.items.length}',
          color: const Color(0xFF29B6F6),
          onTap: () {
            final itemsList = currentProject.items.isNotEmpty
                ? currentProject.items
                    .map((it) => '- ${it.name}: ${it.quantity} ${it.unit} (${it.totalWeight.toStringAsFixed(1)} кг)')
                    .join('\n')
                : 'Список пуст.';
            final prompt =
                'Составь подробную ведомость материалов для закупки по проекту "${currentProject.name}":\n'
                'Текущие позиции:\n$itemsList\n'
                'Общий вес металлопроката: ${currentProject.totalWeight.toStringAsFixed(1)} кг.\n\n'
                'Укажи запас на рез (5-7%), стандартную длину хлыстов для заказа (обычно 6 м) и проверь правильность подбора сечений.';
            _sendMessage(prompt);
          },
        ),
      );
    } else {
      actions.add(
        _ActionItem(
          icon: Icons.inventory_2_outlined,
          label: 'Материалы',
          color: const Color(0xFF29B6F6),
          onTap: () {
            _sendMessage('Какие основные профильные трубы и металлопрокат используются в строительстве и навесах, и как рассчитывать запас на раскрой?');
          },
        ),
      );
    }

    // 3. Покраска и вес
    if (currentProject != null) {
      actions.add(
        _ActionItem(
          icon: Icons.format_paint_outlined,
          label: 'Покраска и вес',
          color: const Color(0xFFFFA726),
          onTap: () {
            final prompt =
                'Рассчитай покраску и вес для проекта "${currentProject.name}":\n'
                '- Общий вес металла: ${currentProject.totalWeight.toStringAsFixed(1)} кг\n'
                '- Общая площадь покраски: ${currentProject.totalPaintingArea.toStringAsFixed(1)} м²\n'
                '- Расход краски: ${currentProject.paintConsumption} кг/м²\n'
                '- Нужно банок краски: ${currentProject.cansNeeded} (по ${currentProject.paintCanWeight} кг)\n'
                '- Стоимость покрасочных материалов: ${currentProject.totalPaintingCost.toStringAsFixed(0)} ₽\n\n'
                'Порекомендуй оптимальную грунт-эмаль (например 3-в-1 или раздельно грунт ГФ-021 + эмаль), растворитель и технологию подготовки (обезжиривание, зачистка швов).';
            _sendMessage(prompt);
          },
        ),
      );
    } else {
      actions.add(
        _ActionItem(
          icon: Icons.format_paint_outlined,
          label: 'Покраска и вес',
          color: const Color(0xFFFFA726),
          onTap: () {
            _sendMessage('Как быстро рассчитать площадь окрашиваемой поверхности металлопроката и расход грунтовки и эмали на 1 м²?');
          },
        ),
      );
    }

    // 4. Статистика проекта
    if (currentProject != null) {
      actions.add(
        _ActionItem(
          icon: Icons.analytics_outlined,
          label: 'Статистика проекта',
          color: const Color(0xFF66BB6A),
          onTap: () {
            final pricePerKg = currentProject.totalWeight > 0
                ? (currentProject.totalPrice / currentProject.totalWeight).toStringAsFixed(0)
                : '0';
            final prompt =
                'Дай экономическую и техническую оценку проекта "${currentProject.name}":\n'
                '- Статус: ${ProjectStatus.getLabel(currentProject.status)}\n'
                '- Стоимость материалов: ${currentProject.materialsCost.toStringAsFixed(0)} ₽\n'
                '- Стоимость работ: ${currentProject.workCost.toStringAsFixed(0)} ₽ (коэфф. сложности ${currentProject.complexity})\n'
                '- Расходники (5%): ${currentProject.consumablesCost.toStringAsFixed(0)} ₽\n'
                '- Итого клиенту: ${currentProject.totalPrice.toStringAsFixed(0)} ₽\n'
                '- Общий вес: ${currentProject.totalWeight.toStringAsFixed(1)} кг\n'
                '- Цена за 1 кг готового изделия: $pricePerKg ₽/кг\n\n'
                'Оцени адекватность расценки за работу, маржинальность и подскажи, как обосновать смету заказчику.';
            _sendMessage(prompt);
          },
        ),
      );
    }

    // 5. Общая статистика цеха (из главного меню!)
    actions.add(
      _ActionItem(
        icon: Icons.query_stats_rounded,
        label: 'Статистика цеха',
        badge: '${projects.length}',
        color: const Color(0xFFAB47BC),
        onTap: () {
          final completed = projects.where((p) => p.status == ProjectStatus.completed).toList();
          final inProgress = projects.where((p) => p.status == ProjectStatus.inProgress).toList();
          final rejected = projects.where((p) => p.status == ProjectStatus.rejected).toList();
          final completedRevenue = completed.fold(0.0, (sum, p) => sum + p.totalPrice);
          final completedProfit = completed.fold(0.0, (sum, p) => sum + p.workCost);
          final inProgressRevenue = inProgress.fold(0.0, (sum, p) => sum + p.totalPrice);
          final avgCheck = completed.isNotEmpty ? completedRevenue / completed.length : 0.0;

          final prompt =
              'Сделай анализ общей статистики сварочного цеха по всем проектам:\n'
              '- Всего проектов в базе: ${projects.length}\n'
              '- Завершено заказов: ${completed.length} (общая выручка: ${completedRevenue.toStringAsFixed(0)} ₽, чистая оплата работ: ${completedProfit.toStringAsFixed(0)} ₽)\n'
              '- Проектов в работе: ${inProgress.length} (на сумму: ${inProgressRevenue.toStringAsFixed(0)} ₽)\n'
              '- Отклонено / отказов: ${rejected.length}\n'
              '- Средний чек выполненного заказа: ${avgCheck.toStringAsFixed(0)} ₽\n\n'
              'Дай аналитический отчет: оценку эффективности цеха, конверсию сделок и 3-4 практических совета по повышению прибыли и сокращению издержек.';
          _sendMessage(prompt);
        },
      ),
    );

    // 6. Расходники и метизы
    actions.add(
      _ActionItem(
        icon: Icons.build_outlined,
        label: 'Расходники',
        color: const Color(0xFF26A69A),
        onTap: () {
          if (currentProject != null) {
            final prompt =
                'Рассчитай и предложи конкретный список расходных материалов для проекта "${currentProject.name}" (вес металла: ${currentProject.totalWeight.toStringAsFixed(1)} кг):\n'
                '- Сварочные электроды или проволока для полуавтомата\n'
                '- Отрезные и зачистные диски 125 мм\n'
                '- Заглушки пластиковые для профильных труб\n'
                '- Крепеж (анкеры, кровельные саморезы, болты)\n\n'
                'Обязательно добавь блок weldprice_materials с ценами, чтобы я мог добавить их в смету в 1 клик!';
            _sendMessage(prompt);
          } else {
            _sendMessage('Какие расходные материалы (электроды, круги, перчатки, герметик, крепеж) и в каком количестве обычно закладываются на типовой металлокаркас? Добавь блок weldprice_materials.');
          }
        },
      ),
    );

    // 7. Раскрой 6м
    actions.add(
      _ActionItem(
        icon: Icons.content_cut_rounded,
        label: 'Раскрой 6м',
        color: const Color(0xFFFF7043),
        onTap: () {
          if (currentProject != null) {
            _sendMessage('Помоги с раскроем проката для проекта "${currentProject.name}". Как с минимальным остатком порезать профильные трубы из стандартных хлыстов 6 м, учитывая толщину реза диска 2-3 мм?');
          } else {
            _sendMessage('Как правильно составить карту раскроя профильных труб из хлыстов 6 метров, чтобы минимизировать деловой остаток и отходы?');
          }
        },
      ),
    );

    return Container(
      height: 42,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final a = actions[i];
          return InkWell(
            onTap: a.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: a.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: a.color.withOpacity(0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(a.icon, size: 16, color: a.color),
                  const SizedBox(width: 6),
                  Text(
                    a.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: a.color.withOpacity(0.95),
                    ),
                  ),
                  if (a.badge != null) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: a.color.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        a.badge!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: a.color,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final String? badge;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    this.badge,
    required this.color,
    required this.onTap,
  });
}
