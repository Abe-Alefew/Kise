import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/home/presentation/screens/home_dashboard.dart';

abstract class AppRoutes {
	static const String splash = '/';
	static const String onboarding = '/onboarding';
	static const String login = '/login';
	static const String register = '/register';
	static const String home = '/home';
}

abstract class AppRouter {
	static final GoRouter router = GoRouter(
		initialLocation: AppRoutes.splash,
		routes: <RouteBase>[
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
				path: AppRoutes.home,
				builder: (context, state) => const HomeDashboardScreen(),
			),
		],
		errorBuilder: (context, state) {
			return const SizedBox.shrink();
		},
	);
}
