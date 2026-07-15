import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'providers/service_providers.dart';
import 'services/database_service.dart';

/// App entry point.
///
/// We do a little async setup BEFORE running the app:
///   1. Load SharedPreferences (settings).
///   2. Open + prepare the local database (history/flashcards).
/// Then we inject those ready-to-use instances into Riverpod by *overriding*
/// their providers, so the rest of the app can read them synchronously.
Future<void> main() async {
  // Required when doing async work before runApp().
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Settings storage.
  final prefs = await SharedPreferences.getInstance();

  // 2. Local database. If it fails we still launch — history just won't load,
  //    and the UI shows a friendly error instead of a crash.
  final db = DatabaseService();
  try {
    await db.init();
  } catch (e) {
    debugPrint('Database failed to initialize: $e');
  }

  runApp(
    ProviderScope(
      // Provide the already-loaded singletons to the whole app.
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseServiceProvider.overrideWithValue(db),
      ],
      child: const Pick2LearnApp(),
    ),
  );
}
