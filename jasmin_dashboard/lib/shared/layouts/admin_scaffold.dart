import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/sync/providers/app_sync_provider.dart';

class AdminScaffold extends ConsumerWidget {
  const AdminScaffold({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.child,
    this.actions,
  });

  final String title;
  final String currentRoute;
  final Widget child;
  final List<Widget>? actions;

  static const List<_NavItem> _items = [
    _NavItem('/dashboard', Icons.dashboard_rounded, 'Home'),
    _NavItem('/orders', Icons.receipt_long_rounded, 'Orders'),
    _NavItem('/products', Icons.inventory_2_rounded, 'Products'),
    _NavItem('/games', Icons.sports_esports_rounded, 'Games'),
    _NavItem('/settings', Icons.settings_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final showRail = width >= 760;
    final authState = ref.watch(authProvider);
    final syncState = ref.watch(appSyncProvider);
    final admin = authState.admin;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          ...?actions,
          _SyncAction(
            state: syncState,
            onPressed: () {
              ref.read(appSyncProvider.notifier).pollNow();
            },
          ),
          _NotificationBell(count: syncState.unreadNotifications),
          PopupMenuButton<String>(
            tooltip: 'Admin account',
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (value) async {
              if (value == 'logout') {
                final shouldLogout = await _confirmLogout(context);
                if (shouldLogout && context.mounted) {
                  await ref.read(authProvider.notifier).logout();
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        admin?.name?.isNotEmpty == true
                            ? admin!.name!
                            : 'Admin',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(admin?.email ?? 'Admin account'),
                    const SizedBox(height: 2),
                    Text('Role: ${admin?.role ?? 'ADMIN'}'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded),
                    SizedBox(width: 10),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Row(
        children: [
          if (showRail)
            NavigationRail(
              selectedIndex: _selectedIndex,
              labelType: NavigationRailLabelType.all,
              onDestinationSelected: (index) => context.go(_items[index].route),
              destinations: [
                for (final item in _items)
                  NavigationRailDestination(
                    icon: Icon(item.icon),
                    label: Text(item.label),
                  ),
              ],
            ),
          Expanded(child: SafeArea(top: false, child: child)),
        ],
      ),
      bottomNavigationBar: showRail
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => context.go(_items[index].route),
              destinations: [
                for (final item in _items)
                  NavigationDestination(
                      icon: Icon(item.icon), label: item.label),
              ],
            ),
    );
  }

  int get _selectedIndex {
    final index = _items.indexWhere((item) => item.route == currentRoute);
    return index < 0 ? 0 : index;
  }

  Future<bool> _confirmLogout(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Logout?'),
            content: const Text(
                'This will revoke the current admin session and clear the token from secure storage.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Logout')),
            ],
          ),
        ) ??
        false;
  }
}

class _NavItem {
  const _NavItem(this.route, this.icon, this.label);

  final String route;
  final IconData icon;
  final String label;
}

class _SyncAction extends StatelessWidget {
  const _SyncAction({required this.state, required this.onPressed});

  final AppSyncState state;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lastChecked = state.lastWebsiteCheckAt == null
        ? 'Not checked yet'
        : Formatters.shortTime.format(state.lastWebsiteCheckAt!);
    final notice = state.errorMessage ?? state.syncNotice;
    final tooltip = [
      'Auto-update sync',
      'Website check: $lastChecked',
      if (state.pendingWebsiteSyncScope != null)
        'Waiting: ${state.pendingWebsiteSyncScope}',
      if (notice != null && notice.isNotEmpty) notice,
    ].join('\n');

    final icon = state.errorMessage != null
        ? Icons.sync_problem_rounded
        : state.isCheckingWebsite
            ? Icons.sync_rounded
            : state.hasPendingWebsiteSync
                ? Icons.pending_actions_rounded
                : state.hasRecentWebsiteChange
                    ? Icons.cloud_done_rounded
                    : Icons.cloud_sync_rounded;

    final color = state.errorMessage != null
        ? colorScheme.error
        : state.hasPendingWebsiteSync
            ? colorScheme.tertiary
            : colorScheme.primary;

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: state.isCheckingWebsite
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.3, color: color),
            )
          : Icon(icon, color: color),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: count > 0 ? '$count unread notifications' : 'Notifications',
      onPressed: () => context.go('/notifications'),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_none_rounded),
          if (count > 0)
            Positioned(
              right: -7,
              top: -7,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
