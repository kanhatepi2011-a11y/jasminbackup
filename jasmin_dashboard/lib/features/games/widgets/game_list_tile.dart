import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../models/game_model.dart';
import 'game_status_pill.dart';

class GameListTile extends StatelessWidget {
  const GameListTile({
    super.key,
    required this.game,
    required this.isBusy,
    required this.onToggleActive,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final GameModel game;
  final bool isBusy;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.go('/games/${Uri.encodeComponent(game.id)}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GameAvatar(game: game),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            game.safeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GameStatusPill(active: game.active, featured: game.featured, compact: true),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '/${game.safeSlug} • ${game.publisher.isEmpty ? 'No publisher' : game.publisher}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game.description?.isNotEmpty == true ? game.description! : 'No description yet.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _MiniInfo(icon: Icons.paid_rounded, label: game.currencyName.isEmpty ? 'Currency' : game.currencyName),
                        _MiniInfo(icon: Icons.person_search_rounded, label: game.uidLabel),
                        _MiniInfo(icon: Icons.sort_rounded, label: 'Order ${game.sortOrder}'),
                        _MiniInfo(icon: Icons.inventory_2_rounded, label: '${game.productsCount} products'),
                        _MiniInfo(icon: Icons.receipt_long_rounded, label: '${game.ordersCount} orders'),
                        if (game.updatedAt != null) _MiniInfo(icon: Icons.update_rounded, label: Formatters.dateTimeOrDash(game.updatedAt)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isBusy)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.3)),
                )
              else
                PopupMenuButton<String>(
                  tooltip: 'Game actions',
                  onSelected: (value) {
                    if (value == 'edit') context.go('/games/${Uri.encodeComponent(game.id)}');
                    if (value == 'toggle') onToggleActive();
                    if (value == 'up') onMoveUp();
                    if (value == 'down') onMoveDown();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: _MenuRow(icon: Icons.edit_rounded, label: 'Edit')),
                    PopupMenuItem(
                      value: 'toggle',
                      child: _MenuRow(
                        icon: game.active ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        label: game.active ? 'Hide from website' : 'Show on website',
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'up', child: _MenuRow(icon: Icons.keyboard_arrow_up_rounded, label: 'Move up')),
                    const PopupMenuItem(value: 'down', child: _MenuRow(icon: Icons.keyboard_arrow_down_rounded, label: 'Move down')),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'delete', child: _MenuRow(icon: Icons.delete_outline_rounded, label: 'Delete safely')),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameAvatar extends StatelessWidget {
  const _GameAvatar({required this.game});

  final GameModel game;

  @override
  Widget build(BuildContext context) {
    final color = game.active ? Theme.of(context).colorScheme.primary : Colors.black45;
    final imageUrl = game.imagePreviewUrl;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.startsWith('http')
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.sports_esports_rounded, color: color),
            )
          : Icon(Icons.sports_esports_rounded, color: color),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black45),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }
}
