import 'package:equatable/equatable.dart';

enum MoodType {
  happy('😊', 'Good'),
  neutral('😐', 'Okay'),
  tired('😴', 'Tired'),
  sad('�', 'Not great');

  const MoodType(this.emoji, this.label);
  final String emoji;
  final String label;
}

class JournalEntry extends Equatable {
  final String id;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final MoodType? mood;
  final List<String> attachments; // URLs or file paths
  final bool isFavorite;

  const JournalEntry({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.mood,
    this.attachments = const [],
    this.isFavorite = false,
  });

  JournalEntry copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    MoodType? mood,
    List<String>? attachments,
    bool? isFavorite,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      mood: mood ?? this.mood,
      attachments: attachments ?? this.attachments,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': tags,
      'mood': mood?.name,
      'attachments': attachments,
      'isFavorite': isFavorite,
    };
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      tags: List<String>.from(json['tags'] as List? ?? []),
      mood: json['mood'] != null
          ? MoodType.values.firstWhere(
              (m) => m.name == json['mood'],
              orElse: () => MoodType.neutral,
            )
          : null,
      attachments: List<String>.from(json['attachments'] as List? ?? []),
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  String get dateString {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

    if (entryDate == today) {
      return 'Today';
    } else if (entryDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  String get timeString {
    return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  String get preview {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }

  @override
  List<Object?> get props => [
        id,
        content,
        createdAt,
        updatedAt,
        tags,
        mood,
        attachments,
        isFavorite,
      ];
}
