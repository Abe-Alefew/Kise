// Tests for AuthRepositoryImpl — login, register, logout, hasStoredSession,
// fetchCurrentUser, restoreSession, refreshSession, and clearLocalSession.
//
// Dependencies mocked with mocktail:
//   - MockDioClient for outgoing HTTP (DioClient interface)
//   - MockDio for the separate refreshDio (raw Dio)
//   - MockTokenStorage for secure token storage
//   - Future.error() for appDatabase (failures are silently caught in repo)

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kise/core/database/app_database.dart';
import 'package:kise/core/network/api_endpoints.dart';
import 'package:kise/core/network/dio_client.dart';
import 'package:kise/features/auth/data/datasources/token_storage.dart';
import 'package:kise/features/auth/data/repositories/auth_repository.dart';
import 'package:kise/features/auth/domain/auth_models.dart';

import '../../../../helpers/database_helper.dart';
import '../../../../helpers/dio_helper.dart';

//  Mocks 

class MockTokenStorage extends Mock implements TokenStorage {}
class MockDio extends Mock implements Dio {}

//  Fixtures 

const _testUser = {
  'id': 'user-001',
  'email': 'test@kise.app',
  'firstName': 'Abel',
  'lastName': 'Bekele',
  'university': 'AAU',
  'department': 'CS',
  'currency': 'ETB',
  'preferredLanguage': 'English',
  'themeMode': 'system',
};

const _testTokens = {
  'accessToken': 'test-access',
  'refreshToken': 'test-refresh',
  'expiresIn': 3600,
};

Map<String, dynamic> _authPayload() => {
      'success': true,
      'data': {
        'user': _testUser,
        'tokens': _testTokens,
      },
    };

Response<Map<String, dynamic>> _successResponse(
  String path,
  Map<String, dynamic> data, {
  int statusCode = 200,
}) =>
    Response<Map<String, dynamic>>(
      requestOptions: RequestOptions(path: path),
      statusCode: statusCode,
      data: data,
    );

DioException _dioError(String path, int statusCode) {
  final opts = RequestOptions(path: path);
  return DioException(
    requestOptions: opts,
    response: Response(
      requestOptions: opts,
      statusCode: statusCode,
      data: {
        'success': false,
        'error': {'message': 'Error', 'code': 'ERROR'},
      },
    ),
    type: DioExceptionType.badResponse,
  );
}

//  Factory ─

AuthRepositoryImpl _makeRepo({
  required MockDioClient dioClient,
  required MockTokenStorage tokenStorage,
  required AppDatabase appDb,
  Dio? refreshDio,
}) =>
    AuthRepositoryImpl(
      dioClient: dioClient,
      refreshDio: refreshDio ?? MockDio(),
      tokenStorage: tokenStorage,
      // Wrap the real in-memory DB in a completed Future.
      appDatabase: Future.value(appDb),
    );

// ─

