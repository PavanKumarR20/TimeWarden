import 'package:flutter/material.dart';
import '../../domain/entities/journal_entry.dart';
import '../../../../core/services/haptic_service.dart';

class JournalEntryCard extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onDelete;

  const JournalEntryCard({
    super.key,
    required this.entry,
    this.onTap,
    this.onFavoriteToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () {
          HapticService.lightImpact();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with date, mood, and actions
              Row(
                children: [
                  // Show mood emoji if available
                  if (entry.mood != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.primaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.mood!.emoji,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            entry.mood!.label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      entry.dateString,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (entry.isFavorite)
                        Icon(
                          Icons.favorite,
                          color: theme.colorScheme.error,
                          size: 18,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        entry.timeString,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        onSelected: (value) {
                          HapticService.buttonTap();
                          switch (value) {
                            case 'favorite':
                              onFavoriteToggle?.call();
                              break;
                            case 'delete':
                              onDelete?.call();
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'favorite',
                            child: Row(
                              children: [
                                Icon(
                                  entry.isFavorite
                                      ? Icons.favorite_border
                                      : Icons.favorite,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(entry.isFavorite
                                    ? 'Remove from favorites'
                                    : 'Add to favorites'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Content preview
              Text(
                entry.preview,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // Tags (if any)
              if (entry.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    // Tags
                    ...entry.tags.map((tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#$tag',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        )),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
