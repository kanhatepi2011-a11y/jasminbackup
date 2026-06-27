import 'package:flutter/material.dart';

class GameStatusPill extends StatelessWidget {
  const GameStatusPill({
    super.key,
    required this.active,
    this.featured = false,
    this.compact = false,
  });

  final bool active;
  final bool featured;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.green : Colors.black45;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _Pill(
          icon:
              active ? Icons.visibility_rounded : Icons.visibility_off_rounded,
          label: active ? 'Visible' : 'Hidden',
          color: color,
          compact: compact,
        ),
        if (featured)
          _Pill(
            icon: Icons.star_rounded,
            label: 'Featured',
            color: Colors.orange,
            compact: compact,
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(
      {required this.icon,
      required this.label,
      required this.color,
      required this.compact});

  final IconData icon;
  final String label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10, vertical: compact ? 4 : 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 13 : 15, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
