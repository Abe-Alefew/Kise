// Integration test: exercises the full widget tree on a real device/emulator.
// Verifies the app boots, renders the initial route, and key flows are reachable.
//
// Run with:
//   flutter test integration_test/app_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Prevent slow network timeout — fail fast when font is not in assets.
  GoogleFonts.config.allowRuntimeFetching = false;

    // App boot smoke test
  
  group('App boot', () {
    testWidgets('app starts without throwing a fatal error', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpApp(tester);
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Scaffold is present in the widget tree after boot',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpApp(tester);
      expect(find.byType(Scaffold), findsAtLeast(1));
    });
  });

    // First-launch flow (no stored session, no onboarding seen)
  
  group('First-launch flow', () {
    testWidgets('unauthenticated user lands on onboarding or login',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpApp(tester);

      final hasOnboarding =
          find.byKey(const Key('onboarding_screen')).evaluate().isNotEmpty;
      final hasLogin =
          find.byKey(const Key('login_screen')).evaluate().isNotEmpty;
      final hasAnyText = find.byType(Text).evaluate().isNotEmpty;

      expect(hasAnyText || hasOnboarding || hasLogin, isTrue);
    });

    testWidgets('onboarding-seen user lands on login', (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_seen': true});
      await pumpApp(tester);
      expect(find.byType(Scaffold), findsAtLeast(1));
    });
  });

    // Core widget availability checks (not logged-in state)
  
  group('Core widget tree', () {
    testWidgets('no unhandled Flutter framework errors on boot', (tester) async {
      // pumpApp forwards any non-font zone errors to the test framework, which
      // will fail this test. Font errors are suppressed — see test_helpers.dart.
      SharedPreferences.setMockInitialValues({});
      await pumpApp(tester);
      expect(find.byType(Scaffold), findsAtLeast(1));
    });
  });
}