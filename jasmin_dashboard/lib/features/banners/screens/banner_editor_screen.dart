import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/layouts/admin_scaffold.dart';
import '../models/banner_payload.dart';
import '../providers/banners_provider.dart';

class BannerEditorScreen extends ConsumerStatefulWidget {
  const BannerEditorScreen({super.key, this.bannerId});

  final String? bannerId;
  bool get isEditing => bannerId != null && bannerId!.trim().isNotEmpty;

  @override
  ConsumerState<BannerEditorScreen> createState() => _BannerEditorScreenState();
}

class _BannerEditorScreenState extends ConsumerState<BannerEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _linkUrlController = TextEditingController();
  final _ctaLabelController = TextEditingController();
  final _sortOrderController = TextEditingController(text: '0');
  bool _active = true;
  bool _hydrated = false;

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _imageUrlController.dispose();
    _linkUrlController.dispose();
    _ctaLabelController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bannerId = widget.isEditing ? widget.bannerId! : null;
    final provider = bannerEditorProvider(bannerId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    if (!_hydrated && !state.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _hydrate(state));
    }

    return AdminScaffold(
      title: widget.isEditing ? 'Edit Banner' : 'Create Banner',
      currentRoute: '/banners',
      actions: [
        IconButton(
            tooltip: 'Back to banners',
            onPressed: () => context.go('/banners'),
            icon: const Icon(Icons.close_rounded))
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
                    tooltip: 'Back',
                    onPressed: () => context.go('/banners'),
                    icon: const Icon(Icons.arrow_back_rounded)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.isEditing ? 'Edit banner' : 'Create banner',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(
                            'Homepage banner changes are saved through the secure admin API and reflected on JASMINTOPUP automatically.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.black54)),
                      ]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.errorMessage != null)
              _NoticeCard(
                  icon: Icons.error_outline_rounded,
                  title: 'Banner action failed',
                  message: state.errorMessage!,
                  color: Theme.of(context).colorScheme.error),
            if (state.successMessage != null)
              _NoticeCard(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Saved',
                  message: state.successMessage!,
                  color: Colors.green),
            if (state.isLoading)
              const _EditorLoading()
            else
              Form(
                key: _formKey,
                child: _FormCard(
                  title: 'Banner details',
                  children: [
                    TextFormField(
                        controller: _titleController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                            labelText: 'Title',
                            prefixIcon: Icon(Icons.title_rounded)),
                        validator: _required('Title')),
                    const SizedBox(height: 14),
                    TextFormField(
                        controller: _subtitleController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(
                            labelText: 'Subtitle optional',
                            prefixIcon: Icon(Icons.short_text_rounded))),
                    const SizedBox(height: 14),
                    TextFormField(
                        controller: _imageUrlController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                            labelText: 'Image URL/path',
                            hintText: '/uploads/banner.png or https://...',
                            prefixIcon: Icon(Icons.image_rounded)),
                        validator: _required('Image URL')),
                    const SizedBox(height: 14),
                    TextFormField(
                        controller: _linkUrlController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                            labelText: 'Link URL optional',
                            prefixIcon: Icon(Icons.link_rounded))),
                    const SizedBox(height: 14),
                    TextFormField(
                        controller: _ctaLabelController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                            labelText: 'CTA label optional',
                            hintText: 'Shop now',
                            prefixIcon: Icon(Icons.touch_app_rounded))),
                    const SizedBox(height: 14),
                    TextFormField(
                        controller: _sortOrderController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: const InputDecoration(
                            labelText: 'Display order',
                            prefixIcon: Icon(Icons.sort_rounded)),
                        validator: _positiveOrZeroInt('Display order')),
                    const SizedBox(height: 14),
                    SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Visible on homepage'),
                        subtitle: const Text(
                            'Disabled banners are hidden from the public homepage.'),
                        value: _active,
                        onChanged: state.isSaving
                            ? null
                            : (value) => setState(() => _active = value)),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                        onPressed:
                            state.isSaving ? null : () => _save(controller),
                        icon: state.isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.save_rounded),
                        label:
                            Text(state.isSaving ? 'Saving...' : 'Save Banner')),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _hydrate(BannerEditorState state) {
    if (_hydrated) {
      return;
    }
    final banner = state.banner;
    if (banner != null) {
      _titleController.text = banner.title;
      _subtitleController.text = banner.subtitle ?? '';
      _imageUrlController.text = banner.imageUrl;
      _linkUrlController.text = banner.linkUrl ?? '';
      _ctaLabelController.text = banner.ctaLabel ?? '';
      _sortOrderController.text = banner.sortOrder.toString();
      _active = banner.active;
    }
    _hydrated = true;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _save(BannerEditorController controller) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final result = await controller.save(BannerPayload(
      title: _titleController.text,
      subtitle: _subtitleController.text,
      imageUrl: _imageUrlController.text,
      linkUrl: _linkUrlController.text,
      ctaLabel: _ctaLabelController.text,
      active: _active,
      sortOrder: int.tryParse(_sortOrderController.text.trim()) ?? 0,
    ));
    if (result != null && mounted) {
      context.go('/banners');
    }
  }

  String? Function(String?) _required(String label) =>
      (value) => (value?.trim().isEmpty ?? true) ? '$label is required.' : null;
  String? Function(String?) _positiveOrZeroInt(String label) => (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) {
          return '$label is required.';
        }
        final number = int.tryParse(text);
        if (number == null || number < 0) {
          return '$label must be 0 or higher.';
        }
        return null;
      };
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            ...children
          ])));
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard(
      {required this.icon,
      required this.title,
      required this.message,
      required this.color});
  final IconData icon;
  final String title;
  final String message;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  Text(message)
                ]))
          ])));
}

class _EditorLoading extends StatelessWidget {
  const _EditorLoading();
  @override
  Widget build(BuildContext context) => const Card(
      child: SizedBox(
          height: 260, child: Center(child: CircularProgressIndicator())));
}
