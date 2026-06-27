import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';

class OrderStatusPill extends StatelessWidget {
  const OrderStatusPill({
    super.key,
    required this.status,
    this.compact = false,
  });

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = colorFor(context, status);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10, vertical: compact ? 4 : 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Text(
        Formatters.statusLabel(status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }

  static Color colorFor(BuildContext context, String status) {
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
