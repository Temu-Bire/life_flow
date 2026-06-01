class NoteModel {
  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final List<String> linkedNoteIds;
  final DateTime lastModified;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    this.tags = const [],
    this.linkedNoteIds = const [],
    required this.lastModified,
  });

  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? tags,
    List<String>? linkedNoteIds,
    DateTime? lastModified,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      linkedNoteIds: linkedNoteIds ?? this.linkedNoteIds,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'tags': tags,
      'linkedNoteIds': linkedNoteIds,
      'lastModified': lastModified.toIso8601String(),
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] as String,
      title: map['title'] as String? ?? "",
      content: map['content'] as String? ?? "",
      tags: List<String>.from(map['tags'] as List? ?? []),
      linkedNoteIds: List<String>.from(map['linkedNoteIds'] as List? ?? []),
      lastModified: DateTime.tryParse(map['lastModified'] as String) ?? DateTime.now(),
    );
  }
}
