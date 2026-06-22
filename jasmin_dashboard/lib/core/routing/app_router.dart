import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/audit_logs/screens/audit_logs_screen.dart';
import '../../features/auth/models/auth_state.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/admin_login_screen.dart';
import '../../features/auth/screens/admin_two_factor_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/banners/screens/banner_editor_screen.dart';
import '../../features/banners/screens/banners_screen.dart';
import '../../features/customers/screens/customer_detail_screen.dart';
import '../../features/customers/screens/customers_screen.dart';
import '../../features/dashboard/screens/dashboard_home_screen.dart';
import '../../features/faqs/screens/faq_editor_screen.dart';
import '../../features/faqs/screens/faqs_screen.dart';
import '../../features/games/screens/game_editor_screen.dart';
import '../../features/games/screens/games_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/orders/screens/order_detail_screen.dart';
import '../../features/orders/screens/orders_screen.dart';
import '../../features/products/screens/product_editor_screen.dart';
import '../../features/products/screens/products_screen.dart';
import '../../features/promo_codes/screens/promo_code_editor_screen.dart';
import '../../features/promo_codes/screens/promo_codes_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final location = state.matchedLocation;
      final status = authState.status;
      final isAuthRoute = location == '/login' || location == '/two-factor';

      if (status == AuthStatus.checking) {
        return location == '/splash' ? null : '/splash';
      }

      if (status == AuthStatus.unauthenticated) {
        return location == '/login' ? null : '/login';
      }

      if (status == AuthStatus.awaitingTwoFactor) {
        return location == '/two-factor' ? null : '/two-factor';
      }

      if (status == AuthStatus.authenticated &&
          (isAuthRoute || location == '/splash')) {
        return '/dashboard';
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _fadePage(state, const AdminLoginScreen()),
      ),
      GoRoute(
        path: '/two-factor',
        pageBuilder: (context, state) =>
            _fadePage(state, const AdminTwoFactorScreen()),
      ),
      GoRoute(
        path: '/dashboard',
        pageBuilder: (context, state) =>
            _fadePage(state, const DashboardHomeScreen()),
      ),
      GoRoute(
          path: '/orders', builder: (context, state) => const OrdersScreen()),
      GoRoute(
        path: '/orders/:orderNumber',
        builder: (context, state) => OrderDetailScreen(
            orderNumber: state.pathParameters['orderNumber'] ?? ''),
      ),
      GoRoute(
          path: '/products',
          builder: (context, state) => const ProductsScreen()),
      GoRoute(
          path: '/products/new',
          builder: (context, state) => const ProductEditorScreen()),
      GoRoute(
        path: '/products/:productId',
        builder: (context, state) => ProductEditorScreen(
            productId: state.pathParameters['productId'] ?? ''),
      ),
      GoRoute(path: '/games', builder: (context, state) => const GamesScreen()),
      GoRoute(
          path: '/games/new',
          builder: (context, state) => const GameEditorScreen()),
      GoRoute(
        path: '/games/:gameId',
        builder: (context, state) =>
            GameEditorScreen(gameId: state.pathParameters['gameId'] ?? ''),
      ),
      GoRoute(
          path: '/banners', builder: (context, state) => const BannersScreen()),
      GoRoute(
          path: '/banners/new',
          builder: (context, state) => const BannerEditorScreen()),
      GoRoute(
        path: '/banners/:bannerId',
        builder: (context, state) => BannerEditorScreen(
            bannerId: state.pathParameters['bannerId'] ?? ''),
      ),
      GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/faqs', builder: (context, state) => const FaqsScreen()),
      GoRoute(
          path: '/faqs/new',
          builder: (context, state) => const FaqEditorScreen()),
      GoRoute(
        path: '/faqs/:faqId',
        builder: (context, state) =>
            FaqEditorScreen(faqId: state.pathParameters['faqId'] ?? ''),
      ),
      GoRoute(
          path: '/customers',
          builder: (context, state) => const CustomersScreen()),
      GoRoute(
        path: '/customers/:customerKey',
        builder: (context, state) => CustomerDetailScreen(
            customerKey: state.pathParameters['customerKey'] ?? ''),
      ),
      GoRoute(
          path: '/promo-codes',
          builder: (context, state) => const PromoCodesScreen()),
      GoRoute(
          path: '/promo-codes/new',
          builder: (context, state) => const PromoCodeEditorScreen()),
      GoRoute(
        path: '/promo-codes/:promoId',
        builder: (context, state) => PromoCodeEditorScreen(
            promoId: state.pathParameters['promoId'] ?? ''),
      ),
      GoRoute(
          path: '/audit-logs',
          builder: (context, state) => const AuditLogsScreen()),
      GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen()),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(child: Text(state.error?.message ?? 'Unknown route')),
    ),
  );
});

Page<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}
