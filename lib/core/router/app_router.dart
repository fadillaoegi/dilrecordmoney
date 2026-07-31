import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/budgets/presentation/pages/budget_page.dart';
import '../../features/backup/presentation/pages/data_backup_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/transactions/presentation/pages/add_transaction_page.dart';
import '../../features/transactions/domain/entities/money_transaction.dart';
import '../../features/transactions/presentation/providers/transaction_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
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
        path: AppRoutes.editTransaction,
        builder: (context, state) => _EditTransactionRoute(
          transactionId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.budget,
        builder: (context, state) => const BudgetPage(),
      ),
      GoRoute(
        path: AppRoutes.backup,
        builder: (context, state) => const DataBackupPage(),
      ),
    ],
  );
});

/// Bungkus route edit: mencari transaksi ber-id [transactionId] dari daftar,
/// lalu me-*render* [AddTransactionPage] dalam mode edit. Menampilkan pesan
/// bila transaksi tidak ditemukan (mis. sudah dihapus).
class _EditTransactionRoute extends ConsumerWidget {
  const _EditTransactionRoute({required this.transactionId});

  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions =
        ref.watch(transactionListProvider).asData?.value ?? const <MoneyTransaction>[];
    final MoneyTransaction? transaction =
        transactions.where((t) => t.id == transactionId).firstOrNull;

    if (transaction == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: Center(
          child: Text('Transaksi tidak ditemukan.', style: AppTextStyles.body),
        ),
      );
    }
    return AddTransactionPage(initial: transaction);
  }
}

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
