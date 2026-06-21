import 'package:flutter/material.dart';

import '../models/promo_code_model.dart';

class PromoCodeStatusPill extends StatelessWidget {
  const PromoCodeStatusPill({super.key, required this.code});
  final PromoCodeModel code;

  @override
  Widget build(BuildContext context) {
    final MaterialColor color;
    final String label;
    if (!code.active) {
      color = Colors.grey;
      label = 'Disabled';
    } else if (code.isExpired) {
      color = Colors.orange;
      label = 'Expired';
    } else if (code.isFullyUsed) {
      color = Colors.red;
      label = 'Used up';
    } else {
      color = Colors.green;
      label = 'Usable';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: color.shade700, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}
