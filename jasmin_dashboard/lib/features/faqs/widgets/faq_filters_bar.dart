import 'package:flutter/material.dart';

class FaqFiltersBar extends StatelessWidget {
  const FaqFiltersBar({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.selectedActiveFilter,
    required this.onCategoryChanged,
    required this.onActiveChanged,
  });

  final List<String> categories;
  final String selectedCategory;
  final String selectedActiveFilter;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onActiveChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String>(
            value: selectedCategory,
            decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_rounded)),
            items: [
              const DropdownMenuItem(value: 'ALL', child: Text('All categories')),
              for (final category in categories) DropdownMenuItem(value: category, child: Text(category)),
            ],
            onChanged: (value) {
              if (value != null) onCategoryChanged(value);
            },
          ),
        ),
        SizedBox(
          width: 190,
          child: DropdownButtonFormField<String>(
            value: selectedActiveFilter,
            decoration: const InputDecoration(labelText: 'Visibility', prefixIcon: Icon(Icons.visibility_rounded)),
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
      ],
    );
  }
}
