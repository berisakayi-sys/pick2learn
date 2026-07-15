import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/responsive.dart';
import '../../models/flashcard.dart';
import '../../models/subject.dart';
import '../../providers/flashcard_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

/// Shows the user's flashcards in a responsive grid. Tap a card to flip it
/// (question ↔ answer). Add new cards with the button; delete via long-press.
class FlashcardsScreen extends ConsumerWidget {
  const FlashcardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(flashcardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Flashcards')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New card'),
      ),
      body: SafeArea(
        child: cardsAsync.when(
          loading: () => const LoadingView(message: 'Loading flashcards…'),
          error: (e, _) => ErrorView(
            error: e,
            onRetry: () => ref.invalidate(flashcardProvider),
          ),
          data: (cards) {
            if (cards.isEmpty) {
              return EmptyState(
                icon: Icons.style_outlined,
                title: 'No flashcards yet',
                message:
                    'Create cards to review and memorize facts, formulas, and vocabulary.',
                actionLabel: 'Add your first card',
                onAction: () => _showAddDialog(context, ref),
              );
            }
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: Responsive.value(context,
                        phone: 2, tablet: 3, desktop: 4),
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (context, i) => _FlipCard(
                    card: cards[i],
                    onDelete: () => ref
                        .read(flashcardProvider.notifier)
                        .delete(cards[i].id),
                    onFavorite: () => ref
                        .read(flashcardProvider.notifier)
                        .toggleFavorite(cards[i].id),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// A dialog for creating a new flashcard.
  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final frontController = TextEditingController();
    final backController = TextEditingController();
    Subject subject = Subject.general;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New flashcard'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: frontController,
                  autofocus: true,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Front (question)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: backController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Back (answer)',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Subject>(
                  value: subject,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  items: Subject.values
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.label),
                          ))
                      .toList(),
                  onChanged: (s) => setState(() => subject = s ?? subject),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (frontController.text.trim().isEmpty ||
                    backController.text.trim().isEmpty) {
                  return;
                }
                ref.read(flashcardProvider.notifier).add(
                      front: frontController.text,
                      back: backController.text,
                      subject: subject,
                    );
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single flashcard that flips between front and back with a 3D animation.
class _FlipCard extends StatefulWidget {
  final Flashcard card;
  final VoidCallback onDelete;
  final VoidCallback onFavorite;

  const _FlipCard({
    required this.card,
    required this.onDelete,
    required this.onFavorite,
  });

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _showingFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_showingFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _showingFront = !_showingFront;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.card.subject.color;

    return GestureDetector(
      onTap: _flip,
      onLongPress: () => _confirmDelete(context),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Rotate around the Y axis. Halfway through we swap faces.
          final angle = _controller.value * math.pi;
          final isBack = angle > math.pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateY(angle),
            child: isBack
                // The back face is rotated again so its text isn't mirrored.
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _face(theme, color, isFront: false),
                  )
                : _face(theme, color, isFront: true),
          );
        },
      ),
    );
  }

  Widget _face(ThemeData theme, Color color, {required bool isFront}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isFront
            ? color.withValues(alpha: 0.12)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(widget.card.subject.icon, size: 16, color: color),
              const Spacer(),
              GestureDetector(
                onTap: widget.onFavorite,
                child: Icon(
                  widget.card.isFavorite
                      ? Icons.star
                      : Icons.star_border,
                  size: 18,
                  color: widget.card.isFavorite ? Colors.amber : color,
                ),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  isFront ? widget.card.front : widget.card.back,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: isFront ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
          Text(
            isFront ? 'Tap to reveal' : 'Answer',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete card?'),
        content: const Text('This flashcard will be removed permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onDelete();
  }
}
