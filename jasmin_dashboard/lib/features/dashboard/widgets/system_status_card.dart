import 'package:flutter/material.dart';

import '../models/system_status.dart';

class SystemStatusCard extends StatelessWidget {
  const SystemStatusCard({
    super.key,
    required this.status,
  });

  final SystemStatus status;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('System status', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            _StatusTile(label: 'Database', value: status.database),
            const SizedBox(height: 10),
            _StatusTile(label: 'API', value: status.api),
            const SizedBox(height: 10),
            _StatusTile(label: 'Auth', value: status.auth),
          ],
        ),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ok = value.toLowerCase() == 'ok';
    final color = ok ? Colors.green : Colors.orange;

    return Row(
      children: [
        Icon(ok ? Icons.check_circle_rounded : Icons.warning_rounded, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
        Text(
          ok ? 'OK' : value.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}
