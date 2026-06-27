import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/layouts/admin_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/audit_logs_provider.dart';
import '../widgets/audit_log_tile.dart';

class AuditLogsScreen extends ConsumerStatefulWidget {
  const AuditLogsScreen({super.key});
  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  final _action = TextEditingController();
  final _adminEmail = TextEditingController();
  Timer? _debounce;
  String _targetType = 'ALL';

  @override
  void dispose() {
    _debounce?.cancel();
    _action.dispose();
    _adminEmail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(auditLogsProvider);
    final controller = ref.read(auditLogsProvider.notifier);
    return AdminScaffold(
      title: 'Audit Logs',
      currentRoute: '/audit-logs',
      actions: [
        IconButton(
            tooltip: 'Refresh audit logs',
            onPressed: state.isLoading ? null : controller.refresh,
            icon: const Icon(Icons.refresh_rounded))
      ],
      child: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              _Header(
                  total: state.total,
                  shown: state.logs.length,
                  lastUpdatedAt: state.lastUpdatedAt),
              const SizedBox(height: 16),
              _Filters(
                  action: _action,
                  adminEmail: _adminEmail,
                  targetType: _targetType,
                  onTargetChanged: (v) {
                    setState(() => _targetType = v);
                    controller.applyFilters(targetType: v);
                  },
                  onChanged: () {
                    _debounce?.cancel();
                    _debounce = Timer(
                        const Duration(milliseconds: 350),
                        () => controller.applyFilters(
                            action: _action.text,
                            adminEmail: _adminEmail.text));
                  }),
              const SizedBox(height: 16),
              if (state.errorMessage != null && state.logs.isEmpty)
                _ErrorCard(
                    message: state.errorMessage!, onRetry: controller.refresh),
              if (state.isLoading)
                const _LoadingList()
              else if (state.logs.isEmpty)
                const EmptyState(
                    icon: Icons.history_rounded,
                    title: 'No audit logs found',
                    message:
                        'Try different filters or check admin activity later.')
              else
                for (final log in state.logs) AuditLogTile(log: log),
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
                child: Icon(Icons.history_rounded,
                    color: Theme.of(context).colorScheme.primary)),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Admin activity trail',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(
                      '$shown loaded • $total total • Updated ${Formatters.dateTimeOrDash(lastUpdatedAt)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.black54))
                ]))
          ])));
}

class _Filters extends StatelessWidget {
  const _Filters(
      {required this.action,
      required this.adminEmail,
      required this.targetType,
      required this.onTargetChanged,
      required this.onChanged});
  final TextEditingController action;
  final TextEditingController adminEmail;
  final String targetType;
  final ValueChanged<String> onTargetChanged;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            TextField(
                controller: action,
                decoration: const InputDecoration(
                    labelText: 'Action contains',
                    prefixIcon: Icon(Icons.search_rounded)),
                onChanged: (_) => onChanged()),
            const SizedBox(height: 10),
            TextField(
                controller: adminEmail,
                decoration: const InputDecoration(
                    labelText: 'Admin email contains',
                    prefixIcon: Icon(Icons.alternate_email_rounded)),
                onChanged: (_) => onChanged()),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
                initialValue: targetType,
                decoration: const InputDecoration(
                    labelText: 'Target type',
                    prefixIcon: Icon(Icons.category_rounded)),
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('All')),
                  DropdownMenuItem(value: 'order', child: Text('Order')),
                  DropdownMenuItem(value: 'product', child: Text('Product')),
                  DropdownMenuItem(value: 'game', child: Text('Game')),
                  DropdownMenuItem(value: 'settings', child: Text('Settings')),
                  DropdownMenuItem(
                      value: 'promo_code', child: Text('Promo code')),
                  DropdownMenuItem(value: 'customer', child: Text('Customer'))
                ],
                onChanged: (v) => onTargetChanged(v ?? 'ALL'))
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
            Text('Could not load audit logs',
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
                  height: 88,
                  child: Center(child: CircularProgressIndicator())))));
}
