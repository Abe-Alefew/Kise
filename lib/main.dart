import 'package:flutter/material.dart';
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4AF37), // KISE Gold
        ),
      ),
      home: const TestPillFilterPage(), // 👈 THIS is your test screen
    );
  }
}