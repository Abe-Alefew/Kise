import 'package:flutter_test/flutter_test.dart';
import 'package:kise/features/auth/domain/auth_models.dart';
import 'package:kise/features/auth/presentation/state/auth_notifier.dart';

AuthUser _testUser({String firstName = 'Test', String lastName = 'User'}) =>
    AuthUser(
      id: 'user-001',
      email: 'test@example.com',
      firstName: firstName,
      lastName: lastName,
      university: 'AAU',
      department: 'CS',
      currency: 'ETB',
      preferredLanguage: 'English',
    );

void main() {
  // ────────────────────────────────────────────────────
  // AuthUser
  // ────────────────────────────────────────────────────
  group('AuthUser', () {
    test('fullName joins firstName and lastName', () {
      final user = _testUser(firstName: 'Abel', lastName: 'Bekele');
      expect(user.fullName, 'Abel Bekele');
    });

    test('fullName trims when lastName is empty', () {
      final user = AuthUser(
        id: 'u',
        email: 'e@e.com',
        firstName: 'Solo',
        lastName: '',
        university: 'AAU',
        department: 'CS',
        currency: 'ETB',
        preferredLanguage: 'English',
      );
      expect(user.fullName, 'Solo');
    });

    test('themeMode defaults to "system"', () {
      expect(_testUser().themeMode, 'system');
    });

    test('fromJson parses all fields', () {
      final json = {
        'id': 'user-123',
        'email': 'hello@test.com',
        'firstName': 'John',
        'lastName': 'Doe',
        'phone': '+251911000000',
        'username': 'johndoe',
        'university': 'MIT',
        'department': 'EE',
        'currency': 'USD',
        'preferredLanguage': 'Amharic',
        'themeMode': 'dark',
      };
      final user = AuthUser.fromJson(json);
      expect(user.id, 'user-123');
      expect(user.email, 'hello@test.com');
      expect(user.firstName, 'John');
      expect(user.lastName, 'Doe');
      expect(user.phone, '+251911000000');
      expect(user.username, 'johndoe');
      expect(user.university, 'MIT');
      expect(user.department, 'EE');
      expect(user.currency, 'USD');
      expect(user.preferredLanguage, 'Amharic');
      expect(user.themeMode, 'dark');
    });

    test('fromJson defaults missing optional fields', () {
      final json = {
        'id': 'u',
        'email': 'e@e.com',
        'firstName': 'F',
        'lastName': 'L',
      };
      final user = AuthUser.fromJson(json);
      expect(user.phone, isNull);
      expect(user.username, isNull);
      expect(user.university, '');
      expect(user.currency, 'ETB');
      expect(user.preferredLanguage, 'English');
      expect(user.themeMode, 'system');
    });

    test('toJson round-trips all fields', () {
      final user = _testUser(firstName: 'Sara', lastName: 'Ali');
      final json = user.toJson();
      final restored = AuthUser.fromJson(json);
      expect(restored.id, user.id);
      expect(restored.email, user.email);
      expect(restored.firstName, user.firstName);
      expect(restored.lastName, user.lastName);
      expect(restored.university, user.university);
      expect(restored.currency, user.currency);
    });
  });

  // ────────────────────────────────────────────────────
  // AuthTokens
  // ────────────────────────────────────────────────────
  group('AuthTokens', () {
    test('fromJson parses tokens correctly', () {
      final json = {
        'accessToken': 'acc-tok',
        'refreshToken': 'ref-tok',
        'expiresIn': 3600,
      };
      final tokens = AuthTokens.fromJson(json);
      expect(tokens.accessToken, 'acc-tok');
      expect(tokens.refreshToken, 'ref-tok');
      expect(tokens.expiresIn, 3600);
    });

    test('fromJson defaults expiresIn to 3600 when absent', () {
      final json = {
        'accessToken': 'a',
        'refreshToken': 'r',
      };
      final tokens = AuthTokens.fromJson(json);
      expect(tokens.expiresIn, 3600);
    });

    test('toJson round-trips', () {
      const tokens = AuthTokens(
        accessToken: 'tok1',
        refreshToken: 'tok2',
        expiresIn: 7200,
      );
      final json = tokens.toJson();
      expect(json['accessToken'], 'tok1');
      expect(json['refreshToken'], 'tok2');
      expect(json['expiresIn'], 7200);
    });
  });

  // ────────────────────────────────────────────────────
  // RegisterRequest.toJson
  // ────────────────────────────────────────────────────
  group('RegisterRequest.toJson', () {
    const request = RegisterRequest(
      firstName: 'Betsinat',
      lastName: 'Habte',
      email: 'bet@test.com',
      password: 'secret123',
      confirmPassword: 'secret123',
      university: 'AAU',
      department: 'CS',
      preferredLanguage: 'English',
      currency: 'ETB',
      termsAccepted: true,
    );

    test('includes required fields', () {
      final json = request.toJson();
      expect(json['firstName'], 'Betsinat');
      expect(json['lastName'], 'Habte');
      expect(json['email'], 'bet@test.com');
      expect(json['password'], 'secret123');
    });

    test('serializes termsAccepted=true as "true" string', () {
      expect(request.toJson()['termsAccepted'], 'true');
    });

    test('serializes termsAccepted=false as "false" string', () {
      const r = RegisterRequest(
        firstName: 'F',
        lastName: 'L',
        email: 'f@l.com',
        password: 'pw1234',
        confirmPassword: 'pw1234',
        university: 'X',
        department: 'Y',
        preferredLanguage: 'English',
        currency: 'ETB',
        termsAccepted: false,
      );
      expect(r.toJson()['termsAccepted'], 'false');
    });

    test('optional username and phone are included when provided', () {
      const r = RegisterRequest(
        firstName: 'F',
        lastName: 'L',
        email: 'f@l.com',
        password: 'pw1234',
        confirmPassword: 'pw1234',
        university: 'X',
        department: 'Y',
        preferredLanguage: 'English',
        currency: 'ETB',
        termsAccepted: true,
        username: 'myuser',
        phone: '+251900000000',
      );
      final json = r.toJson();
      expect(json['username'], 'myuser');
      expect(json['phone'], '+251900000000');
    });
  });

  // ────────────────────────────────────────────────────
  // AuthState
  // ────────────────────────────────────────────────────
  group('AuthState', () {
    test('unknown() has status=unknown, no user, no error', () {
      const s = AuthState.unknown();
      expect(s.status, AuthStatus.unknown);
      expect(s.user, isNull);
      expect(s.errorMessage, isNull);
    });

    test('loading() has status=loading', () {
      const s = AuthState.loading();
      expect(s.status, AuthStatus.loading);
      expect(s.isLoading, isTrue);
    });

    test('authenticated() sets isAuthenticated=true', () {
      final s = AuthState.authenticated(user: _testUser());
      expect(s.status, AuthStatus.authenticated);
      expect(s.isAuthenticated, isTrue);
      expect(s.user, isNotNull);
    });

    test('unauthenticated() has isAuthenticated=false', () {
      const s = AuthState.unauthenticated(errorMessage: 'wrong password');
      expect(s.status, AuthStatus.unauthenticated);
      expect(s.isAuthenticated, isFalse);
      expect(s.errorMessage, 'wrong password');
      expect(s.user, isNull);
    });

    test('copyWith clears error when clearError=true', () {
      const s = AuthState.unauthenticated(errorMessage: 'some error');
      final cleared = s.copyWith(clearError: true);
      expect(cleared.errorMessage, isNull);
    });

    test('copyWith clears redirectRoute when clearRedirect=true', () {
      const s = AuthState(
        status: AuthStatus.authenticated,
        redirectRoute: '/home',
      );
      final cleared = s.copyWith(clearRedirect: true);
      expect(cleared.redirectRoute, isNull);
    });

    test('copyWith clears successType when clearSuccessType=true', () {
      const s = AuthState(
        status: AuthStatus.authenticated,
        successType: AuthSuccessType.signIn,
      );
      final cleared = s.copyWith(clearSuccessType: true);
      expect(cleared.successType, isNull);
    });

    test('copyWith clears user when clearUser=true', () {
      final s = AuthState.authenticated(user: _testUser());
      final cleared = s.copyWith(clearUser: true);
      expect(cleared.user, isNull);
    });

    test('copyWith updates status while preserving others', () {
      final s = AuthState.authenticated(
        user: _testUser(),
        redirectRoute: '/home',
      );
      final copy = s.copyWith(status: AuthStatus.loading);
      expect(copy.status, AuthStatus.loading);
      expect(copy.redirectRoute, '/home');
      expect(copy.user, isNotNull);
    });

    test('isLoading is false for non-loading states', () {
      expect(const AuthState.unknown().isLoading, isFalse);
      expect(AuthState.authenticated(user: _testUser()).isLoading, isFalse);
      expect(const AuthState.unauthenticated().isLoading, isFalse);
    });
  });
}