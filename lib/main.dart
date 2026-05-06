import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/transactions/pages/test_pill_filter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KISE App',
      theme: AppTheme.light,
      home: const TestPillFilterPage(),
    );
  }
}