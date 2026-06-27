import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/faq_model.dart';
import 'faq_status_pill.dart';

class FaqListTile extends StatelessWidget {
  const FaqListTile({
    super.key,
    required this.faq,
    required this.isBusy,
    required this.onToggleActive,
    required this.onDelete,
  });

  final FaqModel faq;
  final bool isBusy;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.go('/faqs/${Uri.encodeComponent(faq.id)}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.12),
                foregroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.help_outline_rounded),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(faq.safeQuestion,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900)),
                        ),
                        const SizedBox(width: 8),
                        FaqStatusPill(active: faq.active, compact: true),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(faq.answer,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.black54)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _MiniInfo(
                            icon: Icons.category_rounded, label: faq.category),
                        _MiniInfo(
                            icon: Icons.sort_rounded,
                            label: 'Order ${faq.sortOrder}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isBusy)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.3)),
                )
              else
                PopupMenuButton<String>(
                  tooltip: 'FAQ actions',
                  onSelected: (value) {
                    if (value == 'edit') {
                      context.go('/faqs/${Uri.encodeComponent(faq.id)}');
                    }
                    if (value == 'toggle') {
                      onToggleActive();
                    }
                    if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: 'edit',
                        child:
                            _MenuRow(icon: Icons.edit_rounded, label: 'Edit')),
                    PopupMenuItem(
                      value: 'toggle',
                      child: _MenuRow(
                          icon: faq.active
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          label: faq.active
                              ? 'Hide from website'
                              : 'Show on website'),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                        value: 'delete',
                        child: _MenuRow(
                            icon: Icons.delete_outline_rounded,
                            label: 'Delete')),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: Colors.black45),
        const SizedBox(width: 5),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(fontWeight: FontWeight.w700, color: Colors.black54))
      ]),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) =>
      Row(children: [Icon(icon), const SizedBox(width: 10), Text(label)]);
}
