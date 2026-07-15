import 'package:flutter/material.dart';

/// Central place for the app's seed color and a few brand accents.
///
/// Material 3 generates a full, accessible color scheme from a single
/// "seed" color, so we mostly only need to pick that one nice color.
/// Individual feature cards use the accents below for a friendly, colorful
/// home screen.
class AppColors {
  AppColors._(); // This class only holds static values — never instantiate it.

  /// The main brand color. Material 3 derives the whole palette from this.
  static const Color seed = Color(0xFF4C6FFF); // A friendly, modern blue.

  /// Accent colors used for the big home-screen feature buttons.
  /// Kept intentionally distinct so beginners can tell buttons apart quickly.
  static const Color scan = Color(0xFF4C6FFF); // Blue
  static const Color photo = Color(0xFF00B894); // Teal/green
  static const Color upload = Color(0xFF6C5CE7); // Purple
  static const Color question = Color(0xFFFF9F43); // Orange
  static const Color calculator = Color(0xFFE84393); // Pink
  static const Color timer = Color(0xFF0984E3); // Sky blue
  static const Color flashcards = Color(0xFF00CEC9); // Cyan
  static const Color history = Color(0xFFEB5757); // Red

  /// Soft success/warning/danger colors for status messages.
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF39C12);
  static const Color danger = Color(0xFFE74C3C);
}
