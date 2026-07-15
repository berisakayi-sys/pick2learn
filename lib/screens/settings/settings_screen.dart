import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/responsive.dart';
import '../../providers/homework_provider.dart';
import '../../providers/settings_provider.dart';

/// A clean, grouped settings page: appearance, answers, the AI connection,
/// data management, and an about section.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.contentMaxWidth(context),
            ),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // --- Appearance ---------------------------------------
                _SectionHeader('Appearance'),
                Card(
                  child: Column(
                    children: [
                      RadioListTile<ThemeMode>(
                        title: const Text('System default'),
                        subtitle: const Text('Match my device'),
                        value: ThemeMode.system,
                        groupValue: settings.themeMode,
                        onChanged: (v) => notifier.setThemeMode(v!),
                      ),
                      RadioListTile<ThemeMode>(
                        title: const Text('Light mode'),
                        value: ThemeMode.light,
                        groupValue: settings.themeMode,
                        onChanged: (v) => notifier.setThemeMode(v!),
                      ),
                      RadioListTile<ThemeMode>(
                        title: const Text('Dark mode'),
                        value: ThemeMode.dark,
                        groupValue: settings.themeMode,
                        onChanged: (v) => notifier.setThemeMode(v!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // --- Answers ------------------------------------------
                _SectionHeader('Answers'),
                Card(
                  child: SwitchListTile(
                    title: const Text('Show only the answer'),
                    subtitle: const Text(
                        'When on, skip the step-by-step explanation and just '
                        'show the final answer.'),
                    value: settings.showOnlyAnswer,
                    onChanged: notifier.setShowOnlyAnswer,
                  ),
                ),
                const SizedBox(height: 20),

                // --- AI connection ------------------------------------
                _SectionHeader('AI connection'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pick2Learn reads photos and explains answers using '
                          'the Anthropic Claude API. Paste your API key below to '
                          'enable it.',
                        ),
                        const SizedBox(height: 12),
                        _ApiKeyField(
                          initialValue: settings.apiKey,
                          onSave: notifier.setApiKey,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: settings.model,
                          decoration: const InputDecoration(labelText: 'Model'),
                          items: const [
                            DropdownMenuItem(
                              value: 'claude-sonnet-5',
                              child: Text('Claude Sonnet 5 (balanced)'),
                            ),
                            DropdownMenuItem(
                              value: 'claude-opus-4-8',
                              child: Text('Claude Opus 4.8 (most capable)'),
                            ),
                            DropdownMenuItem(
                              value: 'claude-haiku-4-5-20251001',
                              child: Text('Claude Haiku 4.5 (fastest)'),
                            ),
                          ],
                          onChanged: (v) =>
                              v == null ? null : notifier.setModel(v),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              settings.hasApiKey
                                  ? Icons.check_circle
                                  : Icons.error_outline,
                              size: 16,
                              color: settings.hasApiKey
                                  ? Colors.green
                                  : Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 6),
                            Text(settings.hasApiKey
                                ? 'AI is ready'
                                : 'No key set yet'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // --- Data ---------------------------------------------
                _SectionHeader('Data'),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.delete_sweep_outlined,
                        color: Theme.of(context).colorScheme.error),
                    title: const Text('Clear all history'),
                    subtitle: const Text('Deletes every saved homework item.'),
                    onTap: () => _confirmClear(context, ref),
                  ),
                ),
                const SizedBox(height: 20),

                // --- About --------------------------------------------
                _SectionHeader('About'),
                Card(
                  child: Column(
                    children: const [
                      ListTile(
                        leading: Icon(Icons.info_outline),
                        title: Text(AppConstants.appName),
                        subtitle: Text('Version 1.0.0'),
                      ),
                      ListTile(
                        leading: Icon(Icons.school_outlined),
                        title: Text(AppConstants.appTagline),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text(
            'This permanently deletes every saved homework item. This cannot '
            'be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(homeworkListProvider.notifier).clearAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('History cleared.')),
        );
      }
    }
  }
}

/// A small uppercase-ish section label.
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// A password-style field for the API key with a show/hide toggle and a save
/// button, so the key isn't saved on every keystroke.
class _ApiKeyField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onSave;

  const _ApiKeyField({required this.initialValue, required this.onSave});

  @override
  State<_ApiKeyField> createState() => _ApiKeyFieldState();
}

class _ApiKeyFieldState extends State<_ApiKeyField> {
  late final TextEditingController _controller;
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      obscureText: _obscured,
      decoration: InputDecoration(
        labelText: 'API key',
        hintText: 'sk-ant-…',
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(_obscured ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscured = !_obscured),
            ),
            IconButton(
              icon: const Icon(Icons.save_outlined),
              tooltip: 'Save key',
              onPressed: () {
                widget.onSave(_controller.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('API key saved.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
