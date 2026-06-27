import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/jasmin_logo.dart';
import '../models/auth_state.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

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
              if (authState.status == AuthStatus.checking) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                const Text('Checking secure admin session...'),
              ] else ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                const Text('Redirecting...'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
