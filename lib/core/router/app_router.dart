import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/budgets/presentation/pages/budget_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/transactions/presentation/pages/add_transaction_page.dart';
import 'app_routes.dart';

/// Konfigurasi navigasi aplikasi menggunakan go_router.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) => _fade(state, const OnboardingPage()),
      ),
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (context, state) => _fade(state, const HomePage()),
      ),
      GoRoute(
        path: AppRoutes.addTransaction,
        builder: (context, state) => const AddTransactionPage(),
      ),
      GoRoute(
        path: AppRoutes.budget,
        builder: (context, state) => const BudgetPage(),
      ),
    ],
  );
});

/// Transisi fade lembut antar halaman.
CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 450),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      );
    },
  );
}
