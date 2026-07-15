import 'subject.dart';

/// A simple study flashcard: a question on the front, an answer on the back.
///
/// Cards can be created by hand or generated from a piece of homework. They're
/// stored in their own database table.
class Flashcard {
  final String id;
  final String front; // The prompt / question side.
  final String back; // The answer side.
  final Subject subject;
  final bool isFavorite;
  final DateTime createdAt;

  Flashcard({
    required this.id,
    required this.front,
    required this.back,
    this.subject = Subject.general,
    this.isFavorite = false,
    required this.createdAt,
  });

  Flashcard copyWith({
    String? front,
    String? back,
    Subject? subject,
    bool? isFavorite,
  }) {
    return Flashcard(
      id: id,
      front: front ?? this.front,
      back: back ?? this.back,
      subject: subject ?? this.subject,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toDbMap() => {
        'id': id,
        'front': front,
        'back': back,
        'subject': subject.name,
        'is_favorite': isFavorite ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory Flashcard.fromDbMap(Map<String, dynamic> map) => Flashcard(
        id: map['id'] as String,
        front: map['front'] as String? ?? '',
        back: map['back'] as String? ?? '',
        subject: Subject.fromName(map['subject'] as String?),
        isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
        createdAt:
            DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}
