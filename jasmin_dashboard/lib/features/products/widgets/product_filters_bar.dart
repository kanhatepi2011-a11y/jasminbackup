import 'package:flutter/material.dart';

import '../models/product_game_summary.dart';

class ProductFiltersBar extends StatelessWidget {
  const ProductFiltersBar({
    super.key,
    required this.games,
    required this.selectedGameId,
    required this.selectedActiveFilter,
    required this.onGameChanged,
    required this.onActiveChanged,
  });

  final List<ProductGameSummary> games;
  final String selectedGameId;
  final String selectedActiveFilter;
  final ValueChanged<String> onGameChanged;
  final ValueChanged<String> onActiveChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        SizedBox(
          width: 260,
          child: DropdownButtonFormField<String>(
            value: selectedGameId,
            decoration: const InputDecoration(
              labelText: 'Game',
              prefixIcon: Icon(Icons.sports_esports_rounded),
            ),
            items: [
              const DropdownMenuItem(value: 'ALL', child: Text('All games')),
              for (final game in games)
                DropdownMenuItem(
                  value: game.id,
                  child: Text(game.active ? game.name : '${game.name} · disabled'),
                ),
            ],
            onChanged: (value) {
              if (value != null) onGameChanged(value);
            },
          ),
        ),
        SizedBox(
          width: 190,
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
      ],
    );
  }
}
