import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'package:kise/core/routing/app_router.dart';

void main() {
  runApp(const KiseApp());
}

class KiseApp extends StatelessWidget {
  const KiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    
    return MaterialApp.router(
      title: 'KISE',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
    );
  }
}
