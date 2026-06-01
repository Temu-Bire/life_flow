import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  late Box _tasksBox;
  late Box _habitsBox;
  late Box _journalBox;
  late Box _settingsBox;
  late Box _goalsBox;
  late Box _focusBox;
  late Box _notesBox;
  late Box _reviewsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    
    // Open boxes for structured Map-based records
    _tasksBox = await Hive.openBox('tasks');
    _habitsBox = await Hive.openBox('habits');
    _journalBox = await Hive.openBox('journal');
    _settingsBox = await Hive.openBox('settings');
    _goalsBox = await Hive.openBox('goals');
    _focusBox = await Hive.openBox('focus_sessions');
    _notesBox = await Hive.openBox('notes');
    _reviewsBox = await Hive.openBox('reviews');

    if (kDebugMode) {
      print("Hive offline-first database initialized successfully with v2 boxes.");
    }
  }

  // Task database interfaces
  List<Map<String, dynamic>> getAllTasks() {
    return _tasksBox.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> saveTask(String id, Map<String, dynamic> taskJson) async {
    await _tasksBox.put(id, taskJson);
  }

  Future<void> deleteTask(String id) async {
    await _tasksBox.delete(id);
  }

  Future<void> clearAllTasks() async {
    await _tasksBox.clear();
  }

  // Habit database interfaces
  List<Map<String, dynamic>> getAllHabits() {
    return _habitsBox.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> saveHabit(String id, Map<String, dynamic> habitJson) async {
    await _habitsBox.put(id, habitJson);
  }

  Future<void> deleteHabit(String id) async {
    await _habitsBox.delete(id);
  }

  Future<void> clearAllHabits() async {
    await _habitsBox.clear();
  }

  // Journal database interfaces
  List<Map<String, dynamic>> getAllJournalEntries() {
    return _journalBox.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> saveJournalEntry(String id, Map<String, dynamic> entryJson) async {
    await _journalBox.put(id, entryJson);
  }

  Future<void> deleteJournalEntry(String id) async {
    await _journalBox.delete(id);
  }

  Future<void> clearAllJournals() async {
    await _journalBox.clear();
  }

  // Goal database interfaces
  List<Map<String, dynamic>> getAllGoals() {
    return _goalsBox.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> saveGoal(String id, Map<String, dynamic> goalJson) async {
    await _goalsBox.put(id, goalJson);
  }

  Future<void> deleteGoal(String id) async {
    await _goalsBox.delete(id);
  }

  Future<void> clearAllGoals() async {
    await _goalsBox.clear();
  }

  // Focus Session database interfaces
  List<Map<String, dynamic>> getAllFocusSessions() {
    return _focusBox.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> saveFocusSession(String id, Map<String, dynamic> sessionJson) async {
    await _focusBox.put(id, sessionJson);
  }

  Future<void> deleteFocusSession(String id) async {
    await _focusBox.delete(id);
  }

  Future<void> clearAllFocusSessions() async {
    await _focusBox.clear();
  }

  // Note/Knowledge database interfaces
  List<Map<String, dynamic>> getAllNotes() {
    return _notesBox.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> saveNote(String id, Map<String, dynamic> noteJson) async {
    await _notesBox.put(id, noteJson);
  }

  Future<void> deleteNote(String id) async {
    await _notesBox.delete(id);
  }

  Future<void> clearAllNotes() async {
    await _notesBox.clear();
  }

  // Review/Reflection database interfaces
  List<Map<String, dynamic>> getAllReviews() {
    return _reviewsBox.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> saveReview(String id, Map<String, dynamic> reviewJson) async {
    await _reviewsBox.put(id, reviewJson);
  }

  Future<void> deleteReview(String id) async {
    await _reviewsBox.delete(id);
  }

  Future<void> clearAllReviews() async {
    await _reviewsBox.clear();
  }

  // Settings database interfaces
  dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  // Backup and Restore (JSON dump of boxes)
  String exportBackup() {
    final Map<String, dynamic> backupData = {
      'tasks': _tasksBox.toMap().map((key, value) => MapEntry(key.toString(), Map<String, dynamic>.from(value as Map))),
      'habits': _habitsBox.toMap().map((key, value) => MapEntry(key.toString(), Map<String, dynamic>.from(value as Map))),
      'journal': _journalBox.toMap().map((key, value) => MapEntry(key.toString(), Map<String, dynamic>.from(value as Map))),
      'settings': _settingsBox.toMap().map((key, value) => MapEntry(key.toString(), value)),
      'goals': _goalsBox.toMap().map((key, value) => MapEntry(key.toString(), Map<String, dynamic>.from(value as Map))),
      'focus_sessions': _focusBox.toMap().map((key, value) => MapEntry(key.toString(), Map<String, dynamic>.from(value as Map))),
      'notes': _notesBox.toMap().map((key, value) => MapEntry(key.toString(), Map<String, dynamic>.from(value as Map))),
      'reviews': _reviewsBox.toMap().map((key, value) => MapEntry(key.toString(), Map<String, dynamic>.from(value as Map))),
      'timestamp': DateTime.now().toIso8601String(),
    };
    return jsonEncode(backupData);
  }

  Future<bool> importBackup(String backupJson) async {
    try {
      final Map<String, dynamic> backupData = jsonDecode(backupJson) as Map<String, dynamic>;
      
      if (backupData.containsKey('tasks')) {
        await _tasksBox.clear();
        final tasks = backupData['tasks'] as Map<String, dynamic>;
        for (var entry in tasks.entries) {
          await _tasksBox.put(entry.key, Map<String, dynamic>.from(entry.value as Map));
        }
      }
      
      if (backupData.containsKey('habits')) {
        await _habitsBox.clear();
        final habits = backupData['habits'] as Map<String, dynamic>;
        for (var entry in habits.entries) {
          await _habitsBox.put(entry.key, Map<String, dynamic>.from(entry.value as Map));
        }
      }

      if (backupData.containsKey('journal')) {
        await _journalBox.clear();
        final journals = backupData['journal'] as Map<String, dynamic>;
        for (var entry in journals.entries) {
          await _journalBox.put(entry.key, Map<String, dynamic>.from(entry.value as Map));
        }
      }

      if (backupData.containsKey('settings')) {
        await _settingsBox.clear();
        final settings = backupData['settings'] as Map<String, dynamic>;
        for (var entry in settings.entries) {
          await _settingsBox.put(entry.key, entry.value);
        }
      }

      if (backupData.containsKey('goals')) {
        await _goalsBox.clear();
        final goals = backupData['goals'] as Map<String, dynamic>;
        for (var entry in goals.entries) {
          await _goalsBox.put(entry.key, Map<String, dynamic>.from(entry.value as Map));
        }
      }

      if (backupData.containsKey('focus_sessions')) {
        await _focusBox.clear();
        final sessions = backupData['focus_sessions'] as Map<String, dynamic>;
        for (var entry in sessions.entries) {
          await _focusBox.put(entry.key, Map<String, dynamic>.from(entry.value as Map));
        }
      }

      if (backupData.containsKey('notes')) {
        await _notesBox.clear();
        final notes = backupData['notes'] as Map<String, dynamic>;
        for (var entry in notes.entries) {
          await _notesBox.put(entry.key, Map<String, dynamic>.from(entry.value as Map));
        }
      }

      if (backupData.containsKey('reviews')) {
        await _reviewsBox.clear();
        final reviews = backupData['reviews'] as Map<String, dynamic>;
        for (var entry in reviews.entries) {
          await _reviewsBox.put(entry.key, Map<String, dynamic>.from(entry.value as Map));
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print("Error during database restore: $e");
      }
      return false;
    }
  }
}
