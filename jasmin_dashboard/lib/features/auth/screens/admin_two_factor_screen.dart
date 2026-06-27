import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/jasmin_logo.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_message_banner.dart';

class AdminTwoFactorScreen extends ConsumerStatefulWidget {
  const AdminTwoFactorScreen({super.key});

  @override
  ConsumerState<AdminTwoFactorScreen> createState() =>
      _AdminTwoFactorScreenState();
}

class _AdminTwoFactorScreenState extends ConsumerState<AdminTwoFactorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _codeFocusNode = FocusNode();

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to login',
          onPressed: authState.isLoading ? null : _backToLogin,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
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
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(child: JasminLogo(size: 76)),
                          const SizedBox(height: 18),
                          Text(
                            'Verify Google Authenticator',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            authState.loginEmail == null
                                ? 'Enter the 6-digit code from your authenticator app.'
                                : 'Enter the 6-digit code for ${authState.loginEmail}.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                          if (authState.errorMessage != null) ...[
                            const SizedBox(height: 18),
                            AuthMessageBanner(
                                message: authState.errorMessage!,
                                type: AuthMessageType.error),
                          ],
                          if (authState.infoMessage != null) ...[
                            const SizedBox(height: 18),
                            AuthMessageBanner(
                                message: authState.infoMessage!,
                                type: AuthMessageType.info),
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
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                            decoration: const InputDecoration(
                              counterText: '',
                              labelText: '6-digit code',
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
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.verified_user_outlined),
                            label: Text(authState.isLoading
                                ? 'Verifying...'
                                : 'Verify 2FA'),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed:
                                authState.isLoading ? null : _backToLogin,
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text('Back to login'),
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
      ),
    );
  }

  String? _validateCode(String? value) {
    final code = value?.trim() ?? '';
    if (code.isEmpty) {
      return '2FA code is required.';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      return 'Enter exactly 6 digits.';
    }
    return null;
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final success = await ref
        .read(authProvider.notifier)
        .verifyTwoFactor(_codeController.text);
    if (success) {
      _codeController.clear();
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
      return;
    }

    _codeController.clear();
    if (mounted) {
      _codeFocusNode.requestFocus();
    }
  }

  Future<void> _backToLogin() {
    return ref.read(authProvider.notifier).resetToLogin();
  }
}
