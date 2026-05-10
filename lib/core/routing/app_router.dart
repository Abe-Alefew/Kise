import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kise/core/widgets/scaffold_with_nav_bar.dart';
import 'package:kise/features/auth/presentation/screens/splash_screen.dart';
import 'package:kise/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:kise/features/auth/presentation/screens/login_screen.dart';
import 'package:kise/features/auth/presentation/screens/register_screen.dart';
import 'package:kise/features/auth/presentation/screens/terms_and_conditions.dart';
import 'package:kise/features/home/presentation/screens/home_dashboard.dart';
import 'package:kise/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:kise/features/goals/presentation/screens/goals_screen.dart';
import 'package:kise/features/debt/domain/debt_entity.dart';
import 'package:kise/features/debt/presentation/screens/debt_screen.dart';
import 'package:kise/features/debt/presentation/screens/debt_detail_screen.dart';
import 'package:kise/features/debt/presentation/screens/add_edit_debt_screen.dart';
import 'package:kise/features/settings/presentation/screens/settings_screen.dart';

abstract class AppRoutes {
  static const String splash       = '/';
  static const String onboarding   = '/onboarding';
  static const String login        = '/login';
  static const String register     = '/register';
  static const String terms = '/terms';

  // Main tabs
  static const String home         = '/home';
  static const String transactions = '/transactions';
  static const String goals        = '/goals';
  static const String debt         = '/debt';
  static const String settings     = '/settings';

  // Debt modal routes — full paths used with context.push()
  static const String debtNew    = '/debt/new';
  static const String debtDetail = '/debt/detail'; // + /:debtId
  static const String debtEdit   = '/debt/edit';   // + /:debtId
}

// ---------------------------------------------------------------------------
// Modal page builder
//
// Routes at the ROOT navigator level appear over the bottom nav bar.
// The child is positioned at Alignment.bottomCenter so the modal wraps its
// content height rather than filling the screen.
// barrierDismissible: true  →  tapping the scrim calls navigator.pop(),
//   which PopScope (in DebtDetailModal) intercepts to return _debt state.
// ---------------------------------------------------------------------------
CustomTransitionPage<T> _modalRoute<T>({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    // Semi-transparent scrim — theme-independent (always black overlay)
    opaque: false,
    barrierColor: Colors.black54,
    barrierDismissible: true,
    // Material ancestor required for TextFormField/InkWell on root navigator.
    // type: transparency preserves the modal's own BoxDecoration background.
    child: Material(
      type: MaterialType.transparency,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: child,
      ),
    ),
    // Slide-from-bottom animation matching showModalBottomSheet
    transitionsBuilder: (context, animation, _, child) => SlideTransition(
      position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOut),
      ),
      child: child,
    ),
  );
}

// ---------------------------------------------------------------------------

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

abstract class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    routes: <RouteBase>[

      // ── Auth screens ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.terms,
        builder: (context, state) => const TermsAndConditionsScreen(),
      ),

      // ── Debt modal routes — ROOT LEVEL ──────────────────────────────────
      // Placed outside StatefulShellRoute so they push onto the root
      // navigator and appear over the bottom navigation bar.

      // /debt/new — no extra data needed
      GoRoute(
        path: AppRoutes.debtNew,
        pageBuilder: (context, state) => _modalRoute(
          state: state,
          child: const AddEditDebtModal(),
        ),
      ),

      // /debt/detail/:debtId — extra: DebtEntity
      GoRoute(
        path: '${AppRoutes.debtDetail}/:debtId',
        pageBuilder: (context, state) {
          final debt = state.extra as DebtEntity;
          return _modalRoute(
            state: state,
            child: DebtDetailModal(debt: debt),
          );
        },
      ),

      // /debt/edit/:debtId — extra: DebtEntity
      GoRoute(
        path: '${AppRoutes.debtEdit}/:debtId',
        pageBuilder: (context, state) {
          final debt = state.extra as DebtEntity;
          return _modalRoute(
            state: state,
            child: AddEditDebtModal(existingDebt: debt),
          );
        },
      ),

      // ── Main tabs (with bottom nav bar) ─────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomeDashboard(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.transactions,
              builder: (context, state) => const TransactionsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.goals,
              builder: (context, state) => const GoalsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.debt,
              builder: (context, state) => const DebtScreen(),
              // No nested modal routes here — they live at root level above.
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, state) => const SettingsScreen(),
            ),
          ]),
        ],
      ),
    ],
    errorBuilder: (context, state) => const SizedBox.shrink(),
  );
}
