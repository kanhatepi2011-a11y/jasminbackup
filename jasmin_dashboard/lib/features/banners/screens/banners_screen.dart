import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/layouts/admin_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/banner_model.dart';
import '../providers/banners_provider.dart';
import '../widgets/banner_filters_bar.dart';
import '../widgets/banner_list_tile.dart';

class BannersScreen extends ConsumerStatefulWidget {
  const BannersScreen({super.key});

  @override
  ConsumerState<BannersScreen> createState() => _BannersScreenState();
}

class _BannersScreenState extends ConsumerState<BannersScreen> {
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
    final state = ref.watch(bannersProvider);
    final controller = ref.read(bannersProvider.notifier);
    final banners = state.filteredBanners;

    ref.listen(bannersProvider, (previous, next) {
      final success = next.successMessage;
      if (success != null && success != previous?.successMessage) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(success)));
      }
      final error = next.errorMessage;
      if (error != null &&
          error != previous?.errorMessage &&
          previous?.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error),
            backgroundColor: Theme.of(context).colorScheme.error));
      }
    });

    return AdminScaffold(
      title: 'Banners',
      currentRoute: '/banners',
      actions: [
        IconButton(
          tooltip: 'Refresh banners',
          onPressed: state.isRefreshing ? null : () => controller.refresh(),
          icon: state.isRefreshing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2))
              : const Icon(Icons.refresh_rounded),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            _Header(
              total: state.banners.length,
              visible: state.banners.where((banner) => banner.active).length,
              lastUpdatedAt: state.lastUpdatedAt,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search banners',
                hintText: 'Title, subtitle, CTA, link...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) {
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 250),
                    () => controller.setQuery(value));
              },
            ),
            const SizedBox(height: 12),
            BannerFiltersBar(
              selectedActiveFilter: state.activeFilter,
              onActiveChanged: controller.setActiveFilter,
            ),
            const SizedBox(height: 16),
            if (state.errorMessage != null && state.banners.isEmpty)
              _ErrorCard(
                  message: state.errorMessage!, onRetry: controller.refresh),
            if (state.isLoading)
              const _LoadingList()
            else if (banners.isEmpty)
              const EmptyState(
                icon: Icons.view_carousel_rounded,
                title: 'No banners found',
                message: 'Create a homepage banner or adjust your filters.',
              )
            else
              for (final banner in banners)
                BannerListTile(
                  banner: banner,
                  isBusy: state.actionBannerId == banner.id,
                  onToggleActive: () => controller.toggleActive(banner),
                  onDelete: () => _confirmDelete(context, controller, banner),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context,
      BannersController controller, BannerModel banner) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete banner?'),
            content: Text(
                'This removes “${banner.safeTitle}” from homepage banners.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete')),
            ],
          ),
        ) ??
        false;
    if (ok) {
      await controller.deleteBanner(banner);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header(
      {required this.total,
      required this.visible,
      required this.lastUpdatedAt});

  final int total;
  final int visible;
  final DateTime? lastUpdatedAt;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.12),
                child: Icon(Icons.view_carousel_rounded,
                    color: Theme.of(context).colorScheme.primary)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Homepage banners',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(
                      '$visible visible • $total total • Updated ${Formatters.dateTimeOrDash(lastUpdatedAt)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.black54)),
                ],
              ),
            ),
            FilledButton.icon(
                onPressed: () => context.go('/banners/new'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('New Banner')),
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
            padding: const EdgeInsets.all(18),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Could not load banners',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(message),
              const SizedBox(height: 12),
              FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'))
            ])));
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();
  @override
  Widget build(BuildContext context) => Column(
      children: List.generate(
          4,
          (index) => const Card(
              margin: EdgeInsets.only(bottom: 12),
              child: SizedBox(
                  height: 92,
                  child: Center(child: CircularProgressIndicator())))));
}
