import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/flashcard.dart';
import '../models/subject.dart';
import 'service_providers.dart';

const _uuid = Uuid();

/// Loads and manages the user's flashcards, persisting every change.
class FlashcardNotifier extends StateNotifier<AsyncValue<List<Flashcard>>> {
  final Ref _ref;

  FlashcardNotifier(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final cards = await _ref.read(databaseServiceProvider).getAllFlashcards();
      state = AsyncValue.data(cards);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add({
    required String front,
    required String back,
    Subject subject = Subject.general,
  }) async {
    final card = Flashcard(
      id: _uuid.v4(),
      front: front.trim(),
      back: back.trim(),
      subject: subject,
      createdAt: DateTime.now(),
    );
    await _ref.read(databaseServiceProvider).upsertFlashcard(card);
    state = state.whenData((list) => [card, ...list]);
  }

  Future<void> delete(String id) async {
    await _ref.read(databaseServiceProvider).deleteFlashcard(id);
    state = state.whenData((list) => list.where((c) => c.id != id).toList());
  }

  Future<void> toggleFavorite(String id) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final card = current.firstWhere((c) => c.id == id);
    final updated = card.copyWith(isFavorite: !card.isFavorite);
    await _ref.read(databaseServiceProvider).upsertFlashcard(updated);
    state = state.whenData(
      (list) => [for (final c in list) if (c.id == id) updated else c],
    );
  }
}

final flashcardProvider =
    StateNotifierProvider<FlashcardNotifier, AsyncValue<List<Flashcard>>>(
  (ref) => FlashcardNotifier(ref),
);
