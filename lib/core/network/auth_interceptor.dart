import 'dart:async';

import 'package:dio/dio.dart';
import 'package:kise/core/network/api_endpoints.dart';
import 'package:kise/core/network/dio_client.dart';
import 'package:kise/features/auth/data/token_storage.dart';

typedef SessionExpiredCallback = void Function();

class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required TokenStorage tokenStorage,
    required Dio refreshDio,
    required SessionExpiredCallback onSessionExpired,
  })  : _tokenStorage = tokenStorage,
        _refreshDio = refreshDio,
        _onSessionExpired = onSessionExpired;

  final TokenStorage _tokenStorage;
  final Dio _refreshDio;
  final SessionExpiredCallback _onSessionExpired;

  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await _tokenStorage.readAccessToken();

    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final requestOptions = err.requestOptions;

    final isUnauthorized = response?.statusCode == 401;
    final isRefreshCall = requestOptions.path.contains(ApiEndpoints.authRefresh);
    final alreadyRetried = requestOptions.extra['retried'] == true;

    if (!isUnauthorized || isRefreshCall || alreadyRetried) {
      handler.next(err);
      return;
    }

    try {
      final refreshed = await _refreshTokensSingleFlight();

      if (!refreshed) {
        await _tokenStorage.clearTokens();
        _onSessionExpired();
        handler.next(err);
        return;
      }

      final newAccessToken = await _tokenStorage.readAccessToken();
      if (newAccessToken == null || newAccessToken.isEmpty) {
        await _tokenStorage.clearTokens();
        _onSessionExpired();
        handler.next(err);
        return;
      }

      final retryOptions = _cloneRequestOptions(requestOptions, newAccessToken);
      retryOptions.extra['retried'] = true;

      final retryResponse = await Dio(
        BaseOptions(
          baseUrl: requestOptions.baseUrl,
          connectTimeout: requestOptions.connectTimeout,
          receiveTimeout: requestOptions.receiveTimeout,
          sendTimeout: requestOptions.sendTimeout,
          headers: requestOptions.headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      ).fetch(retryOptions);

      handler.resolve(retryResponse);
    } catch (_) {
      await _tokenStorage.clearTokens();
      _onSessionExpired();
      handler.next(err);
    }
  }

  RequestOptions _cloneRequestOptions(
    RequestOptions requestOptions,
    String accessToken,
  ) {
    final headers = Map<String, dynamic>.from(requestOptions.headers);
    headers['Authorization'] = 'Bearer $accessToken';

    return RequestOptions(
      method: requestOptions.method,
      baseUrl: requestOptions.baseUrl,
      path: requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      headers: headers,
      extra: Map<String, dynamic>.from(requestOptions.extra),
      responseType: requestOptions.responseType,
      contentType: requestOptions.contentType,
      followRedirects: requestOptions.followRedirects,
      validateStatus: requestOptions.validateStatus,
      receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
      connectTimeout: requestOptions.connectTimeout,
      receiveTimeout: requestOptions.receiveTimeout,
      sendTimeout: requestOptions.sendTimeout,
    );
  }

  Future<bool> _refreshTokensSingleFlight() async {
    if (_isRefreshing) {
      final completer = _refreshCompleter;
      if (completer != null) {
        await completer.future;
        return (await _tokenStorage.readAccessToken()) != null;
      }
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<void>();

    try {
      final refreshToken = await _tokenStorage.readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      final response = await _refreshDio.post<Map<String, dynamic>>(
        ApiEndpoints.authRefresh,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode != 200) {
        return false;
      }

      final data = ApiEnvelopeParser.parseSuccessData(response);
      final tokensJson = data['tokens'];

      if (tokensJson is! Map<String, dynamic>) {
        return false;
      }

      final accessToken = tokensJson['accessToken']?.toString();
      final newRefreshToken = tokensJson['refreshToken']?.toString();

      if (accessToken == null ||
          accessToken.isEmpty ||
          newRefreshToken == null ||
          newRefreshToken.isEmpty) {
        return false;
      }

      await _tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: newRefreshToken,
      );

      return true;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
      _refreshCompleter?.complete();
      _refreshCompleter = null;
    }
  }
}