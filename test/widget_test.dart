// A small smoke test for Pick2Learn.
//
// The full app needs async setup (SharedPreferences + a database), which isn't
// available in a plain widget test, so here we verify the pieces that don't
// depend on those services: the themes build correctly and core widgets render.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick2learn/core/theme/app_theme.dart';
import 'package:pick2learn/widgets/empty_state.dart';

void main() {
  test('Light and dark themes build with Material 3', () {
    final light = AppTheme.light();
    final dark = AppTheme.dark();
    expect(light.useMaterial3, isTrue);
    expect(dark.useMaterial3, isTrue);
    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
  });

  testWidgets('EmptyState shows its title and message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.history,
            title: 'No homework yet',
            message: 'Scan or type a question to get started.',
          ),
        ),
      ),
    );

    expect(find.text('No homework yet'), findsOneWidget);
    expect(find.text('Scan or type a question to get started.'), findsOneWidget);
  });
}
