import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../providers/project_provider.dart';

class NotesScreen extends StatefulWidget {
  final int? initialProjectId; // If opened from a specific project

  const NotesScreen({super.key, this.initialProjectId});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialProjectId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<NotesProvider>(context, listen: false)
            .filterByProject(widget.initialProjectId);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    return DateFormat('dd.MM.yyyy HH:mm').format(dt);
  }

  void _openNoteEditor(BuildContext context, [NoteModel? note]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _NoteEditorScreen(
          note: note,
          preselectedProjectId: widget.initialProjectId,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, NoteModel note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить заметку?'),
        content: Text(
          note.title.isNotEmpty
              ? 'Удалить заметку "${note.title}"?'
              : 'Вы действительно хотите удалить эту заметку?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<NotesProvider>(context, listen: false)
                  .deleteNote(note.id);
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projects = Provider.of<ProjectProvider>(context).projects;

    return Consumer<NotesProvider>(
      builder: (context, notesProvider, child) {
        final filteredNotes = notesProvider.filteredNotes;
        final selectedProjId = notesProvider.selectedProjectId;

        return Scaffold(
          appBar: AppBar(
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Поиск по заметкам...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          notesProvider.setSearchQuery('');
                          setState(() {
                            _isSearching = false;
                          });
                        },
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (val) => notesProvider.setSearchQuery(val),
                  )
                : const Text('Заметки'),
            actions: [
              if (!_isSearching)
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Поиск',
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                ),
            ],
          ),
          body: Column(
            children: [
              // Project Filter Chips Row
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    ChoiceChip(
                      label: Text('Все (${notesProvider.notes.length})'),
                      selected: selectedProjId == null,
                      selectedColor: const Color(0xFFFF4081).withOpacity(0.25),
                      side: BorderSide(
                        color: selectedProjId == null
                            ? const Color(0xFFFF4081)
                            : Colors.white12,
                      ),
                      onSelected: (_) => notesProvider.filterByProject(null),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Общие (без проекта)'),
                      selected: selectedProjId == -1,
                      selectedColor: const Color(0xFFFF4081).withOpacity(0.25),
                      side: BorderSide(
                        color: selectedProjId == -1
                            ? const Color(0xFFFF4081)
                            : Colors.white12,
                      ),
                      onSelected: (_) => notesProvider.filterByProject(-1),
                    ),
                    const SizedBox(width: 8),
                    ...projects.map((p) {
                      final isSelected = selectedProjId == p.id;
                      final count = notesProvider.notes
                          .where((n) => n.projectId == p.id)
                          .length;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: const Icon(Icons.assignment_outlined, size: 16),
                          label: Text('${p.name} ($count)'),
                          selected: isSelected,
                          selectedColor: const Color(0xFFFF4081).withOpacity(0.25),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFFFF4081)
                                : Colors.white12,
                          ),
                          onSelected: (_) => notesProvider.filterByProject(p.id),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Notes List / Empty State
              Expanded(
                child: filteredNotes.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.note_alt_outlined,
                                size: 70,
                                color: Colors.white24,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                notesProvider.notes.isEmpty
                                    ? 'У вас пока нет заметок'
                                    : 'Заметки не найдены',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Нажмите кнопку "+", чтобы записать замеры, расчеты или важные детали.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: filteredNotes.length,
                        itemBuilder: (context, index) {
                          final note = filteredNotes[index];
                          final hasTitle = note.title.trim().isNotEmpty;
                          final hasProject = note.projectName != null &&
                              note.projectName!.trim().isNotEmpty;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: hasProject
                                      ? const Color(0xFFFF4081).withOpacity(0.3)
                                      : Colors.white10,
                                ),
                              ),
                              child: InkWell(
                                onTap: () => _openNoteEditor(context, note),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top Header: Title / Project Badge / Actions
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                if (hasTitle)
                                                  Text(
                                                    note.title,
                                                    style: const TextStyle(
                                                      fontSize: 17,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                if (hasProject) ...[
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFFF4081).withOpacity(0.12),
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(
                                                        color: const Color(0xFFFF4081).withOpacity(0.3),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons.assignment_outlined,
                                                          size: 13,
                                                          color: Color(0xFFFF4081),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Flexible(
                                                          child: Text(
                                                            note.projectName!,
                                                            style: const TextStyle(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w600,
                                                              color: Color(0xFFFF4081),
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                            tooltip: 'Удалить заметку',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => _confirmDelete(context, note),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 10),

                                      // Content Snippet
                                      Text(
                                        note.content,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                          height: 1.4,
                                        ),
                                        maxLines: 6,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                      const SizedBox(height: 12),
                                      const Divider(height: 1, color: Colors.white10),
                                      const SizedBox(height: 8),

                                      // Footer: Date
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Обновлено: ${_formatDate(note.updatedAt)}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const Icon(
                                            Icons.edit_note,
                                            size: 18,
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openNoteEditor(context),
            backgroundColor: const Color(0xFFFF4081),
            foregroundColor: Colors.black,
            icon: const Icon(Icons.add),
            label: const Text('Заметка', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }
}

class _NoteEditorScreen extends StatefulWidget {
  final NoteModel? note;
  final int? preselectedProjectId;

  const _NoteEditorScreen({
    this.note,
    this.preselectedProjectId,
  });

  @override
  State<_NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<_NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  int? _selectedProjectId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _selectedProjectId = widget.note?.projectId ?? widget.preselectedProjectId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (content.isEmpty && title.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    String? projectName;
    if (_selectedProjectId != null) {
      final matching = projectProvider.projects
          .where((p) => p.id == _selectedProjectId)
          .toList();
      if (matching.isNotEmpty) {
        projectName = matching.first.name;
      }
    }

    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    if (widget.note != null) {
      notesProvider.updateNote(
        id: widget.note!.id,
        title: title,
        content: content,
        projectId: _selectedProjectId,
        projectName: projectName,
      );
    } else {
      notesProvider.addNote(
        title: title,
        content: content,
        projectId: _selectedProjectId,
        projectName: projectName,
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;
    final projects = Provider.of<ProjectProvider>(context).projects;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Редактировать заметку' : 'Новая заметка'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, size: 28, color: Color(0xFFFF4081)),
            tooltip: 'Сохранить',
            onPressed: () => _save(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Association Selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.assignment_outlined, size: 20, color: Color(0xFFFF4081)),
                  const SizedBox(width: 10),
                  const Text(
                    'Проект:',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: _selectedProjectId,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF252525),
                        hint: const Text('Без проекта (общая заметка)', style: TextStyle(color: Colors.white70)),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text(
                              'Без проекта (общая)',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          ...projects.map((p) => DropdownMenuItem<int?>(
                                value: p.id,
                                child: Text(
                                  p.name,
                                  style: const TextStyle(color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedProjectId = val;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Title Field
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Заголовок (например, Замеры на объекте)',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.title, color: Colors.grey),
              ),
            ),

            const Divider(color: Colors.white12),
            const SizedBox(height: 8),

            // Content Multi-line Area
            TextField(
              controller: _contentController,
              autofocus: !isEditing,
              maxLines: null,
              minLines: 12,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.5),
              decoration: const InputDecoration(
                hintText: 'Введите текст заметки, размеры, список дел или напоминание...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ElevatedButton.icon(
            onPressed: () => _save(context),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Сохранить заметку', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4081),
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
    );
  }
}
