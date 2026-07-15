import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/ai_service.dart';
import '../services/database_service.dart';
import '../services/image_service.dart';
import '../services/settings_service.dart';

/// These providers expose the app's singleton services to the rest of the app.
///
/// A couple of them ([sharedPreferencesProvider], [databaseServiceProvider])
/// are *overridden* in main.dart after async setup completes, so they can be
/// read synchronously everywhere else.

/// Overridden in main.dart with the real, already-loaded instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in main.dart'),
);

/// Overridden in main.dart with the already-initialized database.
final databaseServiceProvider = Provider<DatabaseService>(
  (ref) => throw UnimplementedError('Override in main.dart'),
);

/// Settings service, built on top of the loaded SharedPreferences.
final settingsServiceProvider = Provider<SettingsService>(
  (ref) => SettingsService(ref.watch(sharedPreferencesProvider)),
);

/// The AI (OCR + explanations) service. Disposed with the provider.
final aiServiceProvider = Provider<AiService>((ref) {
  final service = AiService();
  ref.onDispose(service.dispose);
  return service;
});

/// Image picking / camera service.
final imageServiceProvider = Provider<ImageService>((ref) => ImageService());
