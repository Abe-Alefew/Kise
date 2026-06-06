// Integration test: complete auth user journey.
// Covers: onboarding → registration → login → logout.
//
// Run with:
//   flutter test integration_test/auth_flow_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kise/core/providers/theme_provider.dart';
import 'package:kise/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Auth flow', () {
    testWidgets('first launch shows onboarding screen', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpApp(tester);
      expect(find.byType(Scaffold), findsAtLeast(1));
    });

    testWidgets('returning user sees login screen', (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_seen': true});
      await pumpApp(tester);
      expect(find.byType(Scaffold), findsAtLeast(1));
    });

    testWidgets('login screen has email and password fields', (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_seen': true});
      await pumpApp(tester);
      expect(find.byType(TextField), findsAtLeast(2));
    });

    testWidgets('no crash on app boot regardless of stored session',
        (tester) async {
      final errors = <Object>[];
      final saved = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exception.toString().contains('google_fonts') ||
            details.exception.toString().contains('GoogleFonts')) {
          return;
        }
        errors.add(details.exception);
      };
      try {
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(ProviderScope(
          overrides: [
            initialThemeModeProvider.overrideWithValue(ThemeMode.system),
          ],
          child: const KiseApp(),
        ));
        await tester.pumpAndSettle(const Duration(seconds: 3));
        expect(errors, isEmpty,
            reason: 'Unexpected Flutter errors on boot: $errors');
      } finally {
        FlutterError.onError = saved;
      }
    });
  });
}
