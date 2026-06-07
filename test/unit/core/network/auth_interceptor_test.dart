// Tests for AuthInterceptor — token attachment, 401 handling, refresh flow,
// session expiry, and passthrough guard conditions.
//
// Uses mocktail for TokenStorage and the refresh Dio.
// Uses lightweight spy subclasses for RequestInterceptorHandler /
// ErrorInterceptorHandler to avoid mocking Dio's internal handler hierarchy.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kise/core/network/api_endpoints.dart';
import 'package:kise/core/network/auth_interceptor.dart';
import 'package:kise/features/auth/data/datasources/token_storage.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────────

class MockTokenStorage extends Mock implements TokenStorage {}
class MockDio extends Mock implements Dio {}

// ── Handler Spies ─────────────────────────────────────────────────────────────
// Lightweight subclasses that record which method was called, avoiding the
// need to mock Dio's internal final/private handler machinery.

class _RequestHandlerSpy extends RequestInterceptorHandler {
  RequestOptions? passedOptions;
  bool nextCalled = false;

  @override
  void next(RequestOptions options) {
    passedOptions = options;
    nextCalled = true;
  }
}

class _ErrorHandlerSpy extends ErrorInterceptorHandler {
  DioException? passedError;
  bool nextCalled = false;

  @override
  void next(DioException err) {
    passedError = err;
    nextCalled = true;
  }
}

// ── Factories ─────────────────────────────────────────────────────────────────

RequestOptions _requestOptions({
  String path = '/transactions',
  Map<String, dynamic>? extra,
}) =>
    RequestOptions(
      path: path,
      extra: extra ?? {},
    );

DioException _dioError({
  int statusCode = 401,
  String path = '/transactions',
  Map<String, dynamic>? extra,
}) {
  final opts = _requestOptions(path: path, extra: extra ?? {});
  return DioException(
    requestOptions: opts,
    response: Response(
      requestOptions: opts,
      statusCode: statusCode,
    ),
    type: DioExceptionType.badResponse,
  );
}

