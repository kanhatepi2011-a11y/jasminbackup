import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../models/product_model.dart';
import 'product_status_pill.dart';

class ProductListTile extends StatelessWidget {
  const ProductListTile({
    super.key,
    required this.product,
    required this.isBusy,
    required this.onToggleActive,
    required this.onDelete,
  });

  final ProductModel product;
  final bool isBusy;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.go('/products/${Uri.encodeComponent(product.id)}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProductAvatar(product: product),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name.isEmpty
                                ? 'Untitled package'
                                : product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ProductStatusPill(
                            active: product.active, compact: true),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${product.game.name} • ${product.amountLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.supplierCode == null
                          ? 'No supplier code'
                          : 'Supplier code: ${product.supplierCode}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _MiniInfo(
                            icon: Icons.attach_money_rounded,
                            label: Formatters.moneyUsd(product.priceUsd)),
                        if (product.priceKhr != null)
                          _MiniInfo(
                              icon: Icons.payments_rounded,
                              label: Formatters.moneyKhr(product.priceKhr!)),
                        _MiniInfo(
                            icon: Icons.sort_rounded,
                            label: 'Order ${product.sortOrder}'),
                        if (product.badge != null)
                          _MiniInfo(
                              icon: Icons.local_offer_rounded,
                              label: product.badge!),
                        if (product.hasOrders)
                          _MiniInfo(
                              icon: Icons.receipt_long_rounded,
                              label: '${product.ordersCount} orders'),
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
                  tooltip: 'Product actions',
                  onSelected: (value) {
                    if (value == 'edit') {
                      context
                          .go('/products/${Uri.encodeComponent(product.id)}');
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
                        icon: product.active
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        label: product.active
                            ? 'Hide from website'
                            : 'Show on website',
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                        value: 'delete',
                        child: _MenuRow(
                            icon: Icons.delete_outline_rounded,
                            label: 'Delete safely')),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductAvatar extends StatelessWidget {
  const _ProductAvatar({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final color =
        product.active ? Theme.of(context).colorScheme.primary : Colors.black45;
    final imageUrl = product.imageUrl;
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl == null || !imageUrl.startsWith('http')
          ? Icon(Icons.inventory_2_rounded, color: color)
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.inventory_2_rounded, color: color),
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
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black45),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(fontWeight: FontWeight.w700, color: Colors.black54),
          ),
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
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }
}
