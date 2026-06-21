import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/layouts/admin_scaffold.dart';
import '../models/product_game_summary.dart';
import '../models/product_payload.dart';
import '../providers/products_provider.dart';
import '../widgets/product_status_pill.dart';

class ProductEditorScreen extends ConsumerStatefulWidget {
  const ProductEditorScreen({
    super.key,
    this.productId,
  });

  final String? productId;

  bool get isEditing => productId != null && productId!.trim().isNotEmpty;

  @override
  ConsumerState<ProductEditorScreen> createState() => _ProductEditorScreenState();
}

class _ProductEditorScreenState extends ConsumerState<ProductEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController(text: '0');
  final _bonusController = TextEditingController(text: '0');
  final _priceUsdController = TextEditingController();
  final _priceKhrController = TextEditingController();
  final _badgeController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _supplierCodeController = TextEditingController();
  final _sortOrderController = TextEditingController(text: '0');

  String? _selectedGameId;
  bool _active = true;
  bool _hydrated = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _bonusController.dispose();
    _priceUsdController.dispose();
    _priceKhrController.dispose();
    _badgeController.dispose();
    _imageUrlController.dispose();
    _supplierCodeController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productId = widget.productId == null ? null : Uri.decodeComponent(widget.productId!);
    final provider = productEditorProvider(productId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    if (!_hydrated && !state.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _hydrate(state));
    }

    return AdminScaffold(
      title: widget.isEditing ? 'Edit Package' : 'Create Package',
      currentRoute: '/products',
      actions: [
        IconButton(
          tooltip: 'Back to products',
          onPressed: () => context.go('/products'),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: () async {
          _hydrated = false;
          await controller.load();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Back to products',
                  onPressed: () => context.go('/products'),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isEditing ? 'Edit package' : 'Create package',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Changes are saved through the secure admin API and reflected on JASMINTOPUP automatically.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.errorMessage != null)
              _NoticeCard(
                icon: Icons.error_outline_rounded,
                title: 'Product action failed',
                message: state.errorMessage!,
                color: Theme.of(context).colorScheme.error,
              ),
            if (state.successMessage != null)
              _NoticeCard(
                icon: Icons.check_circle_outline_rounded,
                title: 'Saved',
                message: state.successMessage!,
                color: Colors.green,
              ),
            if (state.isLoading)
              const _EditorLoading()
            else if (state.games.isEmpty)
              const _NoticeCard(
                icon: Icons.sports_esports_rounded,
                title: 'No games available',
                message: 'Create at least one game before creating packages.',
                color: Colors.orange,
              )
            else
              Form(
                key: _formKey,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final twoColumns = constraints.maxWidth >= 860;
                    final form = _FormCard(
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedGameId != null && state.games.any((game) => game.id == _selectedGameId) ? _selectedGameId : null,
                          decoration: const InputDecoration(
                            labelText: 'Game association',
                            prefixIcon: Icon(Icons.sports_esports_rounded),
                          ),
                          items: [
                            for (final game in state.games)
                              DropdownMenuItem(
                                value: game.id,
                                child: Text(game.active ? game.name : '${game.name} · disabled'),
                              ),
                          ],
                          validator: (value) => value == null || value.trim().isEmpty ? 'Please choose a game.' : null,
                          onChanged: state.isSaving ? null : (value) => setState(() => _selectedGameId = value),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Package name',
                            hintText: 'Weekly Pass, 86 Diamonds, 560 Shells...',
                            prefixIcon: Icon(Icons.inventory_2_rounded),
                          ),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Package name is required.' : null,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: const InputDecoration(labelText: 'Amount', prefixIcon: Icon(Icons.numbers_rounded)),
                                validator: (value) => _positiveOrZeroInt(value, 'Amount'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _bonusController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: const InputDecoration(labelText: 'Bonus', prefixIcon: Icon(Icons.add_circle_outline_rounded)),
                                validator: (value) => _positiveOrZeroInt(value, 'Bonus'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _priceUsdController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Price USD', prefixIcon: Icon(Icons.attach_money_rounded)),
                                validator: (value) => _positiveDouble(value, 'Price USD'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _priceKhrController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Price KHR optional', prefixIcon: Icon(Icons.payments_rounded)),
                                validator: (value) => _optionalPositiveDouble(value, 'Price KHR'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );

                    final meta = _FormCard(
                      children: [
                        SwitchListTile.adaptive(
                          value: _active,
                          onChanged: state.isSaving ? null : (value) => setState(() => _active = value),
                          title: const Text('Visible on website'),
                          subtitle: const Text('Turn off to hide this package from customers.'),
                          secondary: ProductStatusPill(active: _active),
                        ),
                        const Divider(height: 28),
                        TextFormField(
                          controller: _sortOrderController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'-?\d*'))],
                          decoration: const InputDecoration(labelText: 'Display order', prefixIcon: Icon(Icons.sort_rounded)),
                          validator: (value) => _intRequired(value, 'Display order'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _badgeController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'Badge optional', hintText: 'Hot, Best value, Sale...', prefixIcon: Icon(Icons.local_offer_rounded)),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _supplierCodeController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'Supplier code optional', prefixIcon: Icon(Icons.qr_code_2_rounded)),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _imageUrlController,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(labelText: 'Image URL optional', prefixIcon: Icon(Icons.image_rounded)),
                        ),
                      ],
                    );

                    if (!twoColumns) {
                      return Column(
                        children: [form, const SizedBox(height: 16), meta, const SizedBox(height: 16), _SaveButton(isSaving: state.isSaving, onPressed: () => _submit(controller))],
                      );
                    }
                    return Column(
                      children: [
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: form), const SizedBox(width: 16), Expanded(child: meta)]),
                        const SizedBox(height: 16),
                        _SaveButton(isSaving: state.isSaving, onPressed: () => _submit(controller)),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _hydrate(ProductEditorState state) {
    if (!mounted || _hydrated) return;
    final product = state.product;
    setState(() {
      if (product != null) {
        _selectedGameId = product.gameId;
        _nameController.text = product.name;
        _amountController.text = product.amount.toString();
        _bonusController.text = product.bonus.toString();
        _priceUsdController.text = product.priceUsd == 0 ? '' : product.priceUsd.toStringAsFixed(2);
        _priceKhrController.text = product.priceKhr == null ? '' : product.priceKhr!.toStringAsFixed(0);
        _badgeController.text = product.badge ?? '';
        _imageUrlController.text = product.imageUrl ?? '';
        _supplierCodeController.text = product.supplierCode ?? '';
        _sortOrderController.text = product.sortOrder.toString();
        _active = product.active;
      } else {
        ProductGameSummary? activeGame;
        for (final game in state.games) {
          if (game.active) {
            activeGame = game;
            break;
          }
        }
        _selectedGameId = activeGame?.id ?? (state.games.isNotEmpty ? state.games.first.id : null);
      }
      _hydrated = true;
    });
  }

  Future<void> _submit(ProductEditorController controller) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGameId == null || _selectedGameId!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please choose a game.')));
      return;
    }

    final payload = ProductPayload(
      gameId: _selectedGameId!,
      name: _nameController.text.trim(),
      amount: int.parse(_amountController.text.trim()),
      bonus: int.parse(_bonusController.text.trim()),
      priceUsd: double.parse(_priceUsdController.text.trim()),
      priceKhr: _priceKhrController.text.trim().isEmpty ? null : double.parse(_priceKhrController.text.trim()),
      badge: _emptyToNull(_badgeController.text),
      imageUrl: _emptyToNull(_imageUrlController.text),
      active: _active,
      sortOrder: int.parse(_sortOrderController.text.trim()),
      supplierCode: _emptyToNull(_supplierCodeController.text),
    );

    final result = await controller.save(payload);
    if (result == null || !mounted) return;
    ref.invalidate(productsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.isEditing ? 'Package updated. Website will refresh shortly.' : 'Package created. Website will refresh shortly.')),
    );
    context.go('/products');
  }

  String? _emptyToNull(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  String? _positiveOrZeroInt(String? value, String label) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null) return '$label must be a number.';
    if (parsed < 0) return '$label cannot be negative.';
    return null;
  }

  String? _intRequired(String? value, String label) {
    if (int.tryParse(value?.trim() ?? '') == null) return '$label must be a number.';
    return null;
  }

  String? _positiveDouble(String? value, String label) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null) return '$label must be a number.';
    if (parsed <= 0) return '$label must be greater than 0.';
    return null;
  }

  String? _optionalPositiveDouble(String? value, String label) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null) return '$label must be a number.';
    if (parsed <= 0) return '$label must be greater than 0.';
    return null;
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.isSaving, required this.onPressed});

  final bool isSaving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: isSaving ? null : onPressed,
        icon: isSaving
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2))
            : const Icon(Icons.save_rounded),
        label: Text(isSaving ? 'Saving package...' : 'Save package'),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.icon, required this.title, required this.message, required this.color});

  final IconData icon;
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorLoading extends StatelessWidget {
  const _EditorLoading();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.3)),
            const SizedBox(width: 14),
            Text('Loading package editor...', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
