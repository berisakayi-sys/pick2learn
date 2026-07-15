import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'screens/home/home_screen.dart';

/// The root widget. It wires up:
///   - the app title,
///   - the light/dark themes (with Material You dynamic color when available),
///   - the current theme mode from settings,
///   - and the first screen (Home).
class Pick2LearnApp extends ConsumerWidget {
  const Pick2LearnApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch just the theme mode so changing it instantly re-themes the app.
    final themeMode =
        ref.watch(settingsProvider.select((s) => s.themeMode));

    // DynamicColorBuilder gives us the device's Material You palette on
    // supported platforms (Android 12+). On everything else, `light`/`dark`
    // are null and we fall back to our seed-based scheme.
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(lightDynamic),
          darkTheme: AppTheme.dark(darkDynamic),
          themeMode: themeMode,
          home: const HomeScreen(),
        );
      },
    );
  }
}
