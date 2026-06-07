// Tests for AuthNotifier — bootstrap paths, login, logout, clearError,
// clearRedirectRoute.  Uses mocktail to replace AuthRepository so no
// real network or token storage is involved.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kise/core/network/dio_client.dart';
import 'package:kise/features/auth/data/repositories/auth_repository.dart';
import 'package:kise/features/auth/domain/auth_models.dart';
import 'package:kise/features/auth/presentation/state/auth_notifier.dart';

import '../../helpers/provider_helper.dart';
import '../../helpers/test_data/auth_fixtures.dart';

// ── Mock ──────────────────────────────────────────────────────────────────────

class MockAuthRepository extends Mock implements AuthRepository {}

// ── Helper ────────────────────────────────────────────────────────────────────

/// Creates a container with [mockRepo] bound to [authRepositoryProvider].
/// SharedPreferences is always reset to a clean slate.
ProviderContainer _makeContainer(
  MockAuthRepository mockRepo, {
  bool onboardingSeen = false,
}) {
  SharedPreferences.setMockInitialValues(
    onboardingSeen ? {'onboarding_seen': true} : {},
  );
  return createContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(mockRepo),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
    registerFallbackValue(
      const RegisterRequest(
        firstName: 'F',
        lastName: 'L',
        email: 'f@l.com',
        password: 'pw1234',
        confirmPassword: 'pw1234',
        university: 'U',
        department: 'D',
        preferredLanguage: 'English',
        currency: 'ETB',
        termsAccepted: true,
      ),
    );
  });

  // ────────────────────────────────────────────────────
  // Bootstrap — no stored session
  // ────────────────────────────────────────────────────
  group('bootstrap — no stored session', () {
    setUp(() {
      when(() => mockRepo.hasStoredSession()).thenAnswer((_) async => false);
    });

    test('returns unauthenticated state', () async {
      final container = _makeContainer(mockRepo);
      final state = await container.read(authNotifierProvider.future);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.isAuthenticated, isFalse);
    });

    test('redirects to onboarding when onboarding not seen', () async {
      final container = _makeContainer(mockRepo, onboardingSeen: false);
      final state = await container.read(authNotifierProvider.future);
      expect(state.redirectRoute, contains('onboarding'));
    });

    test('redirects to login when onboarding already seen', () async {
      final container = _makeContainer(mockRepo, onboardingSeen: true);
      final state = await container.read(authNotifierProvider.future);
      expect(state.redirectRoute, contains('login'));
    });
  });

  // ────────────────────────────────────────────────────
  // Bootstrap — session exists → restore succeeds
  // ────────────────────────────────────────────────────
  group('bootstrap — valid stored session', () {
    setUp(() {
      when(() => mockRepo.hasStoredSession()).thenAnswer((_) async => true);
      when(() => mockRepo.restoreSession())
          .thenAnswer((_) async => testSession);
    });

    test('returns authenticated state with user', () async {
      final container = _makeContainer(mockRepo);
      final state = await container.read(authNotifierProvider.future);
      expect(state.status, AuthStatus.authenticated);
      expect(state.isAuthenticated, isTrue);
      expect(state.user?.email, testUser.email);
    });

    test('redirects to /home on successful restore', () async {
      final container = _makeContainer(mockRepo);
      final state = await container.read(authNotifierProvider.future);
      expect(state.redirectRoute, contains('home'));
    });
  });

  // ────────────────────────────────────────────────────
  // Bootstrap — session exists → restore returns null
  // ────────────────────────────────────────────────────
  group('bootstrap — stored session but restore returns null', () {
    setUp(() {
      when(() => mockRepo.hasStoredSession()).thenAnswer((_) async => true);
      when(() => mockRepo.restoreSession()).thenAnswer((_) async => null);
    });

    test('returns unauthenticated when session cannot be restored', () async {
      final container = _makeContainer(mockRepo);
      final state = await container.read(authNotifierProvider.future);
      expect(state.isAuthenticated, isFalse);
    });
  });

  // ────────────────────────────────────────────────────
  // Bootstrap — restore throws ApiException
  // ────────────────────────────────────────────────────
  group('bootstrap — restore throws', () {
    setUp(() {
      when(() => mockRepo.hasStoredSession()).thenAnswer((_) async => true);
      when(() => mockRepo.restoreSession()).thenThrow(
        const ApiException(message: 'Token expired', code: 'EXPIRED'),
      );
    });

    test('returns unauthenticated with error message', () async {
      final container = _makeContainer(mockRepo);
      final state = await container.read(authNotifierProvider.future);
      expect(state.isAuthenticated, isFalse);
      expect(state.errorMessage, 'Token expired');
    });
  });

  // ────────────────────────────────────────────────────
  // login()
  // ────────────────────────────────────────────────────
  group('login()', () {
    setUp(() {
      // Bootstrap always skips session check in these tests
      when(() => mockRepo.hasStoredSession()).thenAnswer((_) async => false);
    });

    test('transitions to authenticated on success', () async {
      when(() => mockRepo.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => testSession);

      final container = _makeContainer(mockRepo);
      await container.read(authNotifierProvider.future); // wait for boot

      await container
          .read(authNotifierProvider.notifier)
          .login(email: 'test@kise.app', password: 'secret123');

      final state = container.read(authNotifierProvider).value!;
      expect(state.isAuthenticated, isTrue);
      expect(state.user?.email, testUser.email);
      expect(state.successType, AuthSuccessType.signIn);
    });

    test('transitions to unauthenticated on ApiException', () async {
      when(() => mockRepo.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(
        const ApiException(message: 'Invalid credentials', code: 'UNAUTHORIZED'),
      );

      final container = _makeContainer(mockRepo);
      await container.read(authNotifierProvider.future);

      // login() rethrows, so we expect it to throw
      await expectLater(
        container.read(authNotifierProvider.notifier).login(
              email: 'bad@kise.app',
              password: 'wrong',
            ),
        throwsA(isA<ApiException>()),
      );

      final state = container.read(authNotifierProvider).value!;
      expect(state.isAuthenticated, isFalse);
      expect(state.errorMessage, 'Invalid credentials');
    });
  });

  // ────────────────────────────────────────────────────
  // register()
  // ────────────────────────────────────────────────────
  group('register()', () {
    setUp(() {
      when(() => mockRepo.hasStoredSession()).thenAnswer((_) async => false);
    });

    test('transitions to authenticated on success', () async {
      when(() => mockRepo.register(any()))
          .thenAnswer((_) async => testSession);

      final container = _makeContainer(mockRepo);
      await container.read(authNotifierProvider.future);

      await container.read(authNotifierProvider.notifier).register(
            const RegisterRequest(
              firstName: 'Abel',
              lastName: 'Bekele',
              email: 'abel@kise.app',
              password: 'pass123',
              confirmPassword: 'pass123',
              university: 'AAU',
              department: 'CS',
              preferredLanguage: 'English',
              currency: 'ETB',
              termsAccepted: true,
            ),
          );

      final state = container.read(authNotifierProvider).value!;
      expect(state.isAuthenticated, isTrue);
      expect(state.successType, AuthSuccessType.registration);
    });

    test('transitions to unauthenticated on register ApiException', () async {
      when(() => mockRepo.register(any())).thenThrow(
        const ApiException(message: 'Email taken', code: 'CONFLICT'),
      );

      final container = _makeContainer(mockRepo);
      await container.read(authNotifierProvider.future);

      await expectLater(
        container.read(authNotifierProvider.notifier).register(
              const RegisterRequest(
                firstName: 'F',
                lastName: 'L',
                email: 'f@l.com',
                password: 'pw1234',
                confirmPassword: 'pw1234',
                university: 'U',
                department: 'D',
                preferredLanguage: 'English',
                currency: 'ETB',
                termsAccepted: true,
              ),
            ),
        throwsA(isA<ApiException>()),
      );

      final state = container.read(authNotifierProvider).value!;
      expect(state.isAuthenticated, isFalse);
      expect(state.errorMessage, 'Email taken');
    });
  });

  // ────────────────────────────────────────────────────
  // logout()
  // ────────────────────────────────────────────────────
  group('logout()', () {
    setUp(() {
      when(() => mockRepo.hasStoredSession()).thenAnswer((_) async => true);
      when(() => mockRepo.restoreSession())
          .thenAnswer((_) async => testSession);
      when(() => mockRepo.logout()).thenAnswer((_) async {});
    });

    test('returns unauthenticated state after logout', () async {
      final container = _makeContainer(mockRepo);
      await container.read(authNotifierProvider.future);

      await container.read(authNotifierProvider.notifier).logout();

      final state = container.read(authNotifierProvider).value!;
      expect(state.isAuthenticated, isFalse);
      expect(state.status, AuthStatus.unauthenticated);
    });

    test('redirects to /login when navigateToLogin=true (default)', () async {
      final container = _makeContainer(mockRepo);
      await container.read(authNotifierProvider.future);
      await container.read(authNotifierProvider.notifier).logout();

      final state = container.read(authNotifierProvider).value!;
      expect(state.redirectRoute, contains('login'));
    });

    test('no redirect route when navigateToLogin=false', () async {
      final container = _makeContainer(mockRepo);
      await container.read(authNotifierProvider.future);
      await container.read(authNotifierProvider.notifier)
          .logout(navigateToLogin: false);

      final state = container.read(authNotifierProvider).value!;
      expect(state.redirectRoute, isNull);
    });
  });

  // ────────────────────────────────────────────────────
  // clearError()
  // ────────────────────────────────────────────────────
  group('clearError()', () {
    setUp(() {
      when(() => mockRepo.hasStoredSession()).thenAnswer((_) async => false);
      when(() => mockRepo.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(
        const ApiException(message: 'Wrong password', code: 'AUTH_ERROR'),
      );
    });

    test('removes errorMessage from state', () async {
      final container = _makeContainer(mockRepo);
      await container.read(authNotifierProvider.future);

      // produce an error first
      await expectLater(
        container
            .read(authNotifierProvider.notifier)
            .login(email: 'x@x.com', password: 'bad'),
        throwsA(anything),
      );

      expect(container.read(authNotifierProvider).value?.errorMessage,
          isNotNull);

      container.read(authNotifierProvider.notifier).clearError();

      expect(
        container.read(authNotifierProvider).value?.errorMessage,
        isNull,
      );
    });
  });

  // ────────────────────────────────────────────────────
  // clearRedirectRoute()
  // ────────────────────────────────────────────────────
  group('clearRedirectRoute()', () {
    setUp(() {
      when(() => mockRepo.hasStoredSession()).thenAnswer((_) async => false);
    });

    test('sets redirectRoute to null', () async {
      final container = _makeContainer(mockRepo);
      await container.read(authNotifierProvider.future);

      // After boot with no session, redirectRoute is set
      expect(
        container.read(authNotifierProvider).value?.redirectRoute,
        isNotNull,
      );

      container.read(authNotifierProvider.notifier).clearRedirectRoute();

      expect(
        container.read(authNotifierProvider).value?.redirectRoute,
        isNull,
      );
    });
  });

  // ────────────────────────────────────────────────────
  // Derived providers
  // ────────────────────────────────────────────────────
  group('derived providers', () {
    test('authStateProvider returns value from authNotifierProvider', () async {
      when(() => mockRepo.hasStoredSession()).thenAnswer((_) async => true);
      when(() => mockRepo.restoreSession())
          .thenAnswer((_) async => testSession);

      final container = _makeContainer(mockRepo);
      await container.read(authNotifierProvider.future);

      final authState = container.read(authStateProvider);
      expect(authState, isNotNull);
      expect(authState!.isAuthenticated, isTrue);
    });

    test('isAuthenticatedProvider reflects authenticated status', () async {
      when(() => mockRepo.hasStoredSession()).thenAnswer((_) async => true);
      when(() => mockRepo.restoreSession())
          .thenAnswer((_) async => testSession);

      final container = _makeContainer(mockRepo);
      await container.read(authNotifierProvider.future);

      expect(container.read(isAuthenticatedProvider), isTrue);
    });

    test('isAuthenticatedProvider is false when unauthenticated', () async {
      when(() => mockRepo.hasStoredSession()).thenAnswer((_) async => false);

      final container = _makeContainer(mockRepo);
      await container.read(authNotifierProvider.future);

      expect(container.read(isAuthenticatedProvider), isFalse);
    });
  });
}
