import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/responsive.dart';
import '../../models/subject.dart';
import '../../providers/homework_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/subject_picker.dart';
import '../answer/answer_screen.dart';

/// Lets the user type any homework question, pick a subject, and get a
/// step-by-step explanation.
class QuestionScreen extends ConsumerStatefulWidget {
  /// Optional starting text (used when arriving from OCR with pre-filled text).
  final String? initialText;

  const QuestionScreen({super.key, this.initialText});

  @override
  ConsumerState<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends ConsumerState<QuestionScreen> {
  late final TextEditingController _controller;
  Subject _subject = Subject.general;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Sends the question to the AI, saves the result, and opens the answer.
  Future<void> _submit() async {
    final question = _controller.text.trim();
    if (question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please type a question first.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final item = await ref.read(homeworkControllerProvider).createAndExplain(
            question: question,
            subject: _subject,
          );
      if (!mounted) return;
      // Replace this screen with the answer so "back" returns to Home.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => AnswerScreen(item: item)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Failure: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showOnlyAnswer =
        ref.watch(settingsProvider.select((s) => s.showOnlyAnswer));

    return Scaffold(
      appBar: AppBar(title: const Text('Type a Question')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.contentMaxWidth(context),
            ),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Choose a subject',
                    style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                SubjectPicker(
                  selected: _subject,
                  onChanged: (s) => setState(() => _subject = s),
                ),
                const SizedBox(height: 20),
                Text('Your question',
                    style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                TextField(
                  controller: _controller,
                  minLines: 4,
                  maxLines: 10,
                  autofocus: widget.initialText == null,
                  decoration: const InputDecoration(
                    hintText:
                        'e.g. Solve 2x + 5 = 15, or explain photosynthesis…',
                  ),
                ),
                const SizedBox(height: 16),
                // Quick access to the "only show answer" preference.
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show only the answer'),
                  subtitle: const Text(
                      'Off = full step-by-step explanation (recommended)'),
                  value: showOnlyAnswer,
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).setShowOnlyAnswer(v),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(_loading ? 'Thinking…' : 'Get Explanation'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
