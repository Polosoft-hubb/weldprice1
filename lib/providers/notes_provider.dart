import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../services/database_helper.dart';

class NotesProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<NoteModel> _notes = [];
  int? _selectedProjectId; // null = all, -1 = general (no project), >0 = specific project
  String _searchQuery = '';

  List<NoteModel> get notes => _notes;
  int? get selectedProjectId => _selectedProjectId;
  String get searchQuery => _searchQuery;

  List<NoteModel> get filteredNotes {
    var result = List<NoteModel>.from(_notes);

    if (_selectedProjectId != null) {
      if (_selectedProjectId == -1) {
        result = result.where((n) => n.projectId == null).toList();
      } else {
        result = result.where((n) => n.projectId == _selectedProjectId).toList();
      }
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      result = result.where((n) {
        final title = n.title.toLowerCase();
        final content = n.content.toLowerCase();
        final proj = (n.projectName ?? '').toLowerCase();
        return title.contains(q) || content.contains(q) || proj.contains(q);
      }).toList();
    }

    return result;
  }

  Future<void> loadNotes() async {
    _notes = await _dbHelper.getAllNotes();
    notifyListeners();
  }

  void filterByProject(int? projectId) {
    _selectedProjectId = projectId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> addNote({
    required String title,
    required String content,
    int? projectId,
    String? projectName,
  }) async {
    final now = DateTime.now();
    final newNote = NoteModel(
      id: now.millisecondsSinceEpoch.toString(),
      title: title.trim(),
      content: content.trim(),
      projectId: projectId,
      projectName: projectName,
      createdAt: now,
      updatedAt: now,
    );

    await _dbHelper.saveNote(newNote);
    await loadNotes();
  }

  Future<void> updateNote({
    required String id,
    required String title,
    required String content,
    int? projectId,
    String? projectName,
  }) async {
    final index = _notes.indexWhere((n) => n.id == id);
    final now = DateTime.now();
    final createdAt = index != -1 ? _notes[index].createdAt : now;

    final updated = NoteModel(
      id: id,
      title: title.trim(),
      content: content.trim(),
      projectId: projectId,
      projectName: projectName,
      createdAt: createdAt,
      updatedAt: now,
    );

    await _dbHelper.saveNote(updated);
    await loadNotes();
  }

  Future<void> deleteNote(String id) async {
    await _dbHelper.deleteNote(id);
    await loadNotes();
  }
}
