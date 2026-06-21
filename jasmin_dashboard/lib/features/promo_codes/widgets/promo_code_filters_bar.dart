import 'package:flutter/material.dart';

class PromoCodeFiltersBar extends StatelessWidget {
  const PromoCodeFiltersBar({super.key, required this.activeFilter, required this.typeFilter, required this.onActiveChanged, required this.onTypeChanged});
  final String activeFilter;
  final String typeFilter;
  final ValueChanged<String> onActiveChanged;
  final ValueChanged<String> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _Choice(label: 'All', selected: activeFilter == 'ALL', onTap: () => onActiveChanged('ALL')),
        _Choice(label: 'Usable', selected: activeFilter == 'USABLE', onTap: () => onActiveChanged('USABLE')),
        _Choice(label: 'Active', selected: activeFilter == 'ACTIVE', onTap: () => onActiveChanged('ACTIVE')),
        _Choice(label: 'Disabled', selected: activeFilter == 'INACTIVE', onTap: () => onActiveChanged('INACTIVE')),
        _Choice(label: 'Expired', selected: activeFilter == 'EXPIRED', onTap: () => onActiveChanged('EXPIRED')),
        const SizedBox(width: 8),
        _Choice(label: 'Percent', selected: typeFilter == 'PERCENT', onTap: () => onTypeChanged(typeFilter == 'PERCENT' ? 'ALL' : 'PERCENT')),
        _Choice(label: 'Fixed', selected: typeFilter == 'FIXED', onTap: () => onTypeChanged(typeFilter == 'FIXED' ? 'ALL' : 'FIXED')),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap());
}
