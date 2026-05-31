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

  Future<void> init() async {
    await Hive.initFlutter();
    
    // Open boxes for structured Map-based records
    _tasksBox = await Hive.openBox('tasks');
    _habitsBox = await Hive.openBox('habits');
    _journalBox = await Hive.openBox('journal');
    _settingsBox = await Hive.openBox('settings');

    if (kDebugMode) {
      print("Hive offline-first database initialized successfully.");
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

      return true;
    } catch (e) {
      if (kDebugMode) {
        print("Error during database restore: $e");
      }
      return false;
    }
  }
}
