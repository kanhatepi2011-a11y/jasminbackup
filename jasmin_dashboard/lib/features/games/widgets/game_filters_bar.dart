import 'package:flutter/material.dart';

class GameFiltersBar extends StatelessWidget {
  const GameFiltersBar({
    super.key,
    required this.selectedActiveFilter,
    required this.selectedFeaturedFilter,
    required this.onActiveChanged,
    required this.onFeaturedChanged,
  });

  final String selectedActiveFilter;
  final String selectedFeaturedFilter;
  final ValueChanged<String> onActiveChanged;
  final ValueChanged<String> onFeaturedChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<String>(
            value: selectedActiveFilter,
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
              if (value != null) onActiveChanged(value);
            },
          ),
        ),
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<String>(
            value: selectedFeaturedFilter,
            decoration: const InputDecoration(
              labelText: 'Featured',
              prefixIcon: Icon(Icons.star_rounded),
            ),
            items: const [
              DropdownMenuItem(value: 'ALL', child: Text('All')),
              DropdownMenuItem(value: 'FEATURED', child: Text('Featured')),
              DropdownMenuItem(value: 'NORMAL', child: Text('Normal')),
            ],
            onChanged: (value) {
              if (value != null) onFeaturedChanged(value);
            },
          ),
        ),
      ],
    );
  }
}
