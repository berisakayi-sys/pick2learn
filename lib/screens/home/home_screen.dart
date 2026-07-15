import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../providers/service_providers.dart';
import '../../providers/settings_provider.dart';
import '../../services/image_service.dart';
import '../../widgets/feature_card.dart';
import '../../widgets/glass.dart';
import '../calculator/calculator_screen.dart';
import '../flashcards/flashcards_screen.dart';
import '../history/history_screen.dart';
import '../question/question_screen.dart';
import '../scan/photo_review_screen.dart';
import '../scan/scan_screen.dart';
import '../settings/settings_screen.dart';
import '../timer/timer_screen.dart';

/// The main landing screen: a friendly greeting plus a responsive grid of
/// large feature buttons. This is the "menu" of the whole app.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // The list of home features. Keeping them in a list makes the grid tidy
    // and easy to reorder or extend.
    final features = <_Feature>[
      _Feature(
        icon: Icons.document_scanner_outlined,
        label: 'Scan Homework',
        subtitle: 'Use the camera',
        color: AppColors.scan,
        onTap: () => _open(context, const ScanScreen()),
      ),
      _Feature(
        icon: Icons.photo_camera_outlined,
        label: 'Take a Photo',
        subtitle: 'Snap a question',
        color: AppColors.photo,
        onTap: () => _pickImage(context, ref, fromCamera: true),
      ),
      _Feature(
        icon: Icons.upload_file_outlined,
        label: 'Upload a Photo',
        subtitle: 'From your gallery',
        color: AppColors.upload,
        onTap: () => _pickImage(context, ref, fromCamera: false),
      ),
      _Feature(
        icon: Icons.edit_note_outlined,
        label: 'Type a Question',
        subtitle: 'Ask anything',
        color: AppColors.question,
        onTap: () => _open(context, const QuestionScreen()),
      ),
      _Feature(
        icon: Icons.calculate_outlined,
        label: 'Math Calculator',
        subtitle: 'Solve & compute',
        color: AppColors.calculator,
        onTap: () => _open(context, const CalculatorScreen()),
      ),
      _Feature(
        icon: Icons.timer_outlined,
        label: 'Study Timer',
        subtitle: 'Focus sessions',
        color: AppColors.timer,
        onTap: () => _open(context, const TimerScreen()),
      ),
      _Feature(
        icon: Icons.style_outlined,
        label: 'Flashcards',
        subtitle: 'Review & memorize',
        color: AppColors.flashcards,
        onTap: () => _open(context, const FlashcardsScreen()),
      ),
      _Feature(
        icon: Icons.history_outlined,
        label: 'History',
        subtitle: 'Past homework',
        color: AppColors.history,
        onTap: () => _open(context, const HistoryScreen()),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          // Quick light/dark toggle right in the app bar.
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(_themeIcon(ref)),
            onPressed: () => _cycleTheme(ref),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _open(context, const SettingsScreen()),
          ),
          const SizedBox(width: 4),
        ],
      ),
      // Transparent scaffold + glass background = frosted, ChatGPT-style look.
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Center(
            // Constrain width so the grid looks great on wide desktop/web too.
            child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _Greeting()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: Responsive.gridColumns(context),
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.05,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final f = features[i];
                        return FeatureCard(
                          icon: f.icon,
                          label: f.label,
                          subtitle: f.subtitle,
                          color: f.color,
                          index: i,
                          onTap: f.onTap,
                        );
                      },
                      childCount: features.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      AppConstants.appTagline,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Navigation helpers -----------------------------------------------

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  /// Handles "Take a Photo" (camera) and "Upload a Photo" (gallery): grabs an
  /// image, then sends it to the review/OCR screen. Errors are shown gently.
  Future<void> _pickImage(BuildContext context, WidgetRef ref,
      {required bool fromCamera}) async {
    final imageService = ref.read(imageServiceProvider);
    try {
      final PickedImage? image = fromCamera
          ? await imageService.takePhoto()
          : await imageService.pickFromGallery();
      if (image == null || !context.mounted) return; // Cancelled.
      _open(context, PhotoReviewScreen(image: image));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Failure: ', ''))),
      );
    }
  }

  // --- Theme toggle ------------------------------------------------------

  IconData _themeIcon(WidgetRef ref) {
    switch (ref.watch(settingsProvider).themeMode) {
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
    }
  }

  /// Cycles System → Light → Dark → System.
  void _cycleTheme(WidgetRef ref) {
    final notifier = ref.read(settingsProvider.notifier);
    final current = ref.read(settingsProvider).themeMode;
    final next = switch (current) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    notifier.setThemeMode(next);
  }
}

/// A small data holder describing one home feature button.
class _Feature {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  _Feature({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

/// The friendly header at the top of the home screen.
class _Greeting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hi there 👋',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'What would you like help with today?',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
