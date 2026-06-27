import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/layouts/admin_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/game_model.dart';
import '../providers/games_provider.dart';
import '../widgets/game_filters_bar.dart';
import '../widgets/game_list_tile.dart';

class GamesScreen extends ConsumerStatefulWidget {
  const GamesScreen({super.key});

  @override
  ConsumerState<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends ConsumerState<GamesScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gamesProvider);
    final controller = ref.read(gamesProvider.notifier);
    final games = state.filteredGames;

    ref.listen(gamesProvider, (previous, next) {
      final success = next.successMessage;
      if (success != null && success != previous?.successMessage) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(success)));
      }
      final error = next.errorMessage;
      if (error != null &&
          error != previous?.errorMessage &&
          previous?.errorMessage != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
    });

    return AdminScaffold(
      title: 'Games',
      currentRoute: '/games',
      actions: [
        IconButton(
          tooltip: 'Refresh games',
          onPressed: state.isRefreshing ? null : () => controller.refresh(),
          icon: state.isRefreshing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.3))
              : const Icon(Icons.refresh_rounded),
        ),
        IconButton.filledTonal(
          tooltip: 'Create game',
          onPressed: () => context.go('/games/new'),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            _Header(
                total: games.length,
                allTotal: state.games.length,
                lastUpdatedAt: state.lastUpdatedAt),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText:
                    'Search game name, slug, publisher, currency, UID label...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                          ref.read(gamesProvider.notifier).setQuery('');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
              onChanged: (value) {
                setState(() {});
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 350), () {
                  ref.read(gamesProvider.notifier).setQuery(value);
                });
              },
              onSubmitted: (value) =>
                  ref.read(gamesProvider.notifier).setQuery(value),
            ),
            const SizedBox(height: 12),
            GameFiltersBar(
              selectedActiveFilter: state.activeFilter,
              selectedFeaturedFilter: state.featuredFilter,
              onActiveChanged: controller.setActiveFilter,
              onFeaturedChanged: controller.setFeaturedFilter,
            ),
            const SizedBox(height: 18),
            if (state.isLoading)
              const _GameLoadingList()
            else if (state.errorMessage != null && !state.hasGames)
              _ErrorCard(
                  message: state.errorMessage!, onRetry: controller.refresh)
            else if (games.isEmpty)
              const EmptyState(
                icon: Icons.sports_esports_rounded,
                title: 'No games found',
                message:
                    'Try another search/filter or create a new public game for JASMINTOPUP.',
              )
            else
              ...games.map(
                (game) => GameListTile(
                  game: game,
                  isBusy: state.actionGameId == game.id,
                  onToggleActive: () => controller.toggleActive(game),
                  onMoveUp: () => controller.reorder(game, 'up'),
                  onMoveDown: () => controller.reorder(game, 'down'),
                  onDelete: () => _confirmDelete(context, game, controller),
                ),
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, GameModel game, GamesController controller) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete game safely?'),
        content: Text(
          game.canDeleteHard
              ? '${game.safeName} has no linked products/orders, so it can be deleted.'
              : '${game.safeName} has products or orders. The backend will disable it instead of deleting to protect existing data.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continue')),
        ],
      ),
    );
    if (result == true) {
      await controller.deleteGame(game);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header(
      {required this.total,
      required this.allTotal,
      required this.lastUpdatedAt});

  final int total;
  final int allTotal;
  final DateTime? lastUpdatedAt;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(Icons.sports_esports_rounded,
                  color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Games Management',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(
                    '$total showing • $allTotal total • updated ${Formatters.dateTimeOrDash(lastUpdatedAt)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.error_outline_rounded,
                size: 38, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 10),
            Text('Could not load games',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _GameLoadingList extends StatelessWidget {
  const _GameLoadingList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        5,
        (index) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20))),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          height: 14,
                          width: double.infinity,
                          color: Colors.black.withValues(alpha: 0.06)),
                      const SizedBox(height: 10),
                      Container(
                          height: 12,
                          width: 180,
                          color: Colors.black.withValues(alpha: 0.05)),
                    ],
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
