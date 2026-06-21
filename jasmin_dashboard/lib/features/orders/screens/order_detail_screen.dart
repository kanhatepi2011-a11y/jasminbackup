import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/layouts/admin_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/order_model.dart';
import '../models/order_status.dart';
import '../providers/order_detail_provider.dart';
import '../providers/orders_provider.dart';
import '../widgets/order_status_pill.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({
    super.key,
    required this.orderNumber,
  });

  final String orderNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decodedOrderNumber = Uri.decodeComponent(orderNumber);
    final state = ref.watch(orderDetailProvider(decodedOrderNumber));
    final controller = ref.read(orderDetailProvider(decodedOrderNumber).notifier);
    final order = state.order;

    ref.listen(orderDetailProvider(decodedOrderNumber), (previous, next) {
      final success = next.successMessage;
      if (success != null && success != previous?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
        ref.invalidate(ordersProvider);
      }
    });

    return AdminScaffold(
      title: 'Order Detail',
      currentRoute: '/orders',
      actions: [
        IconButton(
          tooltip: 'Refresh order',
          onPressed: state.isRefreshing ? null : () => controller.load(silent: true),
          icon: state.isRefreshing
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.3))
              : const Icon(Icons.refresh_rounded),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: () => controller.load(silent: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Back to orders',
                  onPressed: () => context.go('/orders'),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    decodedOrderNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.errorMessage != null)
              _NoticeCard(
                icon: Icons.error_outline_rounded,
                title: 'Order action failed',
                message: state.errorMessage!,
                color: Theme.of(context).colorScheme.error,
              ),
            if (state.isLoading && order == null)
              const _DetailLoading()
            else if (order == null)
              const EmptyState(
                icon: Icons.receipt_long_rounded,
                title: 'Order not found',
                message: 'This order may have been deleted or the order number is invalid.',
              )
            else ...[
              _OrderSummaryCard(
                order: order,
                isSaving: state.isSaving,
                onCopy: () => _copyOrderNumber(context, order.orderNumber),
                onUpdate: () async {
                  final result = await showDialog<_OrderUpdateResult>(
                    context: context,
                    builder: (context) => _UpdateOrderDialog(order: order),
                  );
                  if (result == null) return;
                  await controller.updateOrder(
                    status: result.status,
                    deliveryNote: result.deliveryNote,
                    failureReason: result.failureReason,
                    adminNote: result.adminNote,
                  );
                },
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final twoColumns = constraints.maxWidth >= 860;
                  final left = _OrderCustomerCard(order: order);
                  final right = _OrderPaymentCard(order: order);
                  if (!twoColumns) {
                    return Column(children: [left, const SizedBox(height: 16), right]);
                  }
                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: left), const SizedBox(width: 16), Expanded(child: right)]);
                },
              ),
              const SizedBox(height: 16),
              _OrderNotesCard(order: order),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _copyOrderNumber(BuildContext context, String orderNumber) async {
    await Clipboard.setData(ClipboardData(text: orderNumber));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order number copied.')));
    }
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.order,
    required this.isSaving,
    required this.onCopy,
    required this.onUpdate,
  });

  final OrderModel order;
  final bool isSaving;
  final VoidCallback onCopy;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final amount = order.amountKhr != null && order.currency.toUpperCase() == 'KHR'
        ? Formatters.moneyKhr(order.amountKhr!)
        : Formatters.moneyUsd(order.amountUsd);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.orderNumber, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OrderStatusPill(status: order.status),
                          _SoftChip(icon: Icons.payments_rounded, label: amount),
                          _SoftChip(icon: Icons.schedule_rounded, label: Formatters.dateTimeOrDash(order.createdAt)),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(onPressed: onCopy, tooltip: 'Copy order number', icon: const Icon(Icons.copy_rounded)),
              ],
            ),
            const SizedBox(height: 18),
            _InfoRow(label: 'Game', value: order.game.name),
            _InfoRow(label: 'Package', value: order.product.name),
            _InfoRow(label: 'Player UID', value: order.uidLabel),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isSaving ? null : onUpdate,
                icon: isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2))
                    : const Icon(Icons.edit_note_rounded),
                label: Text(isSaving ? 'Saving...' : 'Update status / notes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCustomerCard extends StatelessWidget {
  const _OrderCustomerCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.person_rounded,
      title: 'Customer',
      children: [
        _InfoRow(label: 'Name / nickname', value: order.playerNickname ?? '—'),
        _InfoRow(label: 'Email', value: order.customerEmail ?? '—'),
        _InfoRow(label: 'Phone', value: order.customerPhone ?? '—'),
        _InfoRow(label: 'UID', value: order.uidLabel),
      ],
    );
  }
}

