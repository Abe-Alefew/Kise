import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kise/core/routing/app_router.dart';
import 'package:kise/core/theme/app_theme.dart';
import 'package:kise/core/providers/theme_provider.dart';
import 'package:kise/features/auth/presentation/providers/auth_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final initialThemeMode = await ThemeNotifier.getStoredTheme();
  
  runApp(
    ProviderScope(
      overrides: [
        initialThemeModeProvider.overrideWithValue(initialThemeMode),
      ],
      child: const KiseApp(),
    ),
  );
}

class KiseApp extends ConsumerWidget {
  const KiseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (previous, next) {
      final redirect = next.value?.redirectRoute;
      if (redirect != null) {
        final successType = next.value?.successType;
        if (successType != null) {
          AppRouter.router.go(redirect, extra: successType);
        } else {
          AppRouter.router.go(redirect);
        }
        ref.read(authNotifierProvider.notifier).clearRedirectRoute();
      }
    });

    return MaterialApp.router(
      title: 'KISE App',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
