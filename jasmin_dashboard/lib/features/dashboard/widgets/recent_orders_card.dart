import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../models/dashboard_recent_order.dart';

class RecentOrdersCard extends StatelessWidget {
  const RecentOrdersCard({
    super.key,
    required this.orders,
  });

  final List<DashboardRecentOrder> orders;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Recent orders', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                ),
                TextButton.icon(
                  onPressed: () => context.go('/orders'),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (orders.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: Text('No recent orders yet.')),
              )
            else
              ...orders.take(6).map((order) => _RecentOrderTile(order: order)),
          ],
        ),
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  const _RecentOrderTile({required this.order});

  final DashboardRecentOrder order;

  @override
  Widget build(BuildContext context) {
    final amount = order.amountKhr != null && order.currency.toUpperCase() == 'KHR'
        ? Formatters.moneyKhr(order.amountKhr!)
        : Formatters.moneyUsd(order.amountUsd);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.go('/orders/${Uri.encodeComponent(order.orderNumber)}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _statusColor(context, order.status).withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.receipt_long_rounded, color: _statusColor(context, order.status), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderNumber.isEmpty ? 'Unknown order' : order.orderNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${order.game.name} • ${order.product.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${order.customerLabel} • ${Formatters.dateTimeOrDash(order.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black45),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(amount, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                _StatusPill(status: order.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(BuildContext context, String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
      case 'PROCESSING':
        return Colors.blue;
      case 'DELIVERED':
      case 'COMPLETED':
        return Colors.green;
      case 'FAILED':
      case 'CANCELLED':
      case 'REFUNDED':
        return Colors.red;
      case 'PENDING':
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        Formatters.statusLabel(status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }

  Color _color(BuildContext context) {
    switch (status.toUpperCase()) {
      case 'PAID':
      case 'PROCESSING':
        return Colors.blue;
      case 'DELIVERED':
      case 'COMPLETED':
        return Colors.green;
      case 'FAILED':
      case 'CANCELLED':
      case 'REFUNDED':
        return Colors.red;
      case 'PENDING':
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
}
