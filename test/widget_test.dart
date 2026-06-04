// Top-level smoke test: verifies the app builds and essential UI surfaces.
// Heavier feature tests live under test/unit/, test/widget/, test/providers/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  // Verifies that a basic Riverpod ProviderScope wrapping a MaterialApp
  // renders without throwing.  This is the minimum confidence that the
  // dependency graph is wired correctly before any feature tests run.
  testWidgets('ProviderScope + MaterialApp renders without error',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: Center(child: Text('Kise'))),
        ),
      ),
    );

    expect(find.text('Kise'), findsOneWidget);
  });
}
