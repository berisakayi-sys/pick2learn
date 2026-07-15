import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';

/// Reads and writes the small user settings that need to survive app restarts:
/// theme choice, the "show only answer" preference, and the AI API key/model.
///
/// Uses shared_preferences, which works on every platform.
class SettingsService {
  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  /// Convenience async constructor.
  static Future<SettingsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService(prefs);
  }

  // --- Theme -------------------------------------------------------------

  ThemeMode get themeMode {
    final raw = _prefs.getString(AppConstants.prefThemeMode);
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system; // Follow the device by default.
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(AppConstants.prefThemeMode, mode.name);
  }

  // --- "Show only answer" toggle ----------------------------------------

  bool get showOnlyAnswer =>
      _prefs.getBool(AppConstants.prefShowOnlyAnswer) ?? false;

  Future<void> setShowOnlyAnswer(bool value) async {
    await _prefs.setBool(AppConstants.prefShowOnlyAnswer, value);
  }

  // --- AI key + model ----------------------------------------------------

  String get apiKey => _prefs.getString(AppConstants.prefApiKey) ?? '';

  Future<void> setApiKey(String value) async {
    await _prefs.setString(AppConstants.prefApiKey, value.trim());
  }

  String get model =>
      _prefs.getString(AppConstants.prefApiModel) ?? AppConstants.defaultModel;

  Future<void> setModel(String value) async {
    await _prefs.setString(AppConstants.prefApiModel, value);
  }

  // --- Onboarding flag ---------------------------------------------------

  bool get onboarded => _prefs.getBool(AppConstants.prefOnboarded) ?? false;

  Future<void> setOnboarded(bool value) async {
    await _prefs.setBool(AppConstants.prefOnboarded, value);
  }
}
