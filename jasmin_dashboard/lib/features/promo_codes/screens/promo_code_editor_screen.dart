import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/layouts/admin_scaffold.dart';
import '../models/promo_code_payload.dart';
import '../providers/promo_codes_provider.dart';

class PromoCodeEditorScreen extends ConsumerStatefulWidget {
  const PromoCodeEditorScreen({super.key, this.promoId});
  final String? promoId;

  @override
  ConsumerState<PromoCodeEditorScreen> createState() =>
      _PromoCodeEditorScreenState();
}

class _PromoCodeEditorScreenState extends ConsumerState<PromoCodeEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _discountValue = TextEditingController();
  final _minOrderUsd = TextEditingController(text: '0');
  final _maxUses = TextEditingController(text: '0');
  final _expiresAt = TextEditingController();
  String _discountType = 'PERCENT';
  bool _active = true;
  bool _initialized = false;

  @override
  void dispose() {
    _code.dispose();
    _discountValue.dispose();
    _minOrderUsd.dispose();
    _maxUses.dispose();
    _expiresAt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = promoCodeEditorProvider(widget.promoId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final code = state.code;

    if (!_initialized && code != null) {
      _initialized = true;
      _code.text = code.code;
      _discountValue.text = code.discountValue
          .toStringAsFixed(code.discountValue % 1 == 0 ? 0 : 2);
      _minOrderUsd.text = code.minOrderUsd.toStringAsFixed(2);
      _maxUses.text = code.maxUses.toString();
      _expiresAt.text =
          code.expiresAt?.toIso8601String().split('T').first ?? '';
      _discountType = code.discountType.toUpperCase();
      _active = code.active;
    }

    ref.listen(provider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error));
      }
      if (next.successMessage != null &&
          next.successMessage != previous?.successMessage) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.successMessage!)));
      }
    });

    final isEditing = widget.promoId != null && widget.promoId!.isNotEmpty;
    return AdminScaffold(
      title: isEditing ? 'Edit Promo Code' : 'New Promo Code',
      currentRoute: '/promo-codes',
      child: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(padding: const EdgeInsets.all(20), children: [
                Card(
                    child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  isEditing
                                      ? 'Update discount rule'
                                      : 'Create discount rule',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w900)),
                              const SizedBox(height: 16),
                              TextFormField(
                                  controller: _code,
                                  decoration: const InputDecoration(
                                      labelText: 'Code',
                                      prefixIcon: Icon(
                                          Icons.confirmation_number_rounded)),
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  validator: (v) => (v == null ||
                                          v.trim().length < 2)
                                      ? 'Code must be at least 2 characters.'
                                      : null),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                  initialValue: _discountType,
                                  decoration: const InputDecoration(
                                      labelText: 'Discount type',
                                      prefixIcon: Icon(Icons.discount_rounded)),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'PERCENT',
                                        child: Text('Percent')),
                                    DropdownMenuItem(
                                        value: 'FIXED',
                                        child: Text('Fixed USD amount'))
                                  ],
                                  onChanged: (v) => setState(
                                      () => _discountType = v ?? 'PERCENT')),
                              const SizedBox(height: 12),
                              TextFormField(
                                  controller: _discountValue,
                                  decoration: InputDecoration(
                                      labelText: _discountType == 'PERCENT'
                                          ? 'Discount percent'
                                          : 'Discount USD',
                                      prefixIcon:
                                          const Icon(Icons.percent_rounded)),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9.]'))
                                  ],
                                  validator: (v) => (double.tryParse(v ?? '') ??
                                              0) <=
                                          0
                                      ? 'Discount value must be greater than 0.'
                                      : null),
                              const SizedBox(height: 12),
                              TextFormField(
                                  controller: _minOrderUsd,
                                  decoration: const InputDecoration(
                                      labelText: 'Minimum order USD',
                                      prefixIcon:
                                          Icon(Icons.attach_money_rounded)),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9.]'))
                                  ]),
                              const SizedBox(height: 12),
                              TextFormField(
                                  controller: _maxUses,
                                  decoration: const InputDecoration(
                                      labelText: 'Usage limit (0 = unlimited)',
                                      prefixIcon: Icon(Icons.repeat_rounded)),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ]),
                              const SizedBox(height: 12),
                              TextFormField(
                                  controller: _expiresAt,
                                  decoration: const InputDecoration(
                                      labelText:
                                          'Expiry date YYYY-MM-DD (optional)',
                                      prefixIcon: Icon(Icons.event_rounded)),
                                  keyboardType: TextInputType.datetime),
                              const SizedBox(height: 12),
                              SwitchListTile(
                                  value: _active,
                                  onChanged: (v) => setState(() => _active = v),
                                  title: const Text('Active'),
                                  subtitle: const Text(
                                      'Inactive promo codes cannot be used on the website.')),
                            ]))),
                const SizedBox(height: 18),
                FilledButton.icon(
                    onPressed: state.isSaving
                        ? null
                        : () => _save(context, controller),
                    icon: state.isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2))
                        : const Icon(Icons.save_rounded),
                    label:
                        Text(isEditing ? 'Save changes' : 'Create promo code')),
                const SizedBox(height: 10),
                TextButton(
                    onPressed: () => context.go('/promo-codes'),
                    child: const Text('Back to Promo Codes')),
              ]),
            ),
    );
  }

  Future<void> _save(
      BuildContext context, PromoCodeEditorController controller) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final expiryText = _expiresAt.text.trim();
    final payload = PromoCodePayload(
      code: _code.text,
      discountType: _discountType,
      discountValue: double.tryParse(_discountValue.text) ?? 0,
      minOrderUsd: double.tryParse(_minOrderUsd.text) ?? 0,
      maxUses: int.tryParse(_maxUses.text) ?? 0,
      expiresAt: expiryText.isEmpty ? null : DateTime.tryParse(expiryText),
      active: _active,
    );
    final result = await controller.save(payload);
    if (result != null && context.mounted) {
      context.go('/promo-codes');
    }
  }
}
