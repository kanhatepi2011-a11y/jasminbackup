class OrderStatusOption {
  const OrderStatusOption(this.value, this.label);

  final String value;
  final String label;
}

class OrderStatuses {
  const OrderStatuses._();

  static const List<OrderStatusOption> filters = [
    OrderStatusOption('ALL', 'All'),
    OrderStatusOption('PENDING', 'Pending'),
    OrderStatusOption('PAID', 'Paid'),
    OrderStatusOption('PROCESSING', 'Processing'),
    OrderStatusOption('DELIVERED', 'Completed'),
    OrderStatusOption('FAILED', 'Failed'),
    OrderStatusOption('CANCELLED', 'Cancelled'),
  ];

  static const List<OrderStatusOption> editable = [
    OrderStatusOption('PENDING', 'Pending'),
    OrderStatusOption('PAID', 'Paid'),
    OrderStatusOption('PROCESSING', 'Processing'),
    OrderStatusOption('DELIVERED', 'Completed'),
    OrderStatusOption('FAILED', 'Failed'),
    OrderStatusOption('CANCELLED', 'Cancelled'),
    OrderStatusOption('REFUNDED', 'Refunded'),
  ];
}
