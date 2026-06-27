import 'package:flutter/material.dart';

class BannerFiltersBar extends StatelessWidget {
  const BannerFiltersBar({
    super.key,
    required this.selectedActiveFilter,
    required this.onActiveChanged,
  });

  final String selectedActiveFilter;
  final ValueChanged<String> onActiveChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: DropdownButtonFormField<String>(
        initialValue: selectedActiveFilter,
        decoration: const InputDecoration(
          labelText: 'Visibility',
          prefixIcon: Icon(Icons.visibility_rounded),
        ),
        items: const [
          DropdownMenuItem(value: 'ALL', child: Text('All')),
          DropdownMenuItem(value: 'ACTIVE', child: Text('Visible')),
          DropdownMenuItem(value: 'INACTIVE', child: Text('Hidden')),
        ],
        onChanged: (value) {
          if (value != null) {
            onActiveChanged(value);
          }
        },
      ),
    );
  }
}
