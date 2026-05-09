import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kise/core/widgets/scaffold_with_nav_bar.dart';

import 'package:kise/features/auth/presentation/screens/splash_screen.dart';
import 'package:kise/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:kise/features/auth/presentation/screens/login_screen.dart';
import 'package:kise/features/auth/presentation/screens/register_screen.dart';
import 'package:kise/features/home/presentation/screens/home_dashboard.dart';
import 'package:kise/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:kise/features/goals/presentation/screens/goals_screen.dart';
import 'package:kise/features/debt/presentation/screens/debt_screen.dart';
import 'package:kise/features/settings/presentation/screens/settings.dart';

abstract class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  
  // Dashboard / Tabs
  static const String home = '/home';
  static const String transactions = '/transactions';
  static const String goals = '/goals';
  static const String debt = '/debt';
  static const String settings = '/settings';
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

abstract class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash, // Usually splash controls navigation, will act as the first screen
    routes: <RouteBase>[
      // Screens without bottom nav bar
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
      
      // Screens with bottom nav bar
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          // Home
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeDashboardScreen(),
              ),
            ],
          ),
          // Transactions
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.transactions,
                builder: (context, state) => const TransactionsScreen(),
              ),
            ],
          ),
          // Goals
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.goals,
                builder: (context, state) => const GoalsScreen(),
              ),
            ],
          ),
          // Debt Book
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.debt,
                builder: (context, state) => const DebtScreen(),
              ),
            ],
          ),
          // Settings
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) {
      return const SizedBox.shrink(); // A real error page would go here
    },
  );
}
