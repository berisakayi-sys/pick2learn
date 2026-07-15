import 'package:flutter/material.dart';

/// The school subjects Pick2Learn supports.
///
/// Each subject carries a friendly label, an icon, and a color so the UI can
/// tag homework consistently. "General" is the catch-all default.
enum Subject {
  general('General', Icons.auto_stories_outlined, Color(0xFF636E72)),
  math('Math', Icons.calculate_outlined, Color(0xFFE84393)),
  science('Science', Icons.science_outlined, Color(0xFF00B894)),
  english('English', Icons.menu_book_outlined, Color(0xFF6C5CE7)),
  history('History', Icons.account_balance_outlined, Color(0xFFEB984E)),
  geography('Geography', Icons.public_outlined, Color(0xFF0984E3)),
  languages('Languages', Icons.translate_outlined, Color(0xFF00CEC9)),
  computerScience('Computer Science', Icons.code_outlined, Color(0xFF2D3436)),
  other('Other', Icons.category_outlined, Color(0xFFB2BEC3));

  const Subject(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  /// Rebuilds a [Subject] from its stored [name] (used when loading from DB).
  /// Falls back to [Subject.general] if the value is unknown.
  static Subject fromName(String? name) {
    return Subject.values.firstWhere(
      (s) => s.name == name,
      orElse: () => Subject.general,
    );
  }
}
