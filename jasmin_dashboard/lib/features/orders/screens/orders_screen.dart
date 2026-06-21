import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/layouts/admin_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/orders_provider.dart';
import '../widgets/order_filters_bar.dart';
import '../widgets/order_list_tile.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
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
    final state = ref.watch(ordersProvider);
    final controller = ref.read(ordersProvider.notifier);

    return AdminScaffold(
      title: 'Orders',
      currentRoute: '/orders',
      actions: [
        IconButton(
          tooltip: 'Refresh orders',
          onPressed: state.isRefreshing ? null : () => controller.refresh(),
          icon: state.isRefreshing
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.3))
              : const Icon(Icons.refresh_rounded),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            _Header(total: state.total, lastUpdatedAt: state.lastUpdatedAt),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search order number, UID, customer, phone, email, payment ref...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                          ref.read(ordersProvider.notifier).setQuery('');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
              onChanged: (value) {
                setState(() {});
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 450), () {
                  ref.read(ordersProvider.notifier).setQuery(value);
                });
              },
              onSubmitted: (value) => ref.read(ordersProvider.notifier).setQuery(value),
            ),
            const SizedBox(height: 12),
            OrderFiltersBar(
              selectedStatus: state.status,
              onStatusChanged: controller.setStatus,
            ),
            const SizedBox(height: 16),
            if (state.errorMessage != null)
              _MessageCard(
                icon: Icons.error_outline_rounded,
                title: 'Could not load orders',
                message: state.errorMessage!,
                onRetry: controller.refresh,
              ),
            if (state.isLoading && !state.hasOrders)
              const _OrdersLoading()
            else if (!state.hasOrders)
              EmptyState(
                icon: Icons.receipt_long_rounded,
                title: 'No orders found',
                message: state.query.isNotEmpty || state.status != 'ALL'
                    ? 'Try clearing the search or changing the status filter.'
                    : 'New customer orders will appear here automatically.',
              )
            else ...[
              for (final order in state.orders) OrderListTile(order: order),
              const SizedBox(height: 8),
              _PaginationBar(
                page: state.page,
                totalPages: state.totalPages,
                total: state.total,
                onPrevious: state.canGoPrevious ? controller.previousPage : null,
                onNext: state.canGoNext ? controller.nextPage : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.total, required this.lastUpdatedAt});

  final int total;
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
              Text('Orders management', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(
                '$total matching orders • auto-refresh every 20s',
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

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Page $page of $totalPages • $total total',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(onPressed: onPrevious, icon: const Icon(Icons.chevron_left_rounded), tooltip: 'Previous page'),
            IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right_rounded), tooltip: 'Next page'),
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

class _OrdersLoading extends StatelessWidget {
  const _OrdersLoading();

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
                Container(width: 46, height: 46, decoration: BoxDecoration(color: Colors.black.withOpacity(0.06), borderRadius: BorderRadius.circular(18))),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 14, width: 170, decoration: BoxDecoration(color: Colors.black.withOpacity(0.06), borderRadius: BorderRadius.circular(999))),
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
