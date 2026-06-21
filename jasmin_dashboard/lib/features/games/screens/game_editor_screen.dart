import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/layouts/admin_scaffold.dart';
import '../models/game_payload.dart';
import '../providers/games_provider.dart';
import '../widgets/game_status_pill.dart';

class GameEditorScreen extends ConsumerStatefulWidget {
  const GameEditorScreen({super.key, this.gameId});

  final String? gameId;

  bool get isEditing => gameId != null && gameId!.trim().isNotEmpty;

  @override
  ConsumerState<GameEditorScreen> createState() => _GameEditorScreenState();
}

class _GameEditorScreenState extends ConsumerState<GameEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _slugController = TextEditingController();
  final _nameController = TextEditingController();
  final _publisherController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _bannerUrlController = TextEditingController();
  final _currencyNameController = TextEditingController(text: 'Diamonds');
  final _uidLabelController = TextEditingController(text: 'Player ID');
  final _uidExampleController = TextEditingController();
  final _serversController = TextEditingController(text: '[]');
  final _sortOrderController = TextEditingController(text: '0');
  final _seoTitleController = TextEditingController();
  final _seoDescriptionController = TextEditingController();

  bool _active = true;
  bool _featured = false;
  bool _requiresServer = false;
  bool _hydrated = false;

  @override
  void dispose() {
    _slugController.dispose();
    _nameController.dispose();
    _publisherController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _bannerUrlController.dispose();
    _currencyNameController.dispose();
    _uidLabelController.dispose();
    _uidExampleController.dispose();
    _serversController.dispose();
    _sortOrderController.dispose();
    _seoTitleController.dispose();
    _seoDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameId = widget.gameId == null ? null : Uri.decodeComponent(widget.gameId!);
    final provider = gameEditorProvider(gameId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    if (!_hydrated && !state.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _hydrate(state));
    }

    return AdminScaffold(
      title: widget.isEditing ? 'Edit Game' : 'Create Game',
      currentRoute: '/games',
      actions: [
        IconButton(
          tooltip: 'Back to games',
          onPressed: () => context.go('/games'),
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
                  tooltip: 'Back to games',
                  onPressed: () => context.go('/games'),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isEditing ? 'Edit game' : 'Create game',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Game changes are saved through the secure admin API and reflected on JASMINTOPUP automatically.',
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
                title: 'Game action failed',
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
            else
              Form(
                key: _formKey,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final twoColumns = constraints.maxWidth >= 900;
                    final main = _FormCard(
                      title: 'Game identity',
                      children: [
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'Game name', hintText: 'Mobile Legends', prefixIcon: Icon(Icons.sports_esports_rounded)),
                          validator: _required('Game name'),
                          onChanged: (value) {
                            if (!widget.isEditing && _slugController.text.trim().isEmpty) {
                              _slugController.text = _slugFromName(value);
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _slugController,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9-]'))],
                          decoration: const InputDecoration(labelText: 'Slug', hintText: 'mobile-legends', prefixIcon: Icon(Icons.link_rounded)),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.length < 2) return 'Slug must be at least 2 characters.';
                            if (!RegExp(r'^[a-z0-9-]+$').hasMatch(text)) return 'Use lowercase letters, numbers, and hyphens only.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _publisherController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Publisher / category label',
                            hintText: 'Garena, HoYoverse, Tencent...',
                            prefixIcon: Icon(Icons.business_rounded),
                          ),
                          validator: _required('Publisher'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _descriptionController,
                          minLines: 3,
                          maxLines: 5,
                          decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description_rounded)),
                        ),
                      ],
                    );

                    final media = _FormCard(
                      title: 'Media and display',
                      children: [
                        TextFormField(
                          controller: _imageUrlController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'Game image URL/path', hintText: '/uploads/game.png or https://...', prefixIcon: Icon(Icons.image_rounded)),
                          validator: _required('Game image'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _bannerUrlController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'Banner URL/path optional', prefixIcon: Icon(Icons.panorama_rounded)),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _sortOrderController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(labelText: 'Display order', prefixIcon: Icon(Icons.sort_rounded)),
                          validator: _positiveOrZeroInt('Display order'),
                        ),
                        const SizedBox(height: 14),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Visible on website'),
                          subtitle: const Text('Disabled games are hidden from public pages.'),
                          value: _active,
                          onChanged: state.isSaving ? null : (value) => setState(() => _active = value),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Featured game'),
                          subtitle: const Text('Used by homepage/highlight sections when supported.'),
                          value: _featured,
                          onChanged: state.isSaving ? null : (value) => setState(() => _featured = value),
                        ),
                      ],
                    );

                    final player = _FormCard(
                      title: 'Player fields',
                      children: [
                        TextFormField(
                          controller: _currencyNameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'Currency name', hintText: 'Diamonds, Shells, UC...', prefixIcon: Icon(Icons.paid_rounded)),
                          validator: _required('Currency name'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _uidLabelController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'UID label', hintText: 'Player ID', prefixIcon: Icon(Icons.badge_rounded)),
                          validator: _required('UID label'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _uidExampleController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'UID example optional', prefixIcon: Icon(Icons.info_outline_rounded)),
                        ),
                        const SizedBox(height: 14),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Requires server/zone'),
                          subtitle: const Text('Enable for games that need server ID or zone ID.'),
                          value: _requiresServer,
                          onChanged: state.isSaving ? null : (value) => setState(() => _requiresServer = value),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _serversController,
                          minLines: 3,
                          maxLines: 8,
                          decoration: const InputDecoration(
                            labelText: 'Servers JSON',
                            hintText: '[{"id":"1001","name":"Server 1"}]',
                            prefixIcon: Icon(Icons.dns_rounded),
                          ),
                          validator: _serversJson,
                        ),
                      ],
                    );

                    final seo = _FormCard(
                      title: 'SEO optional',
                      children: [
                        TextFormField(
                          controller: _seoTitleController,
                          decoration: const InputDecoration(labelText: 'SEO title', prefixIcon: Icon(Icons.title_rounded)),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _seoDescriptionController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(labelText: 'SEO description', prefixIcon: Icon(Icons.search_rounded)),
                        ),
                        const SizedBox(height: 16),
                        GameStatusPill(active: _active, featured: _featured),
                      ],
                    );

                    return Column(
                      children: [
                        if (twoColumns)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: main),
                              const SizedBox(width: 16),
                              Expanded(child: media),
                            ],
                          )
                        else ...[
                          main,
                          const SizedBox(height: 16),
                          media,
                        ],
                        const SizedBox(height: 16),
                        if (twoColumns)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: player),
                              const SizedBox(width: 16),
                              Expanded(child: seo),
                            ],
                          )
                        else ...[
                          player,
                          const SizedBox(height: 16),
                          seo,
                        ],
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: state.isSaving ? null : () => context.go('/games'),
                                icon: const Icon(Icons.arrow_back_rounded),
                                label: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: state.isSaving ? null : () => _save(controller),
                                icon: state.isSaving
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2))
                                    : const Icon(Icons.save_rounded),
                                label: Text(state.isSaving ? 'Saving...' : 'Save game'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 80),
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

  void _hydrate(GameEditorState state) {
    if (!mounted || _hydrated) return;
    final game = state.game;
    if (game != null) {
      _slugController.text = game.slug;
      _nameController.text = game.name;
      _publisherController.text = game.publisher;
      _descriptionController.text = game.description ?? '';
      _imageUrlController.text = game.imageUrl;
      _bannerUrlController.text = game.bannerUrl ?? '';
      _currencyNameController.text = game.currencyName;
      _uidLabelController.text = game.uidLabel;
      _uidExampleController.text = game.uidExample ?? '';
      _serversController.text = game.servers.trim().isEmpty ? '[]' : game.servers;
      _sortOrderController.text = game.sortOrder.toString();
      _seoTitleController.text = game.seoTitle ?? '';
      _seoDescriptionController.text = game.seoDescription ?? '';
      _active = game.active;
      _featured = game.featured;
      _requiresServer = game.requiresServer;
    }
    setState(() => _hydrated = true);
  }

  Future<void> _save(GameEditorController controller) async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final payload = GamePayload(
      slug: _slugController.text,
      name: _nameController.text,
      publisher: _publisherController.text,
      description: _descriptionController.text,
      imageUrl: _imageUrlController.text,
      bannerUrl: _bannerUrlController.text,
      currencyName: _currencyNameController.text,
      uidLabel: _uidLabelController.text,
      uidExample: _uidExampleController.text,
      requiresServer: _requiresServer,
      servers: _serversController.text,
      featured: _featured,
      active: _active,
      sortOrder: int.tryParse(_sortOrderController.text.trim()) ?? 0,
      seoTitle: _seoTitleController.text,
      seoDescription: _seoDescriptionController.text,
    );

    final result = await controller.save(payload);
    if (result != null && mounted) {
      _hydrated = false;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Game saved. Website will refresh shortly.')));
      context.go('/games');
    }
  }

  FormFieldValidator<String> _required(String label) {
    return (value) => value == null || value.trim().isEmpty ? '$label is required.' : null;
  }

  FormFieldValidator<String> _positiveOrZeroInt(String label) {
    return (value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) return '$label is required.';
      final number = int.tryParse(text);
      if (number == null || number < 0) return '$label must be 0 or higher.';
      return null;
    };
  }

  String? _serversJson(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    try {
      final decoded = jsonDecode(text);
      if (decoded is! List) return 'Servers must be a JSON array.';
    } catch (_) {
      return 'Servers must be valid JSON, for example: []';
    }
    return null;
  }

  String _slugFromName(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
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
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          children: List.generate(
            6,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                height: 18,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.06), borderRadius: BorderRadius.circular(999)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
