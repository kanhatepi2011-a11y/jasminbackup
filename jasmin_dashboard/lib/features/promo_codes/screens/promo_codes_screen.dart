import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/layouts/admin_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/promo_code_model.dart';
import '../providers/promo_codes_provider.dart';
import '../widgets/promo_code_filters_bar.dart';
import '../widgets/promo_code_list_tile.dart';

class PromoCodesScreen extends ConsumerStatefulWidget {
  const PromoCodesScreen({super.key});

  @override
  ConsumerState<PromoCodesScreen> createState() => _PromoCodesScreenState();
}

class _PromoCodesScreenState extends ConsumerState<PromoCodesScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() { _debounce?.cancel(); _searchController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(promoCodesProvider);
    final controller = ref.read(promoCodesProvider.notifier);
    final codes = state.filteredCodes;

    ref.listen(promoCodesProvider, (previous, next) {
      if (next.successMessage != null && next.successMessage != previous?.successMessage) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.successMessage!)));
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage && previous?.errorMessage != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.errorMessage!), backgroundColor: Theme.of(context).colorScheme.error));
    });

    return AdminScaffold(
      title: 'Promo Codes',
      currentRoute: '/promo-codes',
      actions: [
        IconButton(tooltip: 'Refresh promo codes', onPressed: state.isRefreshing ? null : controller.refresh, icon: state.isRefreshing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.3)) : const Icon(Icons.refresh_rounded)),
        IconButton.filledTonal(tooltip: 'Create promo code', onPressed: () => context.go('/promo-codes/new'), icon: const Icon(Icons.add_rounded)),
      ],
      child: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            _Header(total: state.codes.length, usable: state.codes.where((c) => c.canBeUsed).length, lastUpdatedAt: state.lastUpdatedAt),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(hintText: 'Search code, type, discount, minimum order...', prefixIcon: const Icon(Icons.search_rounded), suffixIcon: _searchController.text.isEmpty ? null : IconButton(icon: const Icon(Icons.close_rounded), onPressed: () { _searchController.clear(); controller.setQuery(''); setState(() {}); })),
              onChanged: (value) { setState(() {}); _debounce?.cancel(); _debounce = Timer(const Duration(milliseconds: 250), () => controller.setQuery(value)); },
            ),
            const SizedBox(height: 12),
            PromoCodeFiltersBar(activeFilter: state.activeFilter, typeFilter: state.typeFilter, onActiveChanged: controller.setActiveFilter, onTypeChanged: controller.setTypeFilter),
            const SizedBox(height: 16),
            if (state.errorMessage != null && state.codes.isEmpty) _ErrorCard(message: state.errorMessage!, onRetry: controller.refresh),
            if (state.isLoading)
              const _LoadingList()
            else if (codes.isEmpty)
              const EmptyState(icon: Icons.discount_rounded, title: 'No promo codes found', message: 'Create a promo code or adjust your filters.')
            else
              for (final code in codes) PromoCodeListTile(code: code, isBusy: state.actionCodeId == code.id, onToggleActive: () => controller.toggleActive(code), onDelete: () => _confirmDelete(context, controller, code)),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, PromoCodesController controller, PromoCodeModel code) async {
    final ok = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Delete promo code?'), content: Text('If “${code.code}” has existing orders, backend will disable it instead of deleting it.'), actions: [TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete / disable'))])) ?? false;
    if (ok) await controller.deletePromoCode(code);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.total, required this.usable, required this.lastUpdatedAt});
  final int total;
  final int usable;
  final DateTime? lastUpdatedAt;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12), child: Icon(Icons.discount_rounded, color: Theme.of(context).colorScheme.primary)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Promo code controls', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text('$usable usable • $total total • Updated ${Formatters.dateTimeOrDash(lastUpdatedAt)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54))])), FilledButton.icon(onPressed: () => context.go('/promo-codes/new'), icon: const Icon(Icons.add_rounded), label: const Text('New'))])));
}

class _ErrorCard extends StatelessWidget { const _ErrorCard({required this.message, required this.onRetry}); final String message; final VoidCallback onRetry; @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Could not load promo codes', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text(message), const SizedBox(height: 12), FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry'))]))); }
class _LoadingList extends StatelessWidget { const _LoadingList(); @override Widget build(BuildContext context) => Column(children: List.generate(4, (_) => const Card(margin: EdgeInsets.only(bottom: 12), child: SizedBox(height: 112, child: Center(child: CircularProgressIndicator()))))); }
