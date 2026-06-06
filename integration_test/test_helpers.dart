import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kise/core/providers/theme_provider.dart';
import 'package:kise/main.dart';

/// Pumps [KiseApp] inside a [ProviderScope] and waits for the widget tree to settle.
Future<void> pumpApp(
  WidgetTester tester, {
  Duration settle = const Duration(seconds: 3),
}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      initialThemeModeProvider.overrideWithValue(ThemeMode.system),
    ],
    child: const KiseApp(),
  ));
  await tester.pumpAndSettle(settle);
}
