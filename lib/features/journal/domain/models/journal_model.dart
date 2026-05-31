class JournalModel {
  final String id;
  final DateTime date;
  final String title;
  final String content;
  final String mood; // Happy, Calm, Neutral, Sad, Angry, Stressed
  final List<String> imagePaths;
  final String? voiceNotePath;
  final bool isLocked;
  final String prompt;

  JournalModel({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    this.mood = "Calm",
    this.imagePaths = const [],
    this.voiceNotePath,
    this.isLocked = false,
    this.prompt = "",
  });

  JournalModel copyWith({
    String? id,
    DateTime? date,
    String? title,
    String? content,
    String? mood,
    List<String>? imagePaths,
    String? voiceNotePath,
    bool? isLocked,
    String? prompt,
  }) {
    return JournalModel(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      imagePaths: imagePaths ?? this.imagePaths,
      voiceNotePath: voiceNotePath ?? this.voiceNotePath,
      isLocked: isLocked ?? this.isLocked,
      prompt: prompt ?? this.prompt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'title': title,
      'content': content,
      'mood': mood,
      'imagePaths': imagePaths,
      'voiceNotePath': voiceNotePath,
      'isLocked': isLocked,
      'prompt': prompt,
    };
  }

  factory JournalModel.fromMap(Map<String, dynamic> map) {
    return JournalModel(
      id: map['id'] as String,
      date: DateTime.tryParse(map['date'] as String) ?? DateTime.now(),
      title: map['title'] as String? ?? "",
      content: map['content'] as String? ?? "",
      mood: map['mood'] as String? ?? "Calm",
      imagePaths: List<String>.from(map['imagePaths'] as List? ?? []),
      voiceNotePath: map['voiceNotePath'] as String?,
      isLocked: map['isLocked'] as bool? ?? false,
      prompt: map['prompt'] as String? ?? "",
    );
  }
}