class _OrderPaymentCard extends StatelessWidget {
  const _OrderPaymentCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Payment / timeline',
      children: [
        _InfoRow(label: 'Payment method', value: order.paymentMethod.isEmpty ? '—' : order.paymentMethod),
        _InfoRow(label: 'Payment ref', value: order.paymentRef ?? '—'),
        _InfoRow(label: 'Created', value: Formatters.dateTimeOrDash(order.createdAt)),
        _InfoRow(label: 'Paid at', value: Formatters.dateTimeOrDash(order.paidAt)),
        _InfoRow(label: 'Delivered at', value: Formatters.dateTimeOrDash(order.deliveredAt)),
        _InfoRow(label: 'Last update', value: Formatters.dateTimeOrDash(order.updatedAt)),
      ],
    );
  }
}

class _OrderNotesCard extends StatelessWidget {
  const _OrderNotesCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.notes_rounded,
      title: 'Delivery / failure notes',
      children: [
        _BlockText(label: 'Delivery note', value: order.deliveryNote),
        const SizedBox(height: 12),
        _BlockText(label: 'Failure reason', value: order.failureReason),
        const SizedBox(height: 12),
        Text(
          'Admin note entered during updates is saved to audit logs only. It is not shown to customers.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black45),
        ),
      ],
    );
  }
}

class _UpdateOrderDialog extends StatefulWidget {
  const _UpdateOrderDialog({required this.order});

  final OrderModel order;

  @override
  State<_UpdateOrderDialog> createState() => _UpdateOrderDialogState();
}

class _UpdateOrderDialogState extends State<_UpdateOrderDialog> {
  late String _status;
  late final TextEditingController _deliveryNoteController;
  late final TextEditingController _failureReasonController;
  final TextEditingController _adminNoteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _status = widget.order.status.toUpperCase() == 'COMPLETED' ? 'DELIVERED' : widget.order.status.toUpperCase();
    _deliveryNoteController = TextEditingController(text: widget.order.deliveryNote ?? '');
    _failureReasonController = TextEditingController(text: widget.order.failureReason ?? '');
  }

  @override
  void dispose() {
    _deliveryNoteController.dispose();
    _failureReasonController.dispose();
    _adminNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update order'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.order.orderNumber, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                for (final option in OrderStatuses.editable) DropdownMenuItem(value: option.value, child: Text(option.label)),
              ],
              onChanged: (value) => setState(() => _status = value ?? _status),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _deliveryNoteController,
              maxLines: 3,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'Delivery note',
                hintText: 'Visible/usable delivery note for completed orders',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _failureReasonController,
              maxLines: 3,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'Failure reason',
                hintText: 'Reason when order failed/cancelled/refunded',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _adminNoteController,
              maxLines: 3,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'Admin note',
                hintText: 'Audit-only note, not shown to customers',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Payment-sensitive status changes should only be used after you verify the real transaction/order manually.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              _OrderUpdateResult(
                status: _status,
                deliveryNote: _deliveryNoteController.text,
                failureReason: _failureReasonController.text,
                adminNote: _adminNoteController.text,
              ),
            );
          },
          child: const Text('Save update'),
        ),
      ],
    );
  }
}

class _OrderUpdateResult {
  const _OrderUpdateResult({required this.status, required this.deliveryNote, required this.failureReason, required this.adminNote});

  final String status;
  final String deliveryNote;
  final String failureReason;
  final String adminNote;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.icon, required this.title, required this.children});

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black45, fontWeight: FontWeight.w800)),
          ),
          Expanded(
            child: Text(value.isEmpty ? '—' : value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _BlockText extends StatelessWidget {
  const _BlockText({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black45, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.035),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(value == null || value!.trim().isEmpty ? '—' : value!.trim()),
        ),
      ],
    );
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.045),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.black45),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.icon, required this.title, required this.message, required this.color});

  final IconData icon;
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(message),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailLoading extends StatelessWidget {
  const _DetailLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 18, width: 180, decoration: BoxDecoration(color: Colors.black.withOpacity(0.06), borderRadius: BorderRadius.circular(999))),
                const SizedBox(height: 16),
                Container(height: 12, width: double.infinity, decoration: BoxDecoration(color: Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(999))),
                const SizedBox(height: 10),
                Container(height: 12, width: 240, decoration: BoxDecoration(color: Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(999))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
