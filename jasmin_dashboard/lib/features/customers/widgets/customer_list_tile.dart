import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../models/customer_summary_model.dart';

class CustomerListTile extends StatelessWidget {
  const CustomerListTile({super.key, required this.customer});
  final CustomerSummaryModel customer;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.go('/customers/${Uri.encodeComponent(customer.key)}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12), foregroundColor: Theme.of(context).colorScheme.primary, child: const Icon(Icons.person_rounded)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(customer.displayName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(customer.subtitle.isEmpty ? customer.key : customer.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 6, children: [
                _MiniInfo(icon: Icons.receipt_long_rounded, label: '${customer.totalOrders} orders'),
                _MiniInfo(icon: Icons.check_circle_rounded, label: '${customer.paidOrders} paid'),
                _MiniInfo(icon: Icons.attach_money_rounded, label: Formatters.moneyUsd(customer.lifetimeUsd)),
                _MiniInfo(icon: Icons.sports_esports_rounded, label: '${customer.uidCount} UID'),
              ]),
            ])),
            const Icon(Icons.chevron_right_rounded),
          ]),
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget { const _MiniInfo({required this.icon, required this.label}); final IconData icon; final String label; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(999)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: Colors.black45), const SizedBox(width: 5), Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: Colors.black54))])); }
