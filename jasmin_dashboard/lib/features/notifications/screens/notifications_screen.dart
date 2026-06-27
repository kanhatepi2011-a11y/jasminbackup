import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/layouts/admin_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/notifications_provider.dart';
import '../widgets/notification_tile.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    final controller = ref.read(notificationsProvider.notifier);

    ref.listen(notificationsProvider, (previous, next) {
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

    return AdminScaffold(
      title: 'Notifications',
      currentRoute: '/notifications',
      actions: [
        IconButton(
            tooltip: 'Refresh notifications',
            onPressed: state.isRefreshing ? null : controller.refresh,
            icon: state.isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2))
                : const Icon(Icons.refresh_rounded)),
        IconButton.filledTonal(
            tooltip: 'Mark all read',
            onPressed: state.isBulkBusy || state.unreadCount == 0
                ? null
                : controller.markAllRead,
            icon: state.isBulkBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2))
                : const Icon(Icons.done_all_rounded)),
      ],
      child: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              _Header(
                  total: state.total,
                  unread: state.unreadCount,
                  lastUpdatedAt: state.lastUpdatedAt),
              const SizedBox(height: 12),
              Row(children: [
                ChoiceChip(
                    label: const Text('All'),
                    selected: !state.unreadOnly,
                    onSelected: (_) => controller.setUnreadOnly(false)),
                const SizedBox(width: 8),
                ChoiceChip(
                    label: const Text('Unread only'),
                    selected: state.unreadOnly,
                    onSelected: (_) => controller.setUnreadOnly(true))
              ]),
              const SizedBox(height: 16),
              if (state.errorMessage != null && state.notifications.isEmpty)
                _ErrorCard(
                    message: state.errorMessage!, onRetry: controller.refresh),
              if (state.isLoading)
                const _LoadingList()
              else if (state.notifications.isEmpty)
                const EmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: 'No notifications',
                    message:
                        'New order and admin system notifications will appear here.')
              else
                for (final item in state.notifications)
                  NotificationTile(
                      notification: item,
                      isBusy: state.actionNotificationId == item.id,
                      onToggleRead: () => controller.toggleRead(item)),
              if (state.canLoadMore)
                Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: FilledButton.tonalIcon(
                        onPressed: state.isLoadingMore
                            ? null
                            : () => controller.load(),
                        icon: state.isLoadingMore
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.expand_more_rounded),
                        label: const Text('Load more'))),
            ]),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(
      {required this.total, required this.unread, required this.lastUpdatedAt});
  final int total;
  final int unread;
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
                child: Icon(Icons.notifications_rounded,
                    color: Theme.of(context).colorScheme.primary)),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Admin notifications',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(
                      '$unread unread • $total total • Updated ${Formatters.dateTimeOrDash(lastUpdatedAt)}',
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
            Text('Could not load notifications',
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
          5,
          (_) => const Card(
              margin: EdgeInsets.only(bottom: 10),
              child: SizedBox(
                  height: 92,
                  child: Center(child: CircularProgressIndicator())))));
}
