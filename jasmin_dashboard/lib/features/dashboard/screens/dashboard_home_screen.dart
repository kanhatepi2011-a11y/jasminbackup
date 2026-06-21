import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/layouts/admin_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/dashboard_stats.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_error_card.dart';
import '../widgets/dashboard_quick_actions.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/order_status_summary_card.dart';
import '../widgets/recent_orders_card.dart';
import '../widgets/system_status_card.dart';

class DashboardHomeScreen extends ConsumerWidget {
  const DashboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final dashboardState = ref.watch(dashboardProvider);
    final admin = authState.admin;
    final data = dashboardState.data;
    final stats = data?.stats ?? DashboardStats.empty();

    return AdminScaffold(
      title: 'Dashboard',
      currentRoute: '/dashboard',
      actions: [
        _RefreshAction(isRefreshing: dashboardState.isRefreshing, onPressed: () => ref.read(dashboardProvider.notifier).refresh()),
      ],
      child: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome${admin?.name != null ? ', ${admin!.name}' : ''}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        admin?.email ?? 'Admin account',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                      ),
                      if (dashboardState.lastUpdatedAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Last updated ${Formatters.shortTime.format(dashboardState.lastUpdatedAt!)} • auto-refresh every 20s',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black45),
                        ),
                      ],
                    ],
                  ),
                ),
                if (dashboardState.isRefreshing)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            if (dashboardState.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DashboardErrorCard(
                  message: dashboardState.errorMessage!,
                  onRetry: () => ref.read(dashboardProvider.notifier).refresh(),
                ),
              ),
            if (dashboardState.isLoading && !dashboardState.hasData)
              const _DashboardLoading()
            else if (data == null)
              EmptyState(
                icon: Icons.dashboard_customize_rounded,
                title: 'Dashboard unavailable',
                message: 'Login is working, but the dashboard API did not return data yet.',
              )
            else ...[
              _StatsGrid(stats: stats),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final twoColumns = constraints.maxWidth >= 900;
                  if (!twoColumns) {
                    return Column(
                      children: [
                        RecentOrdersCard(orders: data.recentOrders),
                        const SizedBox(height: 20),
                        OrderStatusSummaryCard(stats: stats),
                        const SizedBox(height: 20),
                        SystemStatusCard(status: data.systemStatus),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: RecentOrdersCard(orders: data.recentOrders)),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            OrderStatusSummaryCard(stats: stats),
                            const SizedBox(height: 20),
                            SystemStatusCard(status: data.systemStatus),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              const DashboardQuickActions(),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1100
            ? 4
            : width >= 720
                ? 3
                : 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: width < 430 ? 1.08 : 1.28,
          children: [
            DashboardStatCard(
              title: 'Total orders',
              value: Formatters.number(stats.totalOrders),
              subtitle: '${stats.newOrdersToday} new today',
              badge: '${stats.openOrders} open',
              icon: Icons.receipt_long_rounded,
              onTap: () => context.go('/orders'),
            ),
            DashboardStatCard(
              title: 'Today revenue',
              value: Formatters.moneyUsd(stats.todayRevenueUsd),
              subtitle: Formatters.moneyKhr(stats.todayRevenueKhr),
              icon: Icons.payments_rounded,
            ),
            DashboardStatCard(
              title: 'Customers',
              value: Formatters.number(stats.totalCustomers),
              subtitle: 'Unique order identities',
              icon: Icons.groups_rounded,
              onTap: () => context.go('/customers'),
            ),
            DashboardStatCard(
              title: 'Notifications',
              value: Formatters.number(stats.unreadNotifications),
              subtitle: 'Unread admin alerts',
              icon: Icons.notifications_active_rounded,
              onTap: () => context.go('/notifications'),
            ),
            DashboardStatCard(
              title: 'Products',
              value: '${stats.activeProducts}/${stats.totalProducts}',
              subtitle: '${stats.inactiveProducts < 0 ? 0 : stats.inactiveProducts} disabled',
              icon: Icons.inventory_2_rounded,
              onTap: () => context.go('/products'),
            ),
            DashboardStatCard(
              title: 'Games',
              value: '${stats.activeGames}/${stats.totalGames}',
              subtitle: '${stats.inactiveGames < 0 ? 0 : stats.inactiveGames} disabled',
              icon: Icons.sports_esports_rounded,
              onTap: () => context.go('/games'),
            ),
            DashboardStatCard(
              title: 'Completed',
              value: Formatters.number(stats.completedOrders),
              subtitle: 'Delivered orders',
              icon: Icons.verified_rounded,
              onTap: () => context.go('/orders'),
            ),
            DashboardStatCard(
              title: 'Failed / cancelled',
              value: Formatters.number(stats.failedOrders + stats.cancelledOrders),
              subtitle: 'Needs review if high',
              icon: Icons.report_problem_rounded,
              onTap: () => context.go('/orders'),
            ),
          ],
        );
      },
    );
  }
}

class _RefreshAction extends StatelessWidget {
  const _RefreshAction({required this.isRefreshing, required this.onPressed});

  final bool isRefreshing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Refresh dashboard',
      onPressed: isRefreshing ? null : onPressed,
      icon: isRefreshing
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4))
          : const Icon(Icons.refresh_rounded),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width > 760 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.28,
          children: List.generate(8, (_) => const _SkeletonCard()),
        ),
        const SizedBox(height: 20),
        const _SkeletonPanel(),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 44, height: 44, decoration: _box(context, radius: 16)),
            const Spacer(),
            Container(width: 90, height: 12, decoration: _box(context)),
            const SizedBox(height: 10),
            Container(width: 120, height: 24, decoration: _box(context)),
          ],
        ),
      ),
    );
  }
}

class _SkeletonPanel extends StatelessWidget {
  const _SkeletonPanel();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: List.generate(
            5,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(width: 42, height: 42, decoration: _box(context, radius: 16)),
                  const SizedBox(width: 12),
                  Expanded(child: Container(height: 14, decoration: _box(context))),
                  const SizedBox(width: 12),
                  Container(width: 60, height: 14, decoration: _box(context)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

BoxDecoration _box(BuildContext context, {double radius = 999}) {
  return BoxDecoration(
    color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
    borderRadius: BorderRadius.circular(radius),
  );
}
