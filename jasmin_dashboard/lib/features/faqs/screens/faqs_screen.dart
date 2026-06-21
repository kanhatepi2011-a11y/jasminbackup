import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/layouts/admin_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/faq_model.dart';
import '../providers/faqs_provider.dart';
import '../widgets/faq_filters_bar.dart';
import '../widgets/faq_list_tile.dart';

class FaqsScreen extends ConsumerStatefulWidget {
  const FaqsScreen({super.key});

  @override
  ConsumerState<FaqsScreen> createState() => _FaqsScreenState();
}

class _FaqsScreenState extends ConsumerState<FaqsScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(faqsProvider);
    final controller = ref.read(faqsProvider.notifier);
    final faqs = state.filteredFaqs;

    ref.listen(faqsProvider, (previous, next) {
      final success = next.successMessage;
      if (success != null && success != previous?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
      }
      final error = next.errorMessage;
      if (error != null && error != previous?.errorMessage && previous?.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Theme.of(context).colorScheme.error));
      }
    });

    return AdminScaffold(
      title: 'FAQ',
      currentRoute: '/faqs',
      actions: [
        IconButton(
          tooltip: 'Refresh FAQ',
          onPressed: state.isRefreshing ? null : () => controller.refresh(),
          icon: state.isRefreshing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2)) : const Icon(Icons.refresh_rounded),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            _Header(total: state.faqs.length, visible: state.faqs.where((faq) => faq.active).length, lastUpdatedAt: state.lastUpdatedAt),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(labelText: 'Search FAQ', hintText: 'Question, answer, category...', prefixIcon: Icon(Icons.search_rounded)),
              onChanged: (value) {
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 250), () => controller.setQuery(value));
              },
            ),
            const SizedBox(height: 12),
            FaqFiltersBar(
              categories: state.categories,
              selectedCategory: state.categoryFilter,
              selectedActiveFilter: state.activeFilter,
              onCategoryChanged: controller.setCategory,
              onActiveChanged: controller.setActiveFilter,
            ),
            const SizedBox(height: 16),
            if (state.errorMessage != null && state.faqs.isEmpty) _ErrorCard(message: state.errorMessage!, onRetry: controller.refresh),
            if (state.isLoading)
              const _LoadingList()
            else if (faqs.isEmpty)
              const EmptyState(icon: Icons.help_outline_rounded, title: 'No FAQ items found', message: 'Create a FAQ item or adjust your filters.')
            else
              for (final faq in faqs)
                FaqListTile(
                  faq: faq,
                  isBusy: state.actionFaqId == faq.id,
                  onToggleActive: () => controller.toggleActive(faq),
                  onDelete: () => _confirmDelete(context, controller, faq),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, FaqsController controller, FaqModel faq) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete FAQ item?'),
            content: Text('This removes “${faq.safeQuestion}” from the FAQ page.'),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete'))],
          ),
        ) ??
        false;
    if (ok) await controller.deleteFaq(faq);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.total, required this.visible, required this.lastUpdatedAt});
  final int total;
  final int visible;
  final DateTime? lastUpdatedAt;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(children: [
          CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12), child: Icon(Icons.help_outline_rounded, color: Theme.of(context).colorScheme.primary)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('FAQ content', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text('$visible visible • $total total • Updated ${Formatters.dateTimeOrDash(lastUpdatedAt)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54))])),
          FilledButton.icon(onPressed: () => context.go('/faqs/new'), icon: const Icon(Icons.add_rounded), label: const Text('New FAQ')),
        ]),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Could not load FAQ', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text(message), const SizedBox(height: 12), FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry'))])));
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();
  @override
  Widget build(BuildContext context) => Column(children: List.generate(4, (index) => const Card(margin: EdgeInsets.only(bottom: 12), child: SizedBox(height: 110, child: Center(child: CircularProgressIndicator())))));
}
