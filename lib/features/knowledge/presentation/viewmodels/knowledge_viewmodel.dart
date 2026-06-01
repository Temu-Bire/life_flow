import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database_service.dart';
import '../../domain/models/note_model.dart';

final noteListProvider = StateNotifierProvider<KnowledgeViewModel, List<NoteModel>>((ref) {
  return KnowledgeViewModel();
});

class KnowledgeViewModel extends StateNotifier<List<NoteModel>> {
  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  KnowledgeViewModel() : super([]) {
    _loadNotes();
  }

  void _loadNotes() {
    final raw = _db.getAllNotes();
    final notes = raw.map((e) => NoteModel.fromMap(e)).toList();
    notes.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    state = notes;
  }

  Future<void> addNote({
    required String title,
    required String content,
    List<String> tags = const [],
    List<String> linkedNoteIds = const [],
  }) async {
    final newNote = NoteModel(
      id: _uuid.v4(),
      title: title,
      content: content,
      tags: tags,
      linkedNoteIds: linkedNoteIds,
      lastModified: DateTime.now(),
    );

    state = [newNote, ...state];
    await _db.saveNote(newNote.id, newNote.toMap());
  }

  Future<void> updateNote(NoteModel updatedNote) async {
    final note = updatedNote.copyWith(lastModified: DateTime.now());
    state = [
      for (final n in state)
        if (n.id == note.id) note else n
    ];
    await _db.saveNote(note.id, note.toMap());
  }

  Future<void> deleteNote(String id) async {
    // Remove linkages in other notes
    state = state.map((n) {
      if (n.linkedNoteIds.contains(id)) {
        final links = List<String>.from(n.linkedNoteIds)..remove(id);
        return n.copyWith(linkedNoteIds: links);
      }
      return n;
    }).toList();
    
    for (final n in state) {
      await _db.saveNote(n.id, n.toMap());
    }

    state = state.where((note) => note.id != id).toList();
    await _db.deleteNote(id);
  }

  // Automatic Bidirectional Linking parser helper:
  // Parses wiki-links [[Note Title]] and returns corresponding note IDs
  List<String> parseWikiLinks(String content) {
    final RegExp regExp = RegExp(r'\[\[(.*?)\]\]');
    final matches = regExp.allMatches(content);
    final List<String> linkedIds = [];

    for (var match in matches) {
      final title = match.group(1)?.trim();
      if (title != null && title.isNotEmpty) {
        final note = state.firstWhere(
          (n) => n.title.toLowerCase() == title.toLowerCase(),
          orElse: () => NoteModel(id: '', title: '', content: '', lastModified: DateTime.now()),
        );
        if (note.id.isNotEmpty && !linkedIds.contains(note.id)) {
          linkedIds.add(note.id);
        }
      }
    }
    return linkedIds;
  }
}

// Search and tag filter providers
final noteSearchProvider = StateProvider<String>((ref) => '');
final noteTagFilterProvider = StateProvider<String?>((ref) => null);

final filteredNotesProvider = Provider<List<NoteModel>>((ref) {
  final notes = ref.watch(noteListProvider);
  final search = ref.watch(noteSearchProvider);
  final tagFilter = ref.watch(noteTagFilterProvider);

  List<NoteModel> filtered = notes;

  if (tagFilter != null) {
    filtered = filtered.where((n) => n.tags.contains(tagFilter)).toList();
  }

  if (search.isNotEmpty) {
    filtered = filtered.where((n) {
      final titleMatch = n.title.toLowerCase().contains(search.toLowerCase());
      final contentMatch = n.content.toLowerCase().contains(search.toLowerCase());
      return titleMatch || contentMatch;
    }).toList();
  }

  return filtered;
});

final allNoteTagsProvider = Provider<List<String>>((ref) {
  final notes = ref.watch(noteListProvider);
  final Set<String> tags = {};
  for (var note in notes) {
    tags.addAll(note.tags);
  }
  return tags.toList();
});
