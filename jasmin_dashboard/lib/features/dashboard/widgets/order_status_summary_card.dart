import 'package:flutter/material.dart';

import '../models/dashboard_stats.dart';

class OrderStatusSummaryCard extends StatelessWidget {
  const OrderStatusSummaryCard({
    super.key,
    required this.stats,
  });

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final rows = <_StatusRowData>[
      _StatusRowData('Pending', stats.pendingOrders,
          Theme.of(context).colorScheme.primary),
      _StatusRowData('Paid', stats.paidOrders, Colors.blue),
      _StatusRowData('Processing', stats.processingOrders, Colors.indigo),
      _StatusRowData('Completed', stats.completedOrders, Colors.green),
      _StatusRowData('Failed', stats.failedOrders, Colors.red),
      _StatusRowData('Cancelled', stats.cancelledOrders, Colors.orange),
    ];
    final maxValue =
        rows.fold<int>(1, (max, row) => row.value > max ? row.value : max);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order status',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            for (final row in rows) ...[
              _StatusProgressRow(row: row, maxValue: maxValue),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusProgressRow extends StatelessWidget {
  const _StatusProgressRow({required this.row, required this.maxValue});

  final _StatusRowData row;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    final fraction = maxValue == 0 ? 0.0 : row.value / maxValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: Text(row.label,
                    style: Theme.of(context).textTheme.bodyMedium)),
            Text(row.value.toString(),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: fraction.clamp(0.0, 1.0).toDouble(),
            backgroundColor: row.color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(row.color),
          ),
        ),
      ],
    );
  }
}

class _StatusRowData {
  const _StatusRowData(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;
}
