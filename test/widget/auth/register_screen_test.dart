import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kise/features/auth/presentation/screens/register_screen.dart';
import 'package:kise/features/auth/presentation/state/auth_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_data/auth_fixtures.dart';
import '../../helpers/widget_helper.dart';

class _UnauthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async => unauthenticatedState;
}

Widget _buildRegisterScreen() {
  SharedPreferences.setMockInitialValues({});
  return buildWithRouter(
    const RegisterScreen(),
    providerOverrides: [
      authNotifierProvider.overrideWith(() => _UnauthNotifier()),
    ],
  );
}

void main() {
  group('RegisterScreen', () {
    group('widget structure', () {
      testWidgets('renders a Scaffold', (tester) async {
        await tester.pumpWidget(_buildRegisterScreen());
        await tester.pumpAndSettle();
        expect(find.byType(Scaffold), findsWidgets);
      });

      testWidgets('shows multiple TextFields for form fields', (tester) async {
        await tester.pumpWidget(_buildRegisterScreen());
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsAtLeast(3));
      });

      testWidgets('shows a submit button', (tester) async {
        await tester.pumpWidget(_buildRegisterScreen());
        await tester.pumpAndSettle();
        expect(
          find.byWidgetPredicate((w) =>
              w is ElevatedButton || w is TextButton || w is OutlinedButton),
          findsAtLeast(1),
        );
      });
    });

    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(_buildRegisterScreen());
      await tester.pumpAndSettle();
      expect(find.byType(RegisterScreen), findsOneWidget);
    });
  });
}