import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/layouts/admin_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/product_model.dart';
import '../providers/products_provider.dart';
import '../widgets/product_filters_bar.dart';
import '../widgets/product_list_tile.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
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
    final state = ref.watch(productsProvider);
    final controller = ref.read(productsProvider.notifier);
    final products = state.filteredProducts;

    ref.listen(productsProvider, (previous, next) {
      final success = next.successMessage;
      if (success != null && success != previous?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
      }
      final error = next.errorMessage;
      if (error != null && error != previous?.errorMessage && previous?.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    });

    return AdminScaffold(
      title: 'Products',
      currentRoute: '/products',
      actions: [
        IconButton(
          tooltip: 'Refresh products',
          onPressed: state.isRefreshing ? null : () => controller.refresh(),
          icon: state.isRefreshing
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.3))
              : const Icon(Icons.refresh_rounded),
        ),
        IconButton.filledTonal(
          tooltip: 'Create package',
          onPressed: () => context.go('/products/new'),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            _Header(total: products.length, allTotal: state.products.length, lastUpdatedAt: state.lastUpdatedAt),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search package name, game, badge, supplier code, amount, price...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                          ref.read(productsProvider.notifier).setQuery('');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
              onChanged: (value) {
                setState(() {});
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 350), () {
                  ref.read(productsProvider.notifier).setQuery(value);
                });
              },
              onSubmitted: (value) => ref.read(productsProvider.notifier).setQuery(value),
            ),
            const SizedBox(height: 12),
            ProductFiltersBar(
              games: state.games,
              selectedGameId: state.gameId,
              selectedActiveFilter: state.activeFilter,
              onGameChanged: controller.setGameFilter,
              onActiveChanged: controller.setActiveFilter,
            ),
            const SizedBox(height: 16),
            if (state.errorMessage != null)
              _MessageCard(
                icon: Icons.error_outline_rounded,
                title: 'Could not load products',
                message: state.errorMessage!,
                onRetry: controller.refresh,
              ),
            if (state.isLoading && !state.hasProducts)
              const _ProductsLoading()
            else if (products.isEmpty)
              EmptyState(
                icon: Icons.inventory_2_rounded,
                title: 'No packages found',
                message: state.query.isNotEmpty || state.gameId != 'ALL' || state.activeFilter != 'ALL'
                    ? 'Try clearing search or changing filters.'
                    : 'Create your first package and it will appear on the website automatically.',
              )
            else ...[
              for (final product in products)
                ProductListTile(
                  product: product,
                  isBusy: state.actionProductId == product.id,
                  onToggleActive: () => controller.toggleActive(product),
                  onDelete: () async {
                    final confirmed = await _confirmDelete(context, product);
                    if (confirmed && mounted) await controller.deleteProduct(product);
                  },
                ),
              const SizedBox(height: 8),
              _WebsiteUpdateCard(productCount: products.length),
            ],
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, ProductModel product) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete package safely?'),
            content: Text(
              product.hasOrders
                  ? '${product.name} already has ${product.ordersCount} orders. The backend should disable it instead of deleting it, so old orders stay safe.'
                  : '${product.name} will be deleted if it has no orders. This action is audited.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete safely'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.total, required this.allTotal, required this.lastUpdatedAt});

  final int total;
  final int allTotal;
  final DateTime? lastUpdatedAt;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Products / packages', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(
                '$total shown • $allTotal loaded • auto-refresh every 30s',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
              if (lastUpdatedAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Last updated ${Formatters.shortTime.format(lastUpdatedAt!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black45),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _WebsiteUpdateCard extends StatelessWidget {
  const _WebsiteUpdateCard({required this.productCount});

  final int productCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.sync_rounded, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$productCount packages loaded. Changes are sent to the backend, audited, and the website cache is revalidated automatically.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.icon, required this.title, required this.message, required this.onRetry});

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(message),
                ],
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _ProductsLoading extends StatelessWidget {
  const _ProductsLoading();

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
                Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.black.withOpacity(0.06), borderRadius: BorderRadius.circular(18))),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 14, width: 190, decoration: BoxDecoration(color: Colors.black.withOpacity(0.06), borderRadius: BorderRadius.circular(999))),
                      const SizedBox(height: 10),
                      Container(height: 12, width: double.infinity, decoration: BoxDecoration(color: Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(999))),
                      const SizedBox(height: 8),
                      Container(height: 12, width: 220, decoration: BoxDecoration(color: Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(999))),
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