void main() {
  late MockDioClient mockClient;
  late MockTokenStorage mockStorage;
  late AppDatabase appDb;
  late AuthRepositoryImpl repo;

  setUpAll(() => initTestDatabase());

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockClient = createMockDioClient();
    mockStorage = MockTokenStorage();
    appDb = await AppDatabase.open();
    await appDb.clearUserData();

    // Default token storage stubs
    when(() => mockStorage.readAccessToken()).thenAnswer((_) async => null);
    when(() => mockStorage.readRefreshToken()).thenAnswer((_) async => null);
    when(() => mockStorage.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        )).thenAnswer((_) async {});
    when(() => mockStorage.clearTokens()).thenAnswer((_) async {});

    registerFallbackValue(RequestOptions(path: ''));

    repo = _makeRepo(
      dioClient: mockClient,
      tokenStorage: mockStorage,
      appDb: appDb,
    );
  });

  tearDown(() => appDb.close());

  // 
  // hasStoredSession
  // 
  group('hasStoredSession', () {
    test('returns false when no tokens are stored', () async {
      expect(await repo.hasStoredSession(), isFalse);
    });

    test('returns true when access token is present', () async {
      when(() => mockStorage.readAccessToken())
          .thenAnswer((_) async => 'access');
      expect(await repo.hasStoredSession(), isTrue);
    });

    test('returns true when refresh token is present (even without access)',
        () async {
      when(() => mockStorage.readRefreshToken())
          .thenAnswer((_) async => 'refresh');
      expect(await repo.hasStoredSession(), isTrue);
    });

    test('returns false when tokens are empty strings', () async {
      when(() => mockStorage.readAccessToken()).thenAnswer((_) async => '');
      when(() => mockStorage.readRefreshToken()).thenAnswer((_) async => '');
      expect(await repo.hasStoredSession(), isFalse);
    });
  });

  // 
  // login
  // 
  group('login', () {
    test('returns AuthSession on 200 success', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            ApiEndpoints.authLogin,
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async =>
          _successResponse(ApiEndpoints.authLogin, _authPayload()));

      final session =
          await repo.login(email: 'test@kise.app', password: 'secret');

      expect(session.user.email, 'test@kise.app');
      expect(session.tokens?.accessToken, 'test-access');
    });

    test('saves tokens to storage on successful login', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            ApiEndpoints.authLogin,
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async =>
          _successResponse(ApiEndpoints.authLogin, _authPayload()));

      await repo.login(email: 'test@kise.app', password: 'pass');

      verify(() => mockStorage.saveTokens(
            accessToken: 'test-access',
            refreshToken: 'test-refresh',
          )).called(1);
    });

    test('trims whitespace from email before sending', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            ApiEndpoints.authLogin,
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async =>
          _successResponse(ApiEndpoints.authLogin, _authPayload()));

      await repo.login(email: '  test@kise.app  ', password: 'pass');

      final captured = verify(() => mockClient.post<Map<String, dynamic>>(
            any(),
            data: captureAny(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).captured;
      final body = captured.first as Map<String, dynamic>;
      expect(body['email'], 'test@kise.app');
    });

    test('throws ApiException when DioException occurs', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            ApiEndpoints.authLogin,
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenThrow(_dioError(ApiEndpoints.authLogin, 401));

      await expectLater(
        repo.login(email: 'bad@kise.app', password: 'wrong'),
        throwsA(isA<ApiException>()),
      );
    });

    test('throws ApiException when response has invalid payload', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            ApiEndpoints.authLogin,
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => _successResponse(
            ApiEndpoints.authLogin,
            {'success': true, 'data': {'no_user': true}},
          ));

      await expectLater(
        repo.login(email: 'x@x.com', password: 'pass'),
        throwsA(isA<ApiException>()),
      );
    });
  });


  // register
 
  group('register', () {
    final request = RegisterRequest(
      firstName: 'Abel',
      lastName: 'Bekele',
      email: 'abel@kise.app',
      password: 'secure123',
      confirmPassword: 'secure123',
      university: 'AAU',
      department: 'CS',
      preferredLanguage: 'English',
      currency: 'ETB',
      termsAccepted: true,
    );

    test('returns AuthSession on 201 success', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            ApiEndpoints.authRegister,
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async =>
          _successResponse(ApiEndpoints.authRegister, _authPayload(),
              statusCode: 201));

      final session = await repo.register(request);
      expect(session.user.email, 'test@kise.app');
    });

    test('saves tokens on successful registration', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            ApiEndpoints.authRegister,
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async =>
          _successResponse(ApiEndpoints.authRegister, _authPayload(),
              statusCode: 201));

      await repo.register(request);

      verify(() => mockStorage.saveTokens(
            accessToken: 'test-access',
            refreshToken: 'test-refresh',
          )).called(1);
    });

    test('throws ApiException on DioException', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            ApiEndpoints.authRegister,
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenThrow(_dioError(ApiEndpoints.authRegister, 409));

      await expectLater(
        repo.register(request),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // 
  // logout
  // 
  group('logout', () {
    test('calls logout endpoint when refresh token is present', () async {
      when(() => mockStorage.readRefreshToken())
          .thenAnswer((_) async => 'valid-refresh');
      when(() => mockClient.post<Map<String, dynamic>>(
            ApiEndpoints.authLogout,
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => _successResponse(
            ApiEndpoints.authLogout, {'success': true, 'data': null}));

      await repo.logout();

      verify(() => mockClient.post<Map<String, dynamic>>(
            ApiEndpoints.authLogout,
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).called(1);
    });

    test('clears tokens even when logout endpoint throws', () async {
      when(() => mockStorage.readRefreshToken())
          .thenAnswer((_) async => 'refresh');
      when(() => mockClient.post<Map<String, dynamic>>(
            ApiEndpoints.authLogout,
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenThrow(Exception('network error'));

      await repo.logout();

      verify(() => mockStorage.clearTokens()).called(1);
    });

    test('does not call logout endpoint when no refresh token', () async {
      when(() => mockStorage.readRefreshToken()).thenAnswer((_) async => null);

      await repo.logout();

      verifyNever(() => mockClient.post<Map<String, dynamic>>(
            ApiEndpoints.authLogout,
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ));
      verify(() => mockStorage.clearTokens()).called(1);
    });
  });

  // 
  // fetchCurrentUser
  // 
  group('fetchCurrentUser', () {
    test('returns AuthUser on 200 success', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            ApiEndpoints.authMe,
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => _successResponse(
            ApiEndpoints.authMe,
            {'success': true, 'data': {'user': _testUser}},
          ));

      final user = await repo.fetchCurrentUser();
      expect(user.email, 'test@kise.app');
      expect(user.firstName, 'Abel');
    });

    test('throws ApiException when response lacks user object', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            ApiEndpoints.authMe,
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => _successResponse(
            ApiEndpoints.authMe,
            {'success': true, 'data': {}},
          ));

      await expectLater(
        repo.fetchCurrentUser(),
        throwsA(isA<ApiException>()),
      );
    });

    test('throws ApiException on 401', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            ApiEndpoints.authMe,
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenThrow(_dioError(ApiEndpoints.authMe, 401));

      await expectLater(
        repo.fetchCurrentUser(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // 
  // restoreSession
  // 
  group('restoreSession', () {
    test('returns null when no session is stored', () async {
      final session = await repo.restoreSession();
      expect(session, isNull);
    });

    test('returns AuthSession when fetchCurrentUser succeeds', () async {
      when(() => mockStorage.readAccessToken())
          .thenAnswer((_) async => 'access');
      when(() => mockClient.get<Map<String, dynamic>>(
            ApiEndpoints.authMe,
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => _successResponse(
            ApiEndpoints.authMe,
            {'success': true, 'data': {'user': _testUser}},
          ));

      final session = await repo.restoreSession();
      expect(session, isNotNull);
      expect(session!.user.email, 'test@kise.app');
    });

    test('clears session and returns null when 401 and refresh also fails',
        () async {
      when(() => mockStorage.readAccessToken())
          .thenAnswer((_) async => 'expired');

      // fetchCurrentUser throws 401
      when(() => mockClient.get<Map<String, dynamic>>(
            ApiEndpoints.authMe,
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenThrow(_dioError(ApiEndpoints.authMe, 401));

      // refreshSession fails (no refresh token)
      when(() => mockStorage.readRefreshToken()).thenAnswer((_) async => null);

      final session = await repo.restoreSession();
      expect(session, isNull);
      verify(() => mockStorage.clearTokens()).called(greaterThanOrEqualTo(1));
    });
  });
}