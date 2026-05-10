import 'package:flutter/material.dart';
import 'package:kise/core/routing/app_router.dart';
import 'package:kise/core/theme/app_theme.dart';

void main() {
  runApp(const KiseApp());
}

class KiseApp extends StatelessWidget {
  const KiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'KISE App',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
    );
  }
}
