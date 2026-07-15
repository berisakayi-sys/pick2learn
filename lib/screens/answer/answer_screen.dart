import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/responsive.dart';
import '../../models/chat_message.dart';
import '../../models/homework_item.dart';
import '../../providers/homework_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/math_markdown.dart';

/// Shows a single homework item: the original question, the AI's step-by-step
/// explanation, and a conversation area for follow-up questions.
///
/// This screen is reached after typing a question, scanning a photo, or tapping
/// an item in History.
class AnswerScreen extends ConsumerStatefulWidget {
  final HomeworkItem item;

  const AnswerScreen({super.key, required this.item});

  @override
  ConsumerState<AnswerScreen> createState() => _AnswerScreenState();
}

class _AnswerScreenState extends ConsumerState<AnswerScreen> {
  late HomeworkItem _item;
  final _followUpController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  @override
  void dispose() {
    _followUpController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Sends a follow-up question to the AI and appends the answer.
  Future<void> _sendFollowUp() async {
    final text = _followUpController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _followUpController.clear();

    try {
      final updated = await ref
          .read(homeworkControllerProvider)
          .askFollowUp(item: _item, followUp: text);
      if (!mounted) return;
      setState(() => _item = updated);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Failure: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _toggleFavorite() async {
    await ref.read(homeworkListProvider.notifier).toggleFavorite(_item.id);
    setState(() => _item = _item.copyWith(isFavorite: !_item.isFavorite));
  }

  @override
  Widget build(BuildContext context) {
    final showOnlyAnswer =
        ref.watch(settingsProvider.select((s) => s.showOnlyAnswer));

    return Scaffold(
      appBar: AppBar(
        title: Text(_item.subject.label),
        actions: [
          IconButton(
            tooltip: _item.isFavorite ? 'Remove bookmark' : 'Bookmark',
            icon: Icon(
              _item.isFavorite ? Icons.bookmark : Icons.bookmark_border,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.contentMaxWidth(context),
            ),
            child: Column(
              children: [
                // A small banner reminding the user of the current mode.
                if (showOnlyAnswer)
                  _ModeBanner(
                    text: 'Showing only answers. Turn off in Settings for '
                        'step-by-step explanations.',
                  ),
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      _QuestionCard(item: _item),
                      const SizedBox(height: 16),
                      // Render every message in the conversation.
                      for (final message in _item.messages)
                        if (message.role == MessageRole.assistant)
                          _AnswerBubble(content: message.content)
                        else if (message.content != _item.question)
                          // Skip the very first user message (it's the question
                          // already shown in the card above); show follow-ups.
                          _FollowUpBubble(content: message.content),
                      if (_sending) ...[
                        const SizedBox(height: 8),
                        const _ThinkingIndicator(),
                      ],
                    ],
                  ),
                ),
                _FollowUpInput(
                  controller: _followUpController,
                  enabled: !_sending,
                  onSend: _sendFollowUp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the original question (and photo, if there was one).
class _QuestionCard extends StatelessWidget {
  final HomeworkItem item;
  const _QuestionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(item.subject.icon, size: 18, color: item.subject.color),
                const SizedBox(width: 6),
                Text('Question',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: item.subject.color)),
              ],
            ),
            const SizedBox(height: 10),
            // Show the scanned image thumbnail if we have one (not on web).
            if (item.imagePath != null && File(item.imagePath!).existsSync()) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(item.imagePath!), fit: BoxFit.cover),
              ),
              const SizedBox(height: 12),
            ],
            SelectableText(
              item.question,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

/// A rendered AI explanation (Markdown + math).
class _AnswerBubble extends StatelessWidget {
  final String content;
  const _AnswerBubble({required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: MathMarkdown(data: content),
    );
  }
}

/// A user's follow-up question, right-aligned like a chat bubble.
class _FollowUpBubble extends StatelessWidget {
  final String content;
  const _FollowUpBubble({required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 8, left: 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(content, style: theme.textTheme.bodyMedium),
      ),
    );
  }
}

/// The bottom input row for asking a follow-up question.
class _FollowUpInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  const _FollowUpInput({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        MediaQuery.viewInsetsOf(context).bottom + 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                hintText: 'Ask a follow-up question…',
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: enabled ? onSend : null,
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(16),
            ),
            child: const Icon(Icons.arrow_upward),
          ),
        ],
      ),
    );
  }
}

/// A little "thinking…" row shown while waiting for the AI.
class _ThinkingIndicator extends StatelessWidget {
  const _ThinkingIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Text('Thinking…', style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

/// A thin info banner used at the top of the screen.
class _ModeBanner extends StatelessWidget {
  final String text;
  const _ModeBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              size: 16, color: theme.colorScheme.onTertiaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                )),
          ),
        ],
      ),
    );
  }
}
