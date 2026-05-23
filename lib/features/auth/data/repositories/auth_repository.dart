import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kise/core/database/app_database.dart';
import 'package:kise/core/network/api_endpoints.dart';
import 'package:kise/core/network/dio_client.dart';
import 'package:kise/features/auth/data/datasources/token_storage.dart';
import 'package:kise/features/auth/domain/auth_models.dart';

abstract class AuthRepository {
  Future<AuthSession> register(RegisterRequest request);

  Future<AuthSession> login({
    required String email,
    required String password,
  });

  Future<AuthSession> refreshSession();

  Future<AuthUser> fetchCurrentUser();

  Future<void> logout();

  Future<bool> hasStoredSession();

  Future<AuthSession?> restoreSession();
}

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required DioClient dioClient,
    required Dio refreshDio,
    required TokenStorage tokenStorage,
    required Future<AppDatabase> appDatabase,
  })  : _dioClient = dioClient,
        _refreshDio = refreshDio,
        _tokenStorage = tokenStorage,
        _appDatabaseFuture = appDatabase;

  final DioClient _dioClient;
  final Dio _refreshDio;
  final TokenStorage _tokenStorage;
  final Future<AppDatabase> _appDatabaseFuture;

  @override
  Future<AuthSession> register(RegisterRequest request) async {
    try {
      final response = await _dioClient.post<Map<String, dynamic>>(
        ApiEndpoints.authRegister,
        data: request.toJson(),
      );

      if (response.statusCode != 201) {
        throw _unexpectedStatus(response);
      }

      final data = ApiEnvelopeParser.parseSuccessData(response);
      return await _persistSessionFromAuthPayload(data);
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw ApiEnvelopeParser.parseDioError(error);
    } catch (error) {
      throw ApiException(
        message: 'Registration failed: ${error.toString()}',
        code: 'SESSION_ERROR',
      );
    }
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dioClient.post<Map<String, dynamic>>(
        ApiEndpoints.authLogin,
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      if (response.statusCode != 200) {
        throw _unexpectedStatus(response);
      }

      final data = ApiEnvelopeParser.parseSuccessData(response);
      return await _persistSessionFromAuthPayload(data);
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw ApiEnvelopeParser.parseDioError(error);
    } catch (error) {
      throw ApiException(
        message: 'Login failed: ${error.toString()}',
        code: 'SESSION_ERROR',
      );
    }
  }

  @override
  Future<AuthSession> refreshSession() async {
    final refreshToken = await _tokenStorage.readRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      throw const ApiException(
        message: 'No refresh token available',
        code: 'UNAUTHORIZED',
        statusCode: 401,
      );
    }

    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        ApiEndpoints.authRefresh,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode != 200) {
        throw _unexpectedStatus(response);
      }

      final data = ApiEnvelopeParser.parseSuccessData(response);
      return _persistSessionFromAuthPayload(data);
    } on DioException catch (error) {
      throw ApiEnvelopeParser.parseDioError(error);
    }
  }

  @override
  Future<AuthUser> fetchCurrentUser() async {
    try {
      final response = await _dioClient.get<Map<String, dynamic>>(
        ApiEndpoints.authMe,
      );

      if (response.statusCode != 200) {
        throw _unexpectedStatus(response);
      }

      final data = ApiEnvelopeParser.parseSuccessData(response);
      final userJson = data['user'];

      if (userJson is! Map<String, dynamic>) {
        throw const ApiException(
          message: 'Missing user payload',
          code: 'INVALID_RESPONSE',
        );
      }

      final user = AuthUser.fromJson(userJson);
      _cacheUserLocally(user).ignore();
      return user;
    } on DioException catch (error) {
      throw ApiEnvelopeParser.parseDioError(error);
    }
  }

  @override
  Future<void> logout() async {
    final refreshToken = await _tokenStorage.readRefreshToken();

    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _dioClient.post<Map<String, dynamic>>(
          ApiEndpoints.authLogout,
          data: {'refreshToken': refreshToken},
        );
      }
    } catch (_) {
    } finally {
      await clearLocalSession();
    }
  }

  @override
  Future<bool> hasStoredSession() async {
    final accessToken = await _tokenStorage.readAccessToken();
    final refreshToken = await _tokenStorage.readRefreshToken();
    return (accessToken != null && accessToken.isNotEmpty) ||
        (refreshToken != null && refreshToken.isNotEmpty);
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final hasSession = await hasStoredSession();
    if (!hasSession) {
      return null;
    }

    try {
      final user = await fetchCurrentUser();
      return AuthSession(user: user);
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        try {
          return await refreshSession();
        } catch (_) {
          await clearLocalSession();
          return null;
        }
      }
      rethrow;
    }
  }

  Future<void> clearLocalSession() async {
    await _tokenStorage.clearTokens();
    try {
      final db = await _appDatabaseFuture.timeout(const Duration(seconds: 5));
      await db.clearUserData();
    } catch (_) {}
  }

  Future<AuthSession> _persistSessionFromAuthPayload(
    Map<String, dynamic> data,
  ) async {
    final userJson = data['user'];
    final tokensJson = data['tokens'];

    if (userJson is! Map<String, dynamic> || tokensJson is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Invalid authentication payload',
        code: 'INVALID_RESPONSE',
      );
    }

    final user = AuthUser.fromJson(userJson);
    final tokens = AuthTokens.fromJson(tokensJson);

    await _tokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );

    _cacheUserLocally(user).ignore();

    return AuthSession(user: user, tokens: tokens);
  }

  Future<void> _cacheUserLocally(AuthUser user) async {
    try {
      final db = await _appDatabaseFuture.timeout(const Duration(seconds: 5));
      await db.upsertUser(
        id: user.id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        phone: user.phone,
        username: user.username,
        university: user.university,
        department: user.department,
        currency: user.currency,
        preferredLanguage: user.preferredLanguage,
        themeMode: user.themeMode,
      );
    } catch (_) {}
  }

  ApiException _unexpectedStatus(Response<dynamic> response) {
    if (response.data is Map<String, dynamic>) {
      return ApiEnvelopeParser.parseErrorFromMap(
        response.data as Map<String, dynamic>,
        response.statusCode,
      );
    }

    return ApiException(
      message: 'Request failed with status ${response.statusCode}',
      code: 'REQUEST_ERROR',
      statusCode: response.statusCode,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final refreshDio = ref.watch(refreshDioProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);

  return AuthRepositoryImpl(
    dioClient: dioClient,
    refreshDio: refreshDio,
    tokenStorage: tokenStorage,
    appDatabase: ref.watch(appDatabaseProvider.future),
  );
});