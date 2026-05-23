import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kise/core/routing/app_router.dart';
import 'package:kise/core/theme/app_theme.dart';
import 'package:kise/core/providers/theme_provider.dart';
import 'package:kise/features/auth/presentation/providers/auth_notifier.dart';
import 'package:kise/features/settings/presentation/providers/settings_notifier.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWebNoWebWorker;
  } else if (defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
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

    if (ref.watch(isAuthenticatedProvider)) {
      ref.watch(settingsNotifierProvider);
    }

    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (previous, next) {
      final wasAuthenticated = previous?.value?.isAuthenticated ?? false;
      final isAuthenticated = next.value?.isAuthenticated ?? false;
      if (wasAuthenticated && !isAuthenticated) {
        ref.invalidate(settingsNotifierProvider);
        ref.invalidate(settingsUiFlagsProvider);
      }

      final redirect = next.value?.redirectRoute;
      if (redirect != null) {
        final successType = next.value?.successType;
        if (successType != null) {
          AppRouter.router.go(redirect, extra: successType);
        } else {
          AppRouter.router.go(redirect);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (ref.context.mounted) {
            ref.read(authNotifierProvider.notifier).clearRedirectRoute();
          }
        });
      }
    });

    return MaterialApp.router(
      title: 'KISE App',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
