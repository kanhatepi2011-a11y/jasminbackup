import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick actions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ActionChip(label: 'Orders', icon: Icons.receipt_long_rounded, onTap: () => context.go('/orders')),
                _ActionChip(label: 'Products', icon: Icons.inventory_2_rounded, onTap: () => context.go('/products')),
                _ActionChip(label: 'Games', icon: Icons.sports_esports_rounded, onTap: () => context.go('/games')),
                _ActionChip(label: 'Banners', icon: Icons.view_carousel_rounded, onTap: () => context.go('/banners')),
                _ActionChip(label: 'Settings', icon: Icons.settings_rounded, onTap: () => context.go('/settings')),
                _ActionChip(label: 'FAQ', icon: Icons.help_outline_rounded, onTap: () => context.go('/faqs')),
                _ActionChip(label: 'Promo Codes', icon: Icons.discount_rounded, onTap: () => context.go('/promo-codes')),
                _ActionChip(label: 'Customers', icon: Icons.people_alt_rounded, onTap: () => context.go('/customers')),
                _ActionChip(label: 'Notifications', icon: Icons.notifications_active_rounded, onTap: () => context.go('/notifications')),
                _ActionChip(label: 'Audit Logs', icon: Icons.history_rounded, onTap: () => context.go('/audit-logs')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
