import 'dart:convert';

import 'chat_message.dart';
import 'subject.dart';

/// One saved piece of homework: the original question (typed or read from a
/// photo), the subject, the conversation (explanation + follow-ups), and a
/// couple of flags (favorite, image path).
///
/// This is the main object stored in the local database and shown in History.
class HomeworkItem {
  final String id;
  final String title; // Short label shown in lists (first line of the question).
  final String question; // The full question text (OCR'd or typed).
  final Subject subject;
  final List<ChatMessage> messages; // Explanation + follow-up Q&A.
  final String? imagePath; // Local path to the scanned/uploaded photo, if any.
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  HomeworkItem({
    required this.id,
    required this.title,
    required this.question,
    required this.subject,
    required this.messages,
    this.imagePath,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// The most recent assistant answer (used for previews in History).
  String get lastAnswerPreview {
    final assistant = messages.where((m) => m.role == MessageRole.assistant);
    if (assistant.isEmpty) return '';
    return assistant.last.content;
  }

  /// Returns a copy with some fields changed. Keeps [HomeworkItem] immutable,
  /// which plays nicely with Riverpod state updates.
  HomeworkItem copyWith({
    String? title,
    String? question,
    Subject? subject,
    List<ChatMessage>? messages,
    String? imagePath,
    bool? isFavorite,
    DateTime? updatedAt,
  }) {
    return HomeworkItem(
      id: id,
      title: title ?? this.title,
      question: question ?? this.question,
      subject: subject ?? this.subject,
      messages: messages ?? this.messages,
      imagePath: imagePath ?? this.imagePath,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // --- Database (de)serialization ---------------------------------------
  // The messages list is stored as a JSON string in a single column so we
  // don't need a separate messages table for this simple app.

  Map<String, dynamic> toDbMap() => {
        'id': id,
        'title': title,
        'question': question,
        'subject': subject.name,
        'messages': jsonEncode(messages.map((m) => m.toMap()).toList()),
        'image_path': imagePath,
        'is_favorite': isFavorite ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory HomeworkItem.fromDbMap(Map<String, dynamic> map) {
    final rawMessages = map['messages'] as String? ?? '[]';
    final decoded = (jsonDecode(rawMessages) as List<dynamic>)
        .map((e) => ChatMessage.fromMap(e as Map<String, dynamic>))
        .toList();

    return HomeworkItem(
      id: map['id'] as String,
      title: map['title'] as String? ?? 'Homework',
      question: map['question'] as String? ?? '',
      subject: Subject.fromName(map['subject'] as String?),
      messages: decoded,
      imagePath: map['image_path'] as String?,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
