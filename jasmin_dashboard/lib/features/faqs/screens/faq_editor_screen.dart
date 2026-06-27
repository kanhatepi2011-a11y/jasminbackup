import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/layouts/admin_scaffold.dart';
import '../models/faq_payload.dart';
import '../providers/faqs_provider.dart';

class FaqEditorScreen extends ConsumerStatefulWidget {
  const FaqEditorScreen({super.key, this.faqId});

  final String? faqId;
  bool get isEditing => faqId != null && faqId!.trim().isNotEmpty;

  @override
  ConsumerState<FaqEditorScreen> createState() => _FaqEditorScreenState();
}

class _FaqEditorScreenState extends ConsumerState<FaqEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  final _categoryController = TextEditingController(text: 'general');
  final _sortOrderController = TextEditingController(text: '0');
  bool _active = true;
  bool _hydrated = false;

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    _categoryController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final faqId = widget.isEditing ? widget.faqId! : null;
    final provider = faqEditorProvider(faqId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    if (!_hydrated && !state.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _hydrate(state));
    }

    return AdminScaffold(
      title: widget.isEditing ? 'Edit FAQ' : 'Create FAQ',
      currentRoute: '/faqs',
      actions: [
        IconButton(
            tooltip: 'Back to FAQ',
            onPressed: () => context.go('/faqs'),
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
            Row(children: [
              IconButton.filledTonal(
                  tooltip: 'Back',
                  onPressed: () => context.go('/faqs'),
                  icon: const Icon(Icons.arrow_back_rounded)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(widget.isEditing ? 'Edit FAQ' : 'Create FAQ',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(
                        'FAQ changes are saved through secure admin API and reflected on the public FAQ page automatically.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.black54))
                  ])),
            ]),
            const SizedBox(height: 16),
            if (state.errorMessage != null)
              _NoticeCard(
                  icon: Icons.error_outline_rounded,
                  title: 'FAQ action failed',
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
                child: _FormCard(title: 'FAQ item', children: [
                  TextFormField(
                      controller: _questionController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(
                          labelText: 'Question',
                          prefixIcon: Icon(Icons.question_answer_rounded)),
                      validator: _required('Question')),
                  const SizedBox(height: 14),
                  TextFormField(
                      controller: _answerController,
                      minLines: 5,
                      maxLines: 10,
                      decoration: const InputDecoration(
                          labelText: 'Answer',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.article_rounded)),
                      validator: _required('Answer')),
                  const SizedBox(height: 14),
                  TextFormField(
                      controller: _categoryController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                          labelText: 'Category',
                          hintText: 'general, payment, order...',
                          prefixIcon: Icon(Icons.category_rounded)),
                      validator: _required('Category')),
                  const SizedBox(height: 14),
                  TextFormField(
                      controller: _sortOrderController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                          labelText: 'Display order',
                          prefixIcon: Icon(Icons.sort_rounded)),
                      validator: _positiveOrZeroInt('Display order')),
                  const SizedBox(height: 14),
                  SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Visible on FAQ page'),
                      subtitle: const Text(
                          'Hidden FAQ items are not shown publicly.'),
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
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save_rounded),
                      label: Text(state.isSaving ? 'Saving...' : 'Save FAQ')),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  void _hydrate(FaqEditorState state) {
    if (_hydrated) {
      return;
    }
    final faq = state.faq;
    if (faq != null) {
      _questionController.text = faq.question;
      _answerController.text = faq.answer;
      _categoryController.text = faq.category;
      _sortOrderController.text = faq.sortOrder.toString();
      _active = faq.active;
    }
    _hydrated = true;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _save(FaqEditorController controller) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final result = await controller.save(FaqPayload(
        question: _questionController.text,
        answer: _answerController.text,
        category: _categoryController.text,
        active: _active,
        sortOrder: int.tryParse(_sortOrderController.text.trim()) ?? 0));
    if (result != null && mounted) {
      context.go('/faqs');
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
