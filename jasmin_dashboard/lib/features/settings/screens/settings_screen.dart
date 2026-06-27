import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/layouts/admin_scaffold.dart';
import '../models/settings_payload.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _siteNameController = TextEditingController(text: 'JASMINTOPUP');
  final _exchangeRateController = TextEditingController(text: '4100');
  final _supportTelegramController = TextEditingController();
  final _supportEmailController = TextEditingController();
  final _maintenanceMessageController = TextEditingController();
  final _announcementController = TextEditingController();
  final _logoUrlController = TextEditingController();
  final _logoTextController = TextEditingController();
  final _logoTaglineController = TextEditingController();
  final _telegramBotTokenController = TextEditingController();
  final _telegramChatIdController = TextEditingController();
  bool _maintenanceMode = false;
  String _announcementTone = 'info';
  bool _hydrated = false;

  @override
  void dispose() {
    _siteNameController.dispose();
    _exchangeRateController.dispose();
    _supportTelegramController.dispose();
    _supportEmailController.dispose();
    _maintenanceMessageController.dispose();
    _announcementController.dispose();
    _logoUrlController.dispose();
    _logoTextController.dispose();
    _logoTaglineController.dispose();
    _telegramBotTokenController.dispose();
    _telegramChatIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    if (!_hydrated && !state.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _hydrate(state));
    }

    ref.listen(settingsProvider, (previous, next) {
      final success = next.successMessage;
      if (success != null && success != previous?.successMessage) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(success)));
      }
      final error = next.errorMessage;
      if (error != null &&
          error != previous?.errorMessage &&
          previous?.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error),
            backgroundColor: Theme.of(context).colorScheme.error));
      }
    });

    return AdminScaffold(
      title: 'Settings',
      currentRoute: '/settings',
      actions: [
        IconButton(
          tooltip: 'Reload settings',
          onPressed: state.isSaving
              ? null
              : () async {
                  _hydrated = false;
                  await controller.load();
                },
          icon: const Icon(Icons.refresh_rounded),
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
            _Header(maintenanceMode: _maintenanceMode),
            const SizedBox(height: 16),
            if (state.errorMessage != null)
              _NoticeCard(
                  icon: Icons.error_outline_rounded,
                  title: 'Settings action failed',
                  message: state.errorMessage!,
                  color: Theme.of(context).colorScheme.error),
            if (state.successMessage != null)
              _NoticeCard(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Saved',
                  message: state.successMessage!,
                  color: Colors.green),
            if (state.isLoading)
              const Card(
                  child: SizedBox(
                      height: 260,
                      child: Center(child: CircularProgressIndicator())))
            else
              Form(
                key: _formKey,
                child: LayoutBuilder(builder: (context, constraints) {
                  final twoColumns = constraints.maxWidth >= 900;
                  final general =
                      _FormCard(title: 'General website settings', children: [
                    TextFormField(
                        controller: _siteNameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                            labelText: 'Site name',
                            prefixIcon: Icon(Icons.public_rounded)),
                        validator: _required('Site name')),
                    const SizedBox(height: 14),
                    TextFormField(
                        controller: _exchangeRateController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                        ],
                        decoration: const InputDecoration(
                            labelText: 'USD to KHR exchange rate',
                            prefixIcon: Icon(Icons.currency_exchange_rounded)),
                        validator: _positiveNumber('Exchange rate')),
                    const SizedBox(height: 14),
                    TextFormField(
                        controller: _supportTelegramController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                            labelText: 'Telegram support link/username',
                            hintText: '@jasmintopup or https://t.me/...',
                            prefixIcon: Icon(Icons.send_rounded))),
                    const SizedBox(height: 14),
                    TextFormField(
                        controller: _supportEmailController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                            labelText: 'Support email optional',
                            prefixIcon: Icon(Icons.email_rounded)),
                        validator: _optionalEmail),
                  ]);

                  final publicContent = _FormCard(
                      title: 'Announcement and maintenance',
                      children: [
                        SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Maintenance mode'),
                            subtitle: const Text(
                                'When enabled, customers see the maintenance gate.'),
                            value: _maintenanceMode,
                            onChanged: state.isSaving
                                ? null
                                : (value) =>
                                    setState(() => _maintenanceMode = value)),
                        const SizedBox(height: 14),
                        TextFormField(
                            controller: _maintenanceMessageController,
                            minLines: 2,
                            maxLines: 4,
                            decoration: const InputDecoration(
                                labelText: 'Maintenance message optional',
                                prefixIcon: Icon(Icons.construction_rounded))),
                        const SizedBox(height: 14),
                        TextFormField(
                            controller: _announcementController,
                            minLines: 2,
                            maxLines: 4,
                            decoration: const InputDecoration(
                                labelText: 'Announcement text optional',
                                prefixIcon: Icon(Icons.campaign_rounded))),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _announcementTone,
                          decoration: const InputDecoration(
                              labelText: 'Announcement tone',
                              prefixIcon: Icon(Icons.palette_rounded)),
                          items: const [
                            DropdownMenuItem(
                                value: 'info', child: Text('Info')),
                            DropdownMenuItem(
                                value: 'warning', child: Text('Warning')),
                            DropdownMenuItem(
                                value: 'promo', child: Text('Promo')),
                          ],
                          onChanged: state.isSaving
                              ? null
                              : (value) => setState(
                                  () => _announcementTone = value ?? 'info'),
                        ),
                      ]);

                  final branding = _FormCard(title: 'Branding', children: [
                    TextFormField(
                        controller: _logoUrlController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                            labelText: 'Logo URL/path optional',
                            prefixIcon: Icon(Icons.image_rounded))),
                    const SizedBox(height: 14),
                    TextFormField(
                        controller: _logoTextController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                            labelText: 'Logo text optional',
                            prefixIcon: Icon(Icons.text_fields_rounded))),
                    const SizedBox(height: 14),
                    TextFormField(
                        controller: _logoTaglineController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                            labelText: 'Logo tagline optional',
                            prefixIcon: Icon(Icons.notes_rounded))),
                  ]);

                  final telegram =
                      _FormCard(title: 'Telegram notifications', children: [
                    Text(
                        'Leave the bot token empty to keep the existing masked token. Do not share real tokens in screenshots.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.black54)),
                    const SizedBox(height: 14),
                    TextFormField(
                        controller: _telegramBotTokenController,
                        obscureText: true,
                        decoration: const InputDecoration(
                            labelText: 'New Telegram bot token optional',
                            prefixIcon: Icon(Icons.key_rounded))),
                    const SizedBox(height: 14),
                    TextFormField(
                        controller: _telegramChatIdController,
                        decoration: const InputDecoration(
                            labelText: 'Telegram chat ID optional',
                            prefixIcon: Icon(Icons.chat_rounded))),
                  ]);

                  final cards = [general, publicContent, branding, telegram];
                  return Column(
                    children: [
                      if (twoColumns)
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  child: Column(children: [
                                cards[0],
                                const SizedBox(height: 16),
                                cards[2]
                              ])),
                              const SizedBox(width: 16),
                              Expanded(
                                  child: Column(children: [
                                cards[1],
                                const SizedBox(height: 16),
                                cards[3]
                              ]))
                            ])
                      else
                        for (final card in cards) ...[
                          card,
                          const SizedBox(height: 16)
                        ],
                      const SizedBox(height: 4),
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
                          label: Text(state.isSaving
                              ? 'Saving settings...'
                              : 'Save Settings')),
                      const SizedBox(height: 24),
                    ],
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }

  void _hydrate(SettingsState state) {
    if (_hydrated) {
      return;
    }
    final settings = state.settings;
    if (settings != null) {
      _siteNameController.text = settings.siteName;
      _exchangeRateController.text = settings.exchangeRate.toStringAsFixed(
          settings.exchangeRate.truncateToDouble() == settings.exchangeRate
              ? 0
              : 2);
      _supportTelegramController.text = settings.supportTelegram ?? '';
      _supportEmailController.text = settings.supportEmail ?? '';
      _maintenanceMode = settings.maintenanceMode;
      _maintenanceMessageController.text = settings.maintenanceMessage ?? '';
      _announcementController.text = settings.announcement ?? '';
      _announcementTone = settings.announcementTone == 'warning' ||
              settings.announcementTone == 'promo'
          ? settings.announcementTone!
          : 'info';
      _logoUrlController.text = settings.logoUrl ?? '';
      _logoTextController.text = settings.logoText ?? '';
      _logoTaglineController.text = settings.logoTagline ?? '';
      _telegramBotTokenController.clear();
      _telegramChatIdController.text = settings.telegramChatId ?? '';
    }
    _hydrated = true;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _save(SettingsController controller) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await controller.save(SettingsPayload(
      siteName: _siteNameController.text,
      exchangeRate:
          double.tryParse(_exchangeRateController.text.trim()) ?? 4100,
      supportTelegram: _supportTelegramController.text,
      supportEmail: _supportEmailController.text,
      maintenanceMode: _maintenanceMode,
      maintenanceMessage: _maintenanceMessageController.text,
      announcement: _announcementController.text,
      announcementTone: _announcementTone,
      logoUrl: _logoUrlController.text,
      logoText: _logoTextController.text,
      logoTagline: _logoTaglineController.text,
      telegramBotToken: _telegramBotTokenController.text,
      telegramChatId: _telegramChatIdController.text,
    ));
  }

  String? Function(String?) _required(String label) =>
      (value) => (value?.trim().isEmpty ?? true) ? '$label is required.' : null;
  String? Function(String?) _positiveNumber(String label) => (value) {
        final number = double.tryParse(value?.trim() ?? '');
        if (number == null || number <= 0) {
          return '$label must be greater than 0.';
        }
        return null;
      };
  String? _optionalEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)
        ? null
        : 'Enter a valid email.';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.maintenanceMode});
  final bool maintenanceMode;
  @override
  Widget build(BuildContext context) {
    final color = maintenanceMode ? Colors.orange : Colors.green;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(children: [
          CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(
                  maintenanceMode
                      ? Icons.construction_rounded
                      : Icons.check_circle_rounded,
                  color: color)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Website settings',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                    maintenanceMode
                        ? 'Maintenance mode is currently ON.'
                        : 'Website is currently live.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.black54))
              ])),
        ]),
      ),
    );
  }
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
