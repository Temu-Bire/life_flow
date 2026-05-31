import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database_service.dart';
import '../../domain/models/journal_model.dart';

final journalListProvider = StateNotifierProvider<JournalViewModel, List<JournalModel>>((ref) {
  return JournalViewModel();
});

class JournalViewModel extends StateNotifier<List<JournalModel>> {
  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  // Premium Daily Reflection prompts
  static const List<String> reflectionPrompts = [
    "What made you smile today, and why?",
    "Describe one challenge you overcame today, no matter how small.",
    "Who are you grateful for today, and how have they influenced you?",
    "What is one thing you would change about today if you could re-live it?",
    "What did you discover about yourself today?",
    "What is the single most important task you achieved today?",
    "How did you handle stress or difficult situations today?",
    "List three micro-wins that happened today."
  ];

  JournalViewModel() : super([]) {
    _loadEntries();
  }

  void _loadEntries() {
    final rawEntries = _db.getAllJournalEntries();
    final entries = rawEntries.map((e) => JournalModel.fromMap(e)).toList();
    // Sort descending (newest entries first)
    entries.sort((a, b) => b.date.compareTo(a.date));
    state = entries;
  }

  String getRandomPrompt() {
    final random = Random();
    return reflectionPrompts[random.nextInt(reflectionPrompts.length)];
  }

  Future<void> addEntry({
    required String title,
    required String content,
    required String mood,
    List<String> imagePaths = const [],
    String? voiceNotePath,
    bool isLocked = false,
    String prompt = "",
  }) async {
    final newEntry = JournalModel(
      id: _uuid.v4(),
      date: DateTime.now(),
      title: title,
      content: content,
      mood: mood,
      imagePaths: imagePaths,
      voiceNotePath: voiceNotePath,
      isLocked: isLocked,
      prompt: prompt,
    );

    state = [newEntry, ...state];
    await _db.saveJournalEntry(newEntry.id, newEntry.toMap());
  }

  Future<void> updateEntry(JournalModel updatedEntry) async {
    state = [
      for (final entry in state)
        if (entry.id == updatedEntry.id) updatedEntry else entry
    ];
    await _db.saveJournalEntry(updatedEntry.id, updatedEntry.toMap());
  }

  Future<void> deleteEntry(String id) async {
    state = state.where((entry) => entry.id != id).toList();
    await _db.deleteJournalEntry(id);
  }

  Future<void> toggleEntryLock(String id) async {
    final entryIndex = state.indexWhere((entry) => entry.id == id);
    if (entryIndex != -1) {
      final entry = state[entryIndex];
      final updated = entry.copyWith(isLocked: !entry.isLocked);
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == entryIndex) updated else state[i]
      ];
      await _db.saveJournalEntry(updated.id, updated.toMap());
    }
  }
}

// Search filtering
final journalSearchQueryProvider = StateProvider<String>((ref) => '');

final searchedJournalEntriesProvider = Provider<List<JournalModel>>((ref) {
  final entries = ref.watch(journalListProvider);
  final query = ref.watch(journalSearchQueryProvider);

  if (query.isEmpty) return entries;

  return entries.where((entry) {
    final titleMatch = entry.title.toLowerCase().contains(query.toLowerCase());
    final contentMatch = entry.content.toLowerCase().contains(query.toLowerCase());
    final moodMatch = entry.mood.toLowerCase().contains(query.toLowerCase());
    return titleMatch || contentMatch || moodMatch;
  }).toList();
});
