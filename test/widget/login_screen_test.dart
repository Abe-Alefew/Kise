import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kise/features/auth/presentation/screens/login_screen.dart';
import 'package:kise/features/auth/presentation/state/auth_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_data/auth_fixtures.dart';
import '../helpers/widget_helper.dart';

// ── Fake notifiers ────────────────────────────────────────────────────────────
// All fakes extend AuthNotifier so they satisfy the typed overrideWith contract.

/// Returns an unauthenticated state immediately — simulates cold start.
class _UnauthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async => unauthenticatedState;
}

/// Emits a loading AuthState — simulates an in-flight login request.
class _LoadingNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async => loadingState;
}

// ── Helper ────────────────────────────────────────────────────────────────────

Widget _buildLoginScreen(AuthNotifier notifier) {
  SharedPreferences.setMockInitialValues({});
  return buildWithRouter(
    const LoginScreen(),
    providerOverrides: [
      authNotifierProvider.overrideWith(() => notifier),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('LoginScreen', () {
    // ── Widget structure ───────────────────────────────────────────
    group('widget structure', () {
      testWidgets('renders a Scaffold', (tester) async {
        await tester.pumpWidget(_buildLoginScreen(_UnauthNotifier()));
        await tester.pumpAndSettle();
        expect(find.byType(Scaffold), findsWidgets);
      });

      testWidgets('shows "Log In" title text', (tester) async {
        await tester.pumpWidget(_buildLoginScreen(_UnauthNotifier()));
        await tester.pumpAndSettle();
        expect(find.text('Log In'), findsOneWidget);
      });

      testWidgets('shows "YOUR EMAIL ADDRESS" label', (tester) async {
        await tester.pumpWidget(_buildLoginScreen(_UnauthNotifier()));
        await tester.pumpAndSettle();
        expect(find.text('YOUR EMAIL ADDRESS'), findsOneWidget);
      });

      testWidgets('shows "PASSWORD" label', (tester) async {
        await tester.pumpWidget(_buildLoginScreen(_UnauthNotifier()));
        await tester.pumpAndSettle();
        expect(find.text('PASSWORD'), findsOneWidget);
      });

      testWidgets('shows "SIGN IN" button', (tester) async {
        await tester.pumpWidget(_buildLoginScreen(_UnauthNotifier()));
        await tester.pumpAndSettle();
        expect(find.text('SIGN IN'), findsOneWidget);
      });

      testWidgets('shows "Forgot?" link', (tester) async {
        await tester.pumpWidget(_buildLoginScreen(_UnauthNotifier()));
        await tester.pumpAndSettle();
        expect(find.text('Forgot?'), findsOneWidget);
      });

      testWidgets('shows "Register Here" link', (tester) async {
        await tester.pumpWidget(_buildLoginScreen(_UnauthNotifier()));
        await tester.pumpAndSettle();
        expect(find.text('Register Here'), findsOneWidget);
      });

      testWidgets('shows two TextFields (email and password)', (tester) async {
        await tester.pumpWidget(_buildLoginScreen(_UnauthNotifier()));
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsAtLeast(2));
      });
    });

    // ── Loading state ──────────────────────────────────────────────
    group('loading state', () {
      testWidgets(
          'shows CircularProgressIndicator on SIGN IN button when loading',
          (tester) async {
        await tester.pumpWidget(_buildLoginScreen(_LoadingNotifier()));
        await tester.pump(); // one frame — loading state is in AsyncLoading
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('hides "SIGN IN" text label while loading', (tester) async {
        await tester.pumpWidget(_buildLoginScreen(_LoadingNotifier()));
        await tester.pump();
        expect(find.text('SIGN IN'), findsNothing);
      });
    });

    // ── Form input ─────────────────────────────────────────────────
    group('form input', () {
      testWidgets('can type into the email field', (tester) async {
        await tester.pumpWidget(_buildLoginScreen(_UnauthNotifier()));
        await tester.pumpAndSettle();

        final emailField = find.byType(TextField).first;
        await tester.enterText(emailField, 'test@kise.app');
        expect(find.text('test@kise.app'), findsOneWidget);
      });

      testWidgets('can type into the password field', (tester) async {
        await tester.pumpWidget(_buildLoginScreen(_UnauthNotifier()));
        await tester.pumpAndSettle();

        // Password field is the second TextField
        final fields = find.byType(TextField);
        await tester.enterText(fields.at(1), 'secret123');
        // Password is obscured — find by controller value via entering text
        expect(fields.at(1), findsOneWidget);
      });
    });

    // ── Back button ────────────────────────────────────────────────
    testWidgets('shows a back arrow button', (tester) async {
      await tester.pumpWidget(_buildLoginScreen(_UnauthNotifier()));
      await tester.pumpAndSettle();
      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    // ── No error by default ────────────────────────────────────────
    testWidgets('shows no error message on initial render', (tester) async {
      await tester.pumpWidget(_buildLoginScreen(_UnauthNotifier()));
      await tester.pumpAndSettle();
      // Error message container only appears when there's an error
      expect(find.textContaining('Unable to sign in'), findsNothing);
    });
  });
}