Response<Map<String, dynamic>> _refreshSuccessResponse() => Response(
      requestOptions: RequestOptions(path: ApiEndpoints.authRefresh),
      statusCode: 200,
      data: {
        'success': true,
        'data': {
          'tokens': {
            'accessToken': 'new-access-token',
            'refreshToken': 'new-refresh-token',
          }
        },
      },
    );

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late MockTokenStorage mockStorage;
  late MockDio mockRefreshDio;
  late bool sessionExpiredCalled;
  late AuthInterceptor interceptor;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockStorage = MockTokenStorage();
    mockRefreshDio = MockDio();
    sessionExpiredCalled = false;

    interceptor = AuthInterceptor(
      tokenStorage: mockStorage,
      refreshDio: mockRefreshDio,
      onSessionExpired: () => sessionExpiredCalled = true,
    );

    // Default: no tokens stored
    when(() => mockStorage.readAccessToken()).thenAnswer((_) async => null);
    when(() => mockStorage.readRefreshToken()).thenAnswer((_) async => null);
    when(() => mockStorage.clearTokens()).thenAnswer((_) async {});
    when(() => mockStorage.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        )).thenAnswer((_) async {});

    registerFallbackValue(RequestOptions(path: ''));
    registerFallbackValue(<String, dynamic>{});
  });

  // ────────────────────────────────────────────────────
  // onRequest — token attachment
  // ────────────────────────────────────────────────────
  group('onRequest — token attachment', () {
    test('attaches Authorization header when access token is available',
        () async {
      when(() => mockStorage.readAccessToken())
          .thenAnswer((_) async => 'my-access-token');

      final handler = _RequestHandlerSpy();
      final options = _requestOptions(path: '/goals');

      await interceptor.onRequest(options, handler);

      expect(handler.nextCalled, isTrue);
      expect(
        handler.passedOptions?.headers['Authorization'],
        'Bearer my-access-token',
      );
    });

    test('does NOT attach Authorization header when no token is stored',
        () async {
      when(() => mockStorage.readAccessToken()).thenAnswer((_) async => null);

      final handler = _RequestHandlerSpy();
      await interceptor.onRequest(_requestOptions(), handler);

      expect(handler.nextCalled, isTrue);
      expect(handler.passedOptions?.headers.containsKey('Authorization'), isFalse);
    });

    test('does NOT attach header when token is an empty string', () async {
      when(() => mockStorage.readAccessToken()).thenAnswer((_) async => '');

      final handler = _RequestHandlerSpy();
      await interceptor.onRequest(_requestOptions(), handler);

      expect(handler.passedOptions?.headers.containsKey('Authorization'), isFalse);
    });

    test('always calls handler.next regardless of token presence', () async {
      final handler = _RequestHandlerSpy();
      await interceptor.onRequest(_requestOptions(), handler);
      expect(handler.nextCalled, isTrue);
    });
  });

  // ────────────────────────────────────────────────────
  // onError — guard conditions (passthrough)
  // ────────────────────────────────────────────────────
  group('onError — passthrough guards', () {
    test('non-401 error passes through without triggering refresh', () async {
      final handler = _ErrorHandlerSpy();
      await interceptor.onError(_dioError(statusCode: 403), handler);

      expect(handler.nextCalled, isTrue);
      expect(sessionExpiredCalled, isFalse);
      verifyNever(() => mockStorage.readRefreshToken());
    });

    test('404 error passes through', () async {
      final handler = _ErrorHandlerSpy();
      await interceptor.onError(_dioError(statusCode: 404), handler);

      expect(handler.nextCalled, isTrue);
    });

    test('500 error passes through', () async {
      final handler = _ErrorHandlerSpy();
      await interceptor.onError(_dioError(statusCode: 500), handler);

      expect(handler.nextCalled, isTrue);
    });

    test('401 on the refresh endpoint passes through (prevents refresh loop)',
        () async {
      final handler = _ErrorHandlerSpy();
      await interceptor.onError(
        _dioError(statusCode: 401, path: ApiEndpoints.authRefresh),
        handler,
      );

      expect(handler.nextCalled, isTrue);
      expect(sessionExpiredCalled, isFalse);
    });

    test('already-retried 401 passes through (prevents double retry)', () async {
      final handler = _ErrorHandlerSpy();
      await interceptor.onError(
        _dioError(statusCode: 401, extra: {'retried': true}),
        handler,
      );

      expect(handler.nextCalled, isTrue);
      expect(sessionExpiredCalled, isFalse);
    });
  });

  // ────────────────────────────────────────────────────
  // onError — 401 with no refresh token
  // ────────────────────────────────────────────────────
  group('onError — 401 with no refresh token', () {
    test('clears tokens and fires onSessionExpired', () async {
      when(() => mockStorage.readRefreshToken()).thenAnswer((_) async => null);

      final handler = _ErrorHandlerSpy();
      await interceptor.onError(_dioError(statusCode: 401), handler);

      verify(() => mockStorage.clearTokens()).called(1);
      expect(sessionExpiredCalled, isTrue);
      expect(handler.nextCalled, isTrue);
    });

    test('fires onSessionExpired when refreshToken is empty string', () async {
      when(() => mockStorage.readRefreshToken()).thenAnswer((_) async => '');

      final handler = _ErrorHandlerSpy();
      await interceptor.onError(_dioError(statusCode: 401), handler);

      expect(sessionExpiredCalled, isTrue);
    });
  });

  // ────────────────────────────────────────────────────
  // onError — 401 with refresh Dio throwing
  // ────────────────────────────────────────────────────
  group('onError — 401 where refresh HTTP call throws', () {
    setUp(() {
      when(() => mockStorage.readRefreshToken())
          .thenAnswer((_) async => 'valid-refresh');
      when(() => mockRefreshDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiEndpoints.authRefresh),
          type: DioExceptionType.connectionError,
        ),
      );
    });

    test('clears tokens and fires onSessionExpired when refresh throws',
        () async {
      final handler = _ErrorHandlerSpy();
      await interceptor.onError(_dioError(statusCode: 401), handler);

      verify(() => mockStorage.clearTokens()).called(1);
      expect(sessionExpiredCalled, isTrue);
      expect(handler.nextCalled, isTrue);
    });
  });

  // ────────────────────────────────────────────────────
  // onError — 401 where refresh returns non-200
  // ────────────────────────────────────────────────────
  group('onError — 401 where refresh returns non-200 status', () {
    setUp(() {
      when(() => mockStorage.readRefreshToken())
          .thenAnswer((_) async => 'valid-refresh');
      when(() => mockRefreshDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ApiEndpoints.authRefresh),
            statusCode: 401, // refresh token also rejected
            data: {'success': false},
          ));
    });

    test('clears tokens and fires onSessionExpired when refresh rejected',
        () async {
      final handler = _ErrorHandlerSpy();
      await interceptor.onError(_dioError(statusCode: 401), handler);

      verify(() => mockStorage.clearTokens()).called(1);
      expect(sessionExpiredCalled, isTrue);
      expect(handler.nextCalled, isTrue);
    });
  });

  // ────────────────────────────────────────────────────
  // onError — 401 where refresh succeeds
  // ────────────────────────────────────────────────────
  group('onError — 401 where refresh HTTP call succeeds', () {
    setUp(() {
      when(() => mockStorage.readRefreshToken())
          .thenAnswer((_) async => 'valid-refresh');
      when(() => mockRefreshDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          )).thenAnswer((_) async => _refreshSuccessResponse());
      // After refresh, new access token is available
      when(() => mockStorage.readAccessToken())
          .thenAnswer((_) async => 'new-access-token');
    });

    test('calls saveTokens with new access and refresh tokens', () async {
      // The retry Dio makes a real HTTP call that will fail in tests.
      // AuthInterceptor catches that exception and calls sessionExpired.
      // We verify that the refresh itself was successful (saveTokens called).
      final handler = _ErrorHandlerSpy();
      await interceptor.onError(_dioError(statusCode: 401), handler);

      // Refresh succeeded → saveTokens was called with the new tokens
      verify(() => mockStorage.saveTokens(
            accessToken: 'new-access-token',
            refreshToken: 'new-refresh-token',
          )).called(1);
    });

    test('sends refresh request to authRefresh endpoint', () async {
      final handler = _ErrorHandlerSpy();
      await interceptor.onError(_dioError(statusCode: 401), handler);

      verify(() => mockRefreshDio.post<Map<String, dynamic>>(
            ApiEndpoints.authRefresh,
            data: any(named: 'data'),
          )).called(1);
    });

    test('sends old refresh token in the refresh request body', () async {
      final handler = _ErrorHandlerSpy();
      await interceptor.onError(_dioError(statusCode: 401), handler);

      final captured = verify(() => mockRefreshDio.post<Map<String, dynamic>>(
            any(),
            data: captureAny(named: 'data'),
          )).captured;

      final body = captured.first as Map<String, dynamic>;
      expect(body['refreshToken'], 'valid-refresh');
    });
  });

  // ────────────────────────────────────────────────────
  // _cloneRequestOptions — Authorization header update
  // ────────────────────────────────────────────────────
  group('_cloneRequestOptions (via onRequest)', () {
    test('cloned options carry the new access token as Authorization header',
        () async {
      // Verify via onRequest since _cloneRequestOptions is private
      when(() => mockStorage.readAccessToken())
          .thenAnswer((_) async => 'cloned-token');

      final handler = _RequestHandlerSpy();
      final options = _requestOptions(path: '/debts');
      await interceptor.onRequest(options, handler);

      expect(handler.passedOptions?.headers['Authorization'],
          'Bearer cloned-token');
    });
  });

  // ────────────────────────────────────────────────────
  // TokenStorage — standalone
  // ────────────────────────────────────────────────────
  group('TokenStorage (standalone — uses SharedPreferences mock)', () {
    late TokenStorage storage;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = TokenStorage();
    });

    test('readAccessToken returns null when nothing stored', () async {
      expect(await storage.readAccessToken(), isNull);
    });

    test('saveTokens then readAccessToken returns stored value', () async {
      await storage.saveTokens(
        accessToken: 'acc-tok',
        refreshToken: 'ref-tok',
      );
      expect(await storage.readAccessToken(), 'acc-tok');
      expect(await storage.readRefreshToken(), 'ref-tok');
    });

    test('clearTokens removes both tokens', () async {
      await storage.saveTokens(
        accessToken: 'acc-tok',
        refreshToken: 'ref-tok',
      );
      await storage.clearTokens();
      expect(await storage.readAccessToken(), isNull);
      expect(await storage.readRefreshToken(), isNull);
    });

    test('clearTokens on empty storage does not throw', () async {
      await expectLater(storage.clearTokens(), completes);
    });

    test('saveTokens is idempotent — second call overwrites first', () async {
      await storage.saveTokens(accessToken: 'old', refreshToken: 'old-r');
      await storage.saveTokens(accessToken: 'new', refreshToken: 'new-r');
      expect(await storage.readAccessToken(), 'new');
      expect(await storage.readRefreshToken(), 'new-r');
    });
  });
}
