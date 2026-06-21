import 'package:flutter/material.dart';

import '../models/order_status.dart';

class OrderFiltersBar extends StatelessWidget {
  const OrderFiltersBar({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in OrderStatuses.filters) ...[
            ChoiceChip(
              label: Text(option.label),
              selected: option.value == selectedStatus,
              onSelected: (_) => onStatusChanged(option.value),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
