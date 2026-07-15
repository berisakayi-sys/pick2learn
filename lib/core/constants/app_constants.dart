/// App-wide constant values kept in one place so they're easy to change.
class AppConstants {
  AppConstants._();

  static const String appName = 'Pick2Learn';
  static const String appTagline = 'Scan it. Understand it. Learn it.';

  // --- Shared-preferences keys (settings persistence) -------------------
  static const String prefThemeMode = 'pref_theme_mode';
  static const String prefShowOnlyAnswer = 'pref_show_only_answer';
  static const String prefApiKey = 'pref_api_key';
  static const String prefApiModel = 'pref_api_model';
  static const String prefOnboarded = 'pref_onboarded';

  // --- Database ----------------------------------------------------------
  static const String dbName = 'pick2learn.db';
  static const int dbVersion = 1;
  static const String tableHomework = 'homework';
  static const String tableFlashcards = 'flashcards';

  // --- AI service --------------------------------------------------------
  // Default model used for explanations + vision OCR. You can change this in
  // Settings. These are Anthropic Claude model IDs (vision-capable).
  static const String defaultModel = 'claude-sonnet-5';
  static const String anthropicVersion = '2023-06-01';
  static const String anthropicBaseUrl = 'https://api.anthropic.com/v1/messages';

  // Max characters we send/keep to avoid runaway payloads.
  static const int maxQuestionLength = 8000;
}
