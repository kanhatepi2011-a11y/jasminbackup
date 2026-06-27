import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/layouts/admin_scaffold.dart';
import '../models/customer_detail_model.dart';
import '../providers/customers_provider.dart';

class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.customerKey});
  final String customerKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customerDetailProvider(customerKey));
    final controller = ref.read(customerDetailProvider(customerKey).notifier);

    ref.listen(customerDetailProvider(customerKey), (previous, next) {
      if (next.successMessage != null &&
          next.successMessage != previous?.successMessage) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.successMessage!)));
      }
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage &&
          previous?.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error));
      }
    });

    final detail = state.detail;
    return AdminScaffold(
      title: 'Customer Detail',
      currentRoute: '/customers',
      actions: [
        IconButton(
            tooltip: 'Refresh customer',
            onPressed: state.isRefreshing ? null : controller.load,
            icon: state.isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2))
                : const Icon(Icons.refresh_rounded))
      ],
      child: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : detail == null
              ? Center(
                  child: FilledButton.icon(
                      onPressed: controller.load,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry')))
              : RefreshIndicator(
                  onRefresh: controller.load,
                  child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      children: [
                        _CustomerCard(
                            detail: detail.customer,
                            isBusy: state.isActionBusy,
                            onBanToggle: () => _confirmBan(
                                context, controller, detail.customer)),
                        const SizedBox(height: 16),
                        Text('Order history',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 10),
                        for (final order in detail.orders)
                          _OrderTile(order: order),
                        if (detail.orders.isEmpty)
                          const Card(
                              child: Padding(
                                  padding: EdgeInsets.all(18),
                                  child: Text(
                                      'No orders found for this customer.'))),
                        const SizedBox(height: 20),
                        TextButton(
                            onPressed: () => context.go('/customers'),
                            child: const Text('Back to Customers')),
                      ]),
                ),
    );
  }

  Future<void> _confirmBan(BuildContext context,
      CustomerDetailController controller, CustomerDetail customer) async {
    if (customer.banned) {
      final ok = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                      title: const Text('Unban customer?'),
                      content: Text(
                          'Allow ${customer.label} to place orders again?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel')),
                        FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Unban'))
                      ])) ??
          false;
      if (ok) {
        await controller.setBan(banned: false);
      }
      return;
    }
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Ban customer?'),
                content: TextField(
                    controller: reasonController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        labelText: 'Reason',
                        hintText:
                            'Suspicious activity, fake order, abusive behavior...')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.of(context)
                          .pop(reasonController.text.trim()),
                      child: const Text('Ban'))
                ]));
    reasonController.dispose();
    if (reason != null) {
      await controller.setBan(banned: true, reason: reason);
    }
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard(
      {required this.detail, required this.isBusy, required this.onBanToggle});
  final CustomerDetail detail;
  final bool isBusy;
  final VoidCallback onBanToggle;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                  backgroundColor: detail.banned
                      ? Colors.red.withValues(alpha: 0.12)
                      : Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.12),
                  foregroundColor: detail.banned
                      ? Colors.red
                      : Theme.of(context).colorScheme.primary,
                  child: Icon(detail.banned
                      ? Icons.block_rounded
                      : Icons.person_rounded)),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(detail.label,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(
                        detail.banned
                            ? 'Banned: ${detail.banReason ?? 'No reason'}'
                            : 'Allowed to order',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: detail.banned
                                ? Colors.red.shade700
                                : Colors.black54))
                  ])),
              FilledButton.tonalIcon(
                  onPressed: isBusy ? null : onBanToggle,
                  icon: isBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(detail.banned
                          ? Icons.check_circle_rounded
                          : Icons.block_rounded),
                  label: Text(detail.banned ? 'Unban' : 'Ban'))
            ]),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _Info(label: '${detail.totalOrders} orders'),
              _Info(label: '${detail.paidOrders} paid'),
              _Info(label: Formatters.moneyUsd(detail.lifetimeUsd)),
              if (detail.email != null) _Info(label: detail.email!),
              if (detail.phone != null) _Info(label: detail.phone!)
            ])
          ])));
}

class _Info extends StatelessWidget {
  const _Info({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(fontWeight: FontWeight.w800)));
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});
  final CustomerOrderModel order;
  @override
  Widget build(BuildContext context) => Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
          onTap: () =>
              context.go('/orders/${Uri.encodeComponent(order.orderNumber)}'),
          leading: const Icon(Icons.receipt_long_rounded),
          title: Text(order.orderNumber,
              style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text(
              '${order.gameName ?? 'Game'} • ${order.productName ?? 'Package'} • UID ${order.playerUid}\n${Formatters.statusLabel(order.status)} • ${Formatters.dateTimeOrDash(order.createdAt)}'),
          isThreeLine: true,
          trailing: Text(Formatters.moneyUsd(order.amountUsd),
              style: const TextStyle(fontWeight: FontWeight.w900))));
}
