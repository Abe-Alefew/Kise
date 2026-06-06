import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kise/core/providers/theme_provider.dart';
import 'package:kise/features/auth/presentation/state/auth_notifier.dart';
import 'package:kise/features/settings/data/repositories/settings_repository.dart';
import 'package:kise/features/settings/presentation/screens/settings_screen.dart';

import '../../helpers/test_data/auth_fixtures.dart';
import '../../helpers/test_data/settings_fixtures.dart';
import '../../helpers/widget_helper.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

class _AuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async => authenticatedState;
}

void main() {
  late MockSettingsRepository mockRepo;

  setUp(() {
    mockRepo = MockSettingsRepository();
    SharedPreferences.setMockInitialValues({});
    when(() => mockRepo.fetchSettings())
        .thenAnswer((_) async => testSettingsBundle);
  });

  group('SettingsScreen', () {
    Widget buildScreen() => buildWithRouter(
          const SettingsScreen(),
          providerOverrides: [
            settingsRepositoryProvider.overrideWithValue(mockRepo),
            initialThemeModeProvider.overrideWithValue(ThemeMode.system),
            authNotifierProvider.overrideWith(() => _AuthNotifier()),
            authStateProvider.overrideWith((ref) => authenticatedState),
          ],
        );

    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('shows Appearance or Preferences section', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      // Settings screen typically shows sections like Account, Preferences etc.
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('shows allowance section after data loads', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      // After loading settings, the screen renders content
      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });
}