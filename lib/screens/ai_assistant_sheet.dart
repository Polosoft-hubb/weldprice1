import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/ai_message.dart';
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
      'title': '🏗️ Навес 6х4 м',
      'prompt': 'Рассчитай металл для односкатного навеса 6х4 метра: столбы, фермы, обрешетка с запасом.',
    },
    {
      'title': '🚪 Калитка 1х2 м',
      'prompt': 'Сколько нужно профильной трубы на каркас калитки 1х2 метра и какие петли лучше взять?',
    },
    {
      'title': '🔍 Проверить смету',
      'prompt': 'Проанализируй позиции в моей текущей смете. Все ли учтено, какие расходники нужны дополнительно?',
    },
    {
      'title': '⚖️ Расчет веса',
      'prompt': 'Посчитай общий вес и площадь покраски для добавленных в смету материалов.',
    },
    {
      'title': '📏 Подбор трубы',
      'prompt': 'Какую трубу выбрать на стойки забора высотой 2 метра из профлиста?',
    },
    {
      'title': '📐 Шаг ферм',
      'prompt': 'Какой оптимальный шаг и уклон ферм делать при перекрытии пролета 6 метров?',
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

              // Quick Suggestions Bar (when chat has few messages)
              if (aiProvider.messages.length <= 2 && !aiProvider.isLoading)
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _quickSuggestions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final item = _quickSuggestions[i];
                      return ActionChip(
                        label: Text(
                          item['title']!,
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                        ),
                        backgroundColor: const Color(0xFF222222),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Colors.white12),
                        ),
                        onPressed: () => _sendMessage(item['prompt']!),
                      );
                    },
                  ),
                ),

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
}
