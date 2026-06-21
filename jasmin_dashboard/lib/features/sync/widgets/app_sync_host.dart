import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/refresh_intervals.dart';
import '../../audit_logs/providers/audit_logs_provider.dart';
import '../../auth/models/auth_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../../banners/providers/banners_provider.dart';
import '../../customers/providers/customers_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../faqs/providers/faqs_provider.dart';
import '../../games/providers/games_provider.dart';
import '../../notifications/providers/notifications_provider.dart';
import '../../orders/providers/orders_provider.dart';
import '../../products/providers/products_provider.dart';
import '../../promo_codes/providers/promo_codes_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/app_sync_provider.dart';

class AppSyncHost extends ConsumerStatefulWidget {
  const AppSyncHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppSyncHost> createState() => _AppSyncHostState();
}

class _AppSyncHostState extends ConsumerState<AppSyncHost> with WidgetsBindingObserver {
  DateTime? _lastResumeRefreshAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAfterResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authStatus = ref.watch(authProvider.select((state) => state.status));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sync = ref.read(appSyncProvider.notifier);
      if (authStatus == AuthStatus.authenticated) {
        sync.start();
      } else {
        sync.stop();
      }
    });

    return widget.child;
  }

  void _refreshAfterResume() {
    final now = DateTime.now();
    final last = _lastResumeRefreshAt;
    if (last != null && now.difference(last) < RefreshIntervals.appResumeDebounce) return;
    _lastResumeRefreshAt = now;

    if (ref.read(authProvider).status != AuthStatus.authenticated) return;

    ref.read(appSyncProvider.notifier).pollNow(reason: 'resume');
    _invalidateVisibleAdminData();
  }

  void _invalidateVisibleAdminData() {
    ref.invalidate(dashboardProvider);
    ref.invalidate(ordersProvider);
    ref.invalidate(productsProvider);
    ref.invalidate(gamesProvider);
    ref.invalidate(bannersProvider);
    ref.invalidate(settingsProvider);
    ref.invalidate(faqsProvider);
    ref.invalidate(customersProvider);
    ref.invalidate(promoCodesProvider);
    ref.invalidate(auditLogsProvider);
    ref.invalidate(notificationsProvider);
  }
}
