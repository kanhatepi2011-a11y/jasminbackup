import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../models/audit_log_model.dart';

class AuditLogTile extends StatelessWidget {
  const AuditLogTile({super.key, required this.log});
  final AuditLogModel log;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: CircleAvatar(
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            foregroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.history_rounded)),
        title: Text(log.action,
            style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(
            '${log.adminEmail ?? 'Unknown admin'} • ${Formatters.dateTimeOrDash(log.createdAt)}'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _Row(
              label: 'Target',
              value: [log.targetType, log.targetId]
                  .where((v) => v != null && v.isNotEmpty)
                  .join(' / ')),
          _Row(label: 'IP', value: log.ipAddress ?? '—'),
          _Row(label: 'User agent', value: log.userAgent ?? '—'),
          if (log.details != null) _Row(label: 'Details', value: log.details!),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Colors.black54, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        SelectableText(value.isEmpty ? '—' : value)
      ]));
}
