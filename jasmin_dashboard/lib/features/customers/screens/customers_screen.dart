import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/layouts/admin_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/customers_provider.dart';
import '../widgets/customer_list_tile.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customersProvider);
    final controller = ref.read(customersProvider.notifier);
    return AdminScaffold(
      title: 'Customers',
      currentRoute: '/customers',
      actions: [
        IconButton(
            tooltip: 'Refresh customers',
            onPressed: state.isRefreshing ? null : controller.refresh,
            icon: state.isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.3))
                : const Icon(Icons.refresh_rounded))
      ],
      child: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              _Header(
                  total: state.total,
                  shown: state.customers.length,
                  lastUpdatedAt: state.lastUpdatedAt),
              const SizedBox(height: 16),
              TextField(
                controller: _search,
                decoration: InputDecoration(
                    hintText: 'Search email, phone, nickname, UID...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _search.clear();
                              setState(() {});
                              controller.search('');
                            })),
                onChanged: (value) {
                  setState(() {});
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 350),
                      () => controller.search(value));
                },
              ),
              const SizedBox(height: 16),
              if (state.errorMessage != null && state.customers.isEmpty)
                _ErrorCard(
                    message: state.errorMessage!, onRetry: controller.refresh),
              if (state.isLoading)
                const _LoadingList()
              else if (state.customers.isEmpty)
                const EmptyState(
                    icon: Icons.people_alt_rounded,
                    title: 'No customers found',
                    message:
                        'Try a different search term or wait for new orders.')
              else
                for (final customer in state.customers)
                  CustomerListTile(customer: customer),
            ]),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(
      {required this.total, required this.shown, required this.lastUpdatedAt});
  final int total;
  final int shown;
  final DateTime? lastUpdatedAt;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            CircleAvatar(
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.12),
                child: Icon(Icons.people_alt_rounded,
                    color: Theme.of(context).colorScheme.primary)),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Customer overview',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(
                      '$shown shown • $total total • Updated ${Formatters.dateTimeOrDash(lastUpdatedAt)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.black54))
                ]))
          ])));
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Could not load customers',
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

class _LoadingList extends StatelessWidget {
  const _LoadingList();
  @override
  Widget build(BuildContext context) => Column(
      children: List.generate(
          4,
          (_) => const Card(
              margin: EdgeInsets.only(bottom: 12),
              child: SizedBox(
                  height: 108,
                  child: Center(child: CircularProgressIndicator())))));
}
