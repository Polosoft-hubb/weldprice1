import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
      'prompt': 'Рассчитай материал для односкатного навеса 6х4 метра: столбы, фермы, обрешетка под профнастил.',
    },
    {
      'title': '🚪 Ворота 3х2 м',
      'prompt': 'Составь смету на распашные ворота 3х2 метра с встроенной калиткой из профильной трубы.',
    },
    {
      'title': '🔍 Проверить смету',
      'prompt': 'Внимательно изучи текущие позиции в смете проекта. Найди скрытые ошибки, забытый крепеж, расходники или несоответствия.',
    },
    {
      'title': '📝 Составить КП',
      'prompt': 'Составь красивое коммерческое предложение для заказчика на основе позиций и стоимости текущего проекта.',
    },
    {
      'title': '📐 Подбор трубы',
      'prompt': 'Какое сечение профильной трубы и какую толщину стенки выбрать для столбов забора высотой 2 метра?',
    },
    {
      'title': '⚡ Режимы сварки',
      'prompt': 'Подскажи оптимальный сварочный ток, диаметр электродов и рекомендации по сварке профильной трубы со стенкой 1.5 - 2 мм.',
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

  void _showApiKeyDialog(BuildContext context) {
    final aiProvider = Provider.of<AIAssistantProvider>(context, listen: false);
    final controller = TextEditingController(text: aiProvider.apiKey);
    bool obscure = true;

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Row(
            children: [
              Icon(Icons.key, color: Color(0xFFFF4081)),
              SizedBox(width: 10),
              Text('API ключ OpenRouter'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ключ хранится локально в вашем браузере. Вы можете получить его бесплатно на сайте OpenRouter.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                obscureText: obscure,
                decoration: InputDecoration(
                  hintText: 'sk-or-v1-...',
                  labelText: 'OpenRouter API Key',
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () => setDlgState(() => obscure = !obscure),
                      ),
                      IconButton(
                        icon: const Icon(Icons.paste, color: Colors.grey),
                        tooltip: 'Вставить из буфера',
                        onPressed: () async {
                          final data = await Clipboard.getData('text/plain');
                          if (data?.text != null) {
                            controller.text = data!.text!.trim();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final uri = Uri.parse('https://openrouter.ai/keys');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Row(
                  children: [
                    Icon(Icons.open_in_new, size: 16, color: Color(0xFFFF4081)),
                    SizedBox(width: 6),
                    Text(
                      'Получить бесплатный ключ на openrouter.ai',
                      style: TextStyle(
                        color: Color(0xFFFF4081),
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dlgCtx).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                aiProvider.setApiKey(controller.text);
                Navigator.of(dlgCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ API ключ сохранён')),
                );
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  void _showModelSelectionDialog(BuildContext context) {
    final aiProvider = Provider.of<AIAssistantProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Выбор модели ИИ (OpenRouter)'),
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
                          Row(
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
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E7D32),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'FREE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, color: Color(0xFFFF4081), size: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Key Settings Icon
                    IconButton(
                      icon: Stack(
                        children: [
                          Icon(
                            Icons.key,
                            color: aiProvider.hasApiKey ? Colors.white70 : Colors.amber,
                            size: 22,
                          ),
                          if (!aiProvider.hasApiKey)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.amber,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      tooltip: 'API Ключ OpenRouter',
                      onPressed: () => _showApiKeyDialog(context),
                    ),

                    // Clear Chat Button
                    if (aiProvider.messages.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.white60, size: 22),
                        tooltip: 'Очистить историю чата',
                        onPressed: () => aiProvider.clearChat(),
                      ),

                    // Close Button
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 22),
                      tooltip: 'Закрыть',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Active Project Context Banner
              if (currentProject != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  color: const Color(0xFF1E1E1E),
                  child: Row(
                    children: [
                      const Icon(Icons.folder_outlined, color: Colors.white60, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Проект: "${currentProject.name}" (${currentProject.items.length} поз.)',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              // API Key Warning Banner (if missing)
              if (!aiProvider.hasApiKey)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.amber, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Требуется ключ OpenRouter',
                              style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Бесплатный ключ даёт доступ к Gemma 4, Nemotron и другим моделям.',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        onPressed: () => _showApiKeyDialog(context),
                        child: const Text('Ввести', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

              // Messages List or Suggestions
              Expanded(
                child: aiProvider.messages.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: aiProvider.messages.length + (aiProvider.isLoading ? 1 : 0),
                        itemBuilder: (ctx, index) {
                          if (index == aiProvider.messages.length) {
                            return _buildLoadingBubble();
                          }
                          final msg = aiProvider.messages[index];
                          return _buildMessageBubble(msg, currentProject != null);
                        },
                      ),
              ),

              // Input Bar
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E1E),
                  border: Border(top: BorderSide(color: Colors.white10)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) {
                          _sendMessage(_textController.text);
                          _focusNode.requestFocus();
                        },
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Спросите о расчёте, металле, смете...',
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          filled: true,
                          fillColor: const Color(0xFF262626),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF4081),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: aiProvider.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        tooltip: 'Отправить',
                        onPressed: aiProvider.isLoading
                            ? null
                            : () {
                                _sendMessage(_textController.text);
                                _focusNode.requestFocus();
                              },
                      ),
                    ),
                  ],
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4081).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFFFF4081),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Чем помочь по проекту?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Рассчитаю конструкцию, подберу металл под нагрузки, составлю смету или КП для клиента.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.white60),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Быстрые подсказки:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickSuggestions.map((s) {
              return ActionChip(
                backgroundColor: const Color(0xFF262626),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.white12),
                ),
                label: Text(
                  s['title']!,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                onPressed: () {
                  _sendMessage(s['prompt']!);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(AIMessage msg, bool hasActiveProject) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(top: 8, bottom: 8, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFF4081).withOpacity(0.2),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            border: Border.all(color: const Color(0xFFFF4081).withOpacity(0.4)),
          ),
          child: Text(
            msg.text,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 8, right: 24),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Header with Copy Button
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFFFF4081), size: 16),
                const SizedBox(width: 6),
                const Text(
                  'WELDPRICE AI',
                  style: TextStyle(
                    color: Color(0xFFFF4081),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: msg.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Текст скопирован в буфер')),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.copy, size: 15, color: Colors.white54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Markdown Message Body
            MarkdownBody(
              data: msg.text,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(color: Colors.white, fontSize: 14, height: 1.45),
                h1: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                h2: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                h3: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                em: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                code: const TextStyle(
                  color: Color(0xFFFF80AB),
                  backgroundColor: Color(0xFF141414),
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
                codeblockDecoration: BoxDecoration(
                  color: const Color(0xFF141414),
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
                              'Количество: ${mat.quantity} ${mat.unit}',
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
              'WELDPRICE AI думает...',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
