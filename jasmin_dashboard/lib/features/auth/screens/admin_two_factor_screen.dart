import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/jasmin_logo.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_message_banner.dart';

class AdminTwoFactorScreen extends ConsumerStatefulWidget {
  const AdminTwoFactorScreen({super.key});

  @override
  ConsumerState<AdminTwoFactorScreen> createState() => _AdminTwoFactorScreenState();
}

class _AdminTwoFactorScreenState extends ConsumerState<AdminTwoFactorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _codeFocusNode = FocusNode();
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final remaining = _remainingText(authState.challengeExpiresAt);

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: JasminLogo(size: 82)),
                        const SizedBox(height: 20),
                        Text(
                          'Google Authenticator',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          authState.loginEmail == null
                              ? 'Enter the 6-digit code from your authenticator app.'
                              : 'Enter the 6-digit code for ${authState.loginEmail}.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        _ChallengeTimerCard(remainingText: remaining),
                        if (authState.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          AuthMessageBanner(message: authState.errorMessage!, type: AuthMessageType.error),
                        ],
                        if (authState.infoMessage != null) ...[
                          const SizedBox(height: 16),
                          AuthMessageBanner(message: authState.infoMessage!, type: AuthMessageType.info),
                        ],
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _codeController,
                          focusNode: _codeFocusNode,
                          enabled: !authState.isLoading,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 6,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 8, fontWeight: FontWeight.w800),
                          decoration: const InputDecoration(
                            counterText: '',
                            labelText: '2FA code',
                            prefixIcon: Icon(Icons.password_rounded),
                          ),
                          validator: _validateCode,
                          onFieldSubmitted: (_) => _verify(),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 22),
                        FilledButton.icon(
                          onPressed: authState.isLoading ? null : _verify,
                          icon: authState.isLoading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.login_rounded),
                          label: Text(authState.isLoading ? 'Verifying...' : 'Verify and enter dashboard'),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: authState.isLoading
                              ? null
                              : () => ref.read(authProvider.notifier).resetToLogin(
                                    message: 'Start a new secure login challenge.',
                                  ),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Use a different admin login'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Never share your Google Authenticator code. JASMIN_DASHBOARD will never ask for your TOTP secret.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateCode(String? value) {
    final code = value?.trim() ?? '';
    if (code.isEmpty) return '2FA code is required.';
    if (!RegExp(r'^\d{6}$').hasMatch(code)) return 'Enter exactly 6 digits.';
    return null;
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).verifyTwoFactor(_codeController.text);
    if (!success) {
      _codeController.clear();
      if (mounted) {
        _codeFocusNode.requestFocus();
      }
    }
  }

  String _remainingText(DateTime? expiresAt) {
    if (expiresAt == null) return 'Challenge expires soon';
    final remaining = expiresAt.difference(DateTime.now().toUtc());
    if (remaining.isNegative) return 'Expired';
    final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _ChallengeTimerCard extends StatelessWidget {
  const _ChallengeTimerCard({required this.remainingText});

  final String remainingText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Temporary 2FA challenge expires in',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            remainingText,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
