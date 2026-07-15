import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'service_providers.dart';

/// Holds all user settings as immutable state and persists changes.
///
/// The UI watches this so, for example, flipping dark mode instantly re-themes
/// the whole app.
class SettingsState {
  final ThemeMode themeMode;
  final bool showOnlyAnswer;
  final String apiKey;
  final String model;

  const SettingsState({
    required this.themeMode,
    required this.showOnlyAnswer,
    required this.apiKey,
    required this.model,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? showOnlyAnswer,
    String? apiKey,
    String? model,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      showOnlyAnswer: showOnlyAnswer ?? this.showOnlyAnswer,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
    );
  }

  bool get hasApiKey => apiKey.trim().isNotEmpty;
}

/// The controller that reads the saved settings once, then updates + persists
/// them as the user changes things.
class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref _ref;

  SettingsNotifier(this._ref)
      : super(_loadInitial(_ref));

  static SettingsState _loadInitial(Ref ref) {
    final s = ref.read(settingsServiceProvider);
    return SettingsState(
      themeMode: s.themeMode,
      showOnlyAnswer: s.showOnlyAnswer,
      apiKey: s.apiKey,
      model: s.model,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _ref.read(settingsServiceProvider).setThemeMode(mode);
  }

  Future<void> setShowOnlyAnswer(bool value) async {
    state = state.copyWith(showOnlyAnswer: value);
    await _ref.read(settingsServiceProvider).setShowOnlyAnswer(value);
  }

  Future<void> setApiKey(String value) async {
    state = state.copyWith(apiKey: value.trim());
    await _ref.read(settingsServiceProvider).setApiKey(value);
  }

  Future<void> setModel(String value) async {
    state = state.copyWith(model: value);
    await _ref.read(settingsServiceProvider).setModel(value);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(ref),
);
