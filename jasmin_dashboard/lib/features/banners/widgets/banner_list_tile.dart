import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../models/banner_model.dart';
import 'banner_status_pill.dart';

class BannerListTile extends StatelessWidget {
  const BannerListTile({
    super.key,
    required this.banner,
    required this.isBusy,
    required this.onToggleActive,
    required this.onDelete,
  });

  final BannerModel banner;
  final bool isBusy;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.go('/banners/${Uri.encodeComponent(banner.id)}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BannerPreview(banner: banner),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            banner.safeTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: 8),
                        BannerStatusPill(active: banner.active, compact: true),
                      ],
                    ),
                    if (banner.subtitle != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        banner.subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.black54),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _MiniInfo(
                            icon: Icons.sort_rounded,
                            label: 'Order ${banner.sortOrder}'),
                        if (banner.hasCta)
                          _MiniInfo(
                              icon: Icons.touch_app_rounded,
                              label: banner.ctaLabel!),
                        if (banner.hasLink)
                          const _MiniInfo(
                              icon: Icons.link_rounded, label: 'Has link'),
                        _MiniInfo(
                            icon: Icons.update_rounded,
                            label: Formatters.dateTimeOrDash(banner.updatedAt)),
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
                  tooltip: 'Banner actions',
                  onSelected: (value) {
                    if (value == 'edit') {
                      context.go('/banners/${Uri.encodeComponent(banner.id)}');
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
                        icon: banner.active
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        label: banner.active
                            ? 'Hide from homepage'
                            : 'Show on homepage',
                      ),
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

class _BannerPreview extends StatelessWidget {
  const _BannerPreview({required this.banner});

  final BannerModel banner;

  @override
  Widget build(BuildContext context) {
    final color =
        banner.active ? Theme.of(context).colorScheme.primary : Colors.black45;
    return Container(
      width: 74,
      height: 54,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: banner.imageUrl.startsWith('http')
          ? Image.network(
              banner.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.view_carousel_rounded, color: color),
            )
          : Icon(Icons.view_carousel_rounded, color: color),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black45),
          const SizedBox(width: 5),
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700, color: Colors.black54)),
        ],
      ),
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
