import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../models/homework_item.dart';
import '../models/subject.dart';
import 'service_providers.dart';
import 'settings_provider.dart';

const _uuid = Uuid();

/// Loads and manages the full list of saved homework (the "History").
///
/// Everything that changes the list also writes to the database, so history
/// survives restarts. The UI watches [homeworkListProvider] to stay in sync.
class HomeworkListNotifier extends StateNotifier<AsyncValue<List<HomeworkItem>>> {
  final Ref _ref;

  HomeworkListNotifier(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final db = _ref.read(databaseServiceProvider);
      final items = await db.getAllHomework();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Reload from the database (e.g. pull-to-refresh).
  Future<void> refresh() => _load();

  /// Adds a brand-new homework item and persists it.
  Future<void> add(HomeworkItem item) async {
    await _ref.read(databaseServiceProvider).upsertHomework(item);
    state = state.whenData((list) => [item, ...list]);
  }

  /// Replaces an existing item (e.g. after a follow-up answer) and persists it.
  Future<void> update(HomeworkItem item) async {
    await _ref.read(databaseServiceProvider).upsertHomework(item);
    state = state.whenData(
      (list) => [
        for (final it in list)
          if (it.id == item.id) item else it,
      ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
    );
  }

  Future<void> delete(String id) async {
    await _ref.read(databaseServiceProvider).deleteHomework(id);
    state = state.whenData((list) => list.where((it) => it.id != id).toList());
  }

  Future<void> toggleFavorite(String id) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final item = current.firstWhere((it) => it.id == id);
    final updated = item.copyWith(isFavorite: !item.isFavorite);
    await update(updated);
  }

  Future<void> clearAll() async {
    await _ref.read(databaseServiceProvider).clearAllHomework();
    state = const AsyncValue.data([]);
  }
}

final homeworkListProvider = StateNotifierProvider<HomeworkListNotifier,
    AsyncValue<List<HomeworkItem>>>((ref) => HomeworkListNotifier(ref));

// --- Search + filter state for the History screen ----------------------

/// The current text typed into the History search box.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Whether the History screen is filtered to favorites only.
final showFavoritesOnlyProvider = StateProvider<bool>((ref) => false);

/// The list actually shown in History, after applying search + favorite filter.
final filteredHomeworkProvider = Provider<List<HomeworkItem>>((ref) {
  final all = ref.watch(homeworkListProvider).valueOrNull ?? const [];
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final favOnly = ref.watch(showFavoritesOnlyProvider);

  return all.where((item) {
    if (favOnly && !item.isFavorite) return false;
    if (query.isEmpty) return true;
    // Search across the title, the question, and the answers.
    final haystack = [
      item.title,
      item.question,
      item.subject.label,
      ...item.messages.map((m) => m.content),
    ].join(' ').toLowerCase();
    return haystack.contains(query);
  }).toList();
});

// --- Creating / answering homework -------------------------------------

/// Helper that builds a fresh [HomeworkItem] from a question, gets the first
/// step-by-step explanation from the AI, saves it, and returns it.
///
/// Screens call this after the user types a question or after OCR reads a photo.
class HomeworkController {
  final Ref _ref;
  HomeworkController(this._ref);

  Future<HomeworkItem> createAndExplain({
    required String question,
    required Subject subject,
    String? imagePath,
  }) async {
    final settings = _ref.read(settingsProvider);
    final ai = _ref.read(aiServiceProvider);

    // Ask the AI for the first explanation.
    final answer = await ai.explainQuestion(
      question: question,
      subject: subject,
      showOnlyAnswer: settings.showOnlyAnswer,
      apiKey: settings.apiKey,
      model: settings.model,
    );

    final now = DateTime.now();
    final item = HomeworkItem(
      id: _uuid.v4(),
      title: _titleFrom(question),
      question: question,
      subject: subject,
      imagePath: imagePath,
      messages: [
        ChatMessage(role: MessageRole.user, content: question, timestamp: now),
        ChatMessage(
            role: MessageRole.assistant, content: answer, timestamp: now),
      ],
      createdAt: now,
      updatedAt: now,
    );

    await _ref.read(homeworkListProvider.notifier).add(item);
    return item;
  }

  /// Sends a follow-up question inside an existing homework item, appends both
  /// the question and the AI's answer, saves, and returns the updated item.
  Future<HomeworkItem> askFollowUp({
    required HomeworkItem item,
    required String followUp,
  }) async {
    final settings = _ref.read(settingsProvider);
    final ai = _ref.read(aiServiceProvider);

    final answer = await ai.askFollowUp(
      history: item.messages,
      followUp: followUp,
      subject: item.subject,
      showOnlyAnswer: settings.showOnlyAnswer,
      apiKey: settings.apiKey,
      model: settings.model,
    );

    final updated = item.copyWith(
      messages: [
        ...item.messages,
        ChatMessage(role: MessageRole.user, content: followUp),
        ChatMessage(role: MessageRole.assistant, content: answer),
      ],
      updatedAt: DateTime.now(),
    );

    await _ref.read(homeworkListProvider.notifier).update(updated);
    return updated;
  }

  /// Uses the first line of the question as a short, tidy title.
  String _titleFrom(String question) {
    final firstLine = question.trim().split('\n').first.trim();
    if (firstLine.isEmpty) return 'Homework';
    return firstLine.length > 60 ? '${firstLine.substring(0, 60)}…' : firstLine;
  }
}

final homeworkControllerProvider =
    Provider<HomeworkController>((ref) => HomeworkController(ref));
