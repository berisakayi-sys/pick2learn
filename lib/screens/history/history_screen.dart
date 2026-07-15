import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/utils/responsive.dart';
import '../../models/homework_item.dart';
import '../../providers/homework_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../answer/answer_screen.dart';

/// The History screen: a searchable list of every saved homework item, with a
/// favorites filter. Tap an item to reopen its explanation; swipe to delete.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(homeworkListProvider);
    final filtered = ref.watch(filteredHomeworkProvider);
    final favOnly = ref.watch(showFavoritesOnlyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          // Toggle the favorites-only filter.
          IconButton(
            tooltip: favOnly ? 'Show all' : 'Show bookmarks only',
            icon: Icon(favOnly ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () => ref
                .read(showFavoritesOnlyProvider.notifier)
                .state = !favOnly,
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
                // Search box.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    onChanged: (v) =>
                        ref.read(searchQueryProvider.notifier).state = v,
                    decoration: InputDecoration(
                      hintText: 'Search your homework…',
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),
                Expanded(
                  child: listAsync.when(
                    loading: () =>
                        const LoadingView(message: 'Loading history…'),
                    error: (e, _) => ErrorView(
                      error: e,
                      onRetry: () =>
                          ref.read(homeworkListProvider.notifier).refresh(),
                    ),
                    data: (_) {
                      if (filtered.isEmpty) {
                        return EmptyState(
                          icon: favOnly
                              ? Icons.bookmark_border
                              : Icons.history_outlined,
                          title: favOnly
                              ? 'No bookmarks yet'
                              : 'No homework yet',
                          message: favOnly
                              ? 'Tap the bookmark icon on any answer to save it here.'
                              : 'Scan, upload, or type a question to get started.',
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => _HistoryTile(
                          item: filtered[i],
                          onOpen: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AnswerScreen(item: filtered[i]),
                            ),
                          ),
                          onFavorite: () => ref
                              .read(homeworkListProvider.notifier)
                              .toggleFavorite(filtered[i].id),
                          onDelete: () => ref
                              .read(homeworkListProvider.notifier)
                              .delete(filtered[i].id),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One row in the history list.
class _HistoryTile extends StatelessWidget {
  final HomeworkItem item;
  final VoidCallback onOpen;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;

  const _HistoryTile({
    required this.item,
    required this.onOpen,
    required this.onFavorite,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline,
            color: theme.colorScheme.onErrorContainer),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete this homework?'),
                content: const Text('It will be removed from your history.'),
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
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Subject icon badge.
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.subject.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.subject.icon,
                      color: item.subject.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.subject.label} · ${DateFormat.yMMMd().add_jm().format(item.updatedAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    item.isFavorite ? Icons.bookmark : Icons.bookmark_border,
                    color: item.isFavorite ? theme.colorScheme.primary : null,
                  ),
                  onPressed: onFavorite,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
