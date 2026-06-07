import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kise/core/theme/app_theme.dart';

/// Wraps [child] in a [MaterialApp] with the Kise light theme.
/// Use for pure stateless/stateful widgets with no routing or Riverpod.
Widget buildSimple(Widget child) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    );

/// Wraps [child] in a [MaterialApp] with the Kise dark theme.
Widget buildSimpleDark(Widget child) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: child),
    );

/// Wraps [child] in a [ProviderScope] + [MaterialApp] with light theme.
/// Use for [ConsumerWidget]s that watch Riverpod providers.
Widget buildWithProviders(
  Widget child, {
  List<Object> overrides = const [],
}) =>
    ProviderScope(
      overrides: overrides.cast(),
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: child),
      ),
    );

/// Wraps [child] with a minimal [GoRouter] so that widgets that call
/// [context.go()] or [context.push()] don't throw a missing-router error.
/// All extra routes (e.g. /settings) resolve to a blank [Scaffold].
Widget buildWithRouter(
  Widget child, {
  List<Object> providerOverrides = const [],
  String initialRoute = '/',
}) {
  final router = GoRouter(
    initialLocation: initialRoute,
    routes: [
      GoRoute(path: '/', builder: (_, _) => Scaffold(body: child)),
      GoRoute(path: '/settings', builder: (_, _) => const Scaffold()),
      GoRoute(path: '/home', builder: (_, _) => const Scaffold()),
      GoRoute(path: '/login', builder: (_, _) => const Scaffold()),
      GoRoute(path: '/register', builder: (_, _) => const Scaffold()),
      GoRoute(path: '/onboarding', builder: (_, _) => const Scaffold()),
      GoRoute(path: '/success', builder: (_, _) => const Scaffold()),
    ],
  );

  return ProviderScope(
    overrides: providerOverrides.cast(),
    child: MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: router,
    ),
  );
}
