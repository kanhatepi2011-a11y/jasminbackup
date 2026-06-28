import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/health_service.dart';
import '../../../shared/widgets/jasmin_logo.dart';
import '../models/auth_state.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final health = ref.watch(startupHealthProvider);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const JasminLogo(size: 96),
              const SizedBox(height: 20),
              Text(
                AppConstants.appName,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text('Connected to ${AppConstants.websiteName} admin backend'),
              const SizedBox(height: 24),
              health.when(
                loading: () => const _SplashStatus(
                  label: 'Connecting to server...',
                ),
                data: (_) => _SplashStatus(
                  label: authState.status == AuthStatus.checking
                      ? 'Checking secure admin session...'
                      : 'Redirecting...',
                ),
                error: (err, _) => _ConnectionError(
                  message: err is AppException
                      ? err.message
                      : 'Cannot connect to server. Please try again.',
                  onRetry: () => ref.invalidate(startupHealthProvider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashStatus extends StatelessWidget {
  const _SplashStatus({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 12),
        Text(label),
      ],
    );
  }
}

class _ConnectionError extends StatelessWidget {
  const _ConnectionError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.wifi_off_rounded,
            size: 40, color: Theme.of(context).colorScheme.error),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    );
  }
}
