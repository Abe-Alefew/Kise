// Widget-test helpers for authenticated scenarios.
// Provides:
//   - buildWithAuth()       → ProviderScope + GoRouter with auth pre-loaded
//   - setMockTokens()       → writes tokens to SharedPreferences mock store
//   - clearMockTokens()     → wipes tokens from SharedPreferences mock store
//   - authUserFromJson()    → quick AuthUser factory from partial JSON

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kise/features/auth/data/datasources/token_storage.dart';
import 'package:kise/features/auth/domain/auth_models.dart';
import 'package:kise/features/auth/presentation/state/auth_notifier.dart';

import 'test_data/auth_fixtures.dart';
import 'widget_helper.dart';

// Token helpers 

/// Injects [accessToken] and [refreshToken] into the SharedPreferences mock
/// store so that [TokenStorage] reads them without a real secure-storage
/// backend.
Future<void> setMockTokens({
  String accessToken = 'test-access-token',
  String refreshToken = 'test-refresh-token',
}) async {
  SharedPreferences.setMockInitialValues({
    TokenStorageKeys.accessToken: accessToken,
    TokenStorageKeys.refreshToken: refreshToken,
  });
}

/// Clears any previously injected tokens from the SharedPreferences mock store.
Future<void> clearMockTokens() async {
  SharedPreferences.setMockInitialValues({});
}

// ── AuthUser factory ──────────────────────────────────────────────────────────

/// Creates a test [AuthUser] with sane defaults.  Pass only the fields you
/// care about overriding.
AuthUser makeTestUser({
  String id = 'user-test-001',
  String email = 'test@kise.app',
  String firstName = 'Abel',
  String lastName = 'Bekele',
  String university = 'AAU',
  String department = 'CS',
  String currency = 'ETB',
  String preferredLanguage = 'English',
  String themeMode = 'system',
}) =>
    AuthUser(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      university: university,
      department: department,
      currency: currency,
      preferredLanguage: preferredLanguage,
      themeMode: themeMode,
    );

// ── Pre-authenticated widget builder ─────────────────────────────────────────

/// Fake [AuthNotifier] that immediately emits [authenticatedState].
/// Avoids hitting the real repository / SharedPreferences bootstrap.
class FakeAuthenticatedNotifier extends AuthNotifier {
  final AuthState? overrideState;

  FakeAuthenticatedNotifier({this.overrideState});

  @override
  Future<AuthState> build() async => overrideState ?? authenticatedState;
}

/// Fake [AuthNotifier] that immediately emits [unauthenticatedState].
class FakeUnauthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async => unauthenticatedState;
}

/// Builds a routable widget tree with [authNotifierProvider] already
/// overridden to return [state] (defaults to authenticated).
///
/// Equivalent to [buildWithRouter] but with auth pre-loaded — use this for
/// screen-level widget tests that need a signed-in context.
Widget buildWithAuth(
  Widget child, {
  AuthState? state,
  List<Object> additionalOverrides = const [],
}) {
  SharedPreferences.setMockInitialValues({});
  return buildWithRouter(
    child,
    providerOverrides: [
      authNotifierProvider.overrideWith(
        () => FakeAuthenticatedNotifier(overrideState: state),
      ),
      authStateProvider.overrideWith(
        (ref) => state ?? authenticatedState,
      ),
      ...additionalOverrides,
    ],
  );
}

/// Builds a routable widget tree simulating an unauthenticated user.
Widget buildWithNoAuth(Widget child) {
  SharedPreferences.setMockInitialValues({});
  return buildWithRouter(
    child,
    providerOverrides: [
      authNotifierProvider.overrideWith(() => FakeUnauthNotifier()),
      authStateProvider.overrideWith((ref) => unauthenticatedState),
    ],
  );
}