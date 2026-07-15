/// Who sent a message in a homework conversation.
enum MessageRole { user, assistant }

/// A single message in the back-and-forth about a piece of homework.
///
/// The first assistant message is usually the full step-by-step explanation;
/// later ones are answers to the user's follow-up questions.
class ChatMessage {
  final MessageRole role;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == MessageRole.user;

  /// Convert to a plain map for JSON storage inside a homework record.
  Map<String, dynamic> toMap() => {
        'role': role.name,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
        role: map['role'] == 'user' ? MessageRole.user : MessageRole.assistant,
        content: map['content'] as String? ?? '',
        timestamp:
            DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
      );
}
