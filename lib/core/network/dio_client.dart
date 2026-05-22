import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kise/core/network/api_endpoints.dart';
import 'package:kise/core/network/auth_interceptor.dart';
import 'package:kise/features/auth/data/token_storage.dart';
import 'package:kise/features/auth/presentation/providers/auth_notifier.dart';

class ApiException implements Exception {
  final String message;
  final String code;
  final int? statusCode;
  final List<ApiFieldError> details;

  const ApiException({
    required this.message,
    required this.code,
    this.statusCode,
    this.details = const [],
  });

  @override
  String toString() => 'ApiException($code): $message';
}

class ApiFieldError {
  final String field;
  final String message;

  const ApiFieldError({
    required this.field,
    required this.message,
  });

  factory ApiFieldError.fromJson(Map<String, dynamic> json) {
    return ApiFieldError(
      field: json['field']?.toString() ?? '',
      message: json['message']?.toString() ?? 'Invalid value',
    );
  }
}

class ApiEnvelopeParser {
  static Map<String, dynamic> parseSuccessData(Response<dynamic> response) {
    final body = response.data;

    if (body is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Invalid server response format',
        code: 'INVALID_RESPONSE',
      );
    }

    final success = body['success'] == true;
    if (!success) {
      throw parseErrorFromMap(body, response.statusCode);
    }

    final data = body['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data == null) {
      return <String, dynamic>{};
    }

    throw const ApiException(
      message: 'Invalid success payload',
      code: 'INVALID_RESPONSE',
    );
  }

  static ApiException parseDioError(DioException error) {
    final response = error.response;

    if (response?.data is Map<String, dynamic>) {
      return parseErrorFromMap(
        response!.data as Map<String, dynamic>,
        response.statusCode,
      );
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message: 'Request timed out. Check your connection and try again.',
          code: 'TIMEOUT',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          message: 'Unable to reach the server. Check your internet connection.',
          code: 'CONNECTION_ERROR',
        );
      case DioExceptionType.cancel:
        return const ApiException(
          message: 'Request was cancelled',
          code: 'REQUEST_CANCELLED',
        );
      default:
        return ApiException(
          message: error.message ?? 'Unexpected network error',
          code: 'NETWORK_ERROR',
          statusCode: response?.statusCode,
        );
    }
  }

  static ApiException parseErrorFromMap(
    Map<String, dynamic> body,
    int? statusCode,
  ) {
    final error = body['error'];

    if (error is Map<String, dynamic>) {
      final detailsJson = error['details'];
      final details = detailsJson is List
          ? detailsJson
              .whereType<Map<String, dynamic>>()
              .map(ApiFieldError.fromJson)
              .toList()
          : <ApiFieldError>[];

      return ApiException(
        message: error['message']?.toString() ?? 'Request failed',
        code: error['code']?.toString() ?? 'REQUEST_ERROR',
        statusCode: statusCode,
        details: details,
      );
    }

    return ApiException(
      message: 'Request failed',
      code: 'REQUEST_ERROR',
      statusCode: statusCode,
    );
  }
}

class DioClient {
  DioClient._(this._dio);

  final Dio _dio;

  Dio get dio => _dio;

  static Dio createBaseDio({
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 20),
    Duration sendTimeout = const Duration(seconds: 20),
  }) {
    return Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        sendTimeout: sendTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

final refreshDioProvider = Provider<Dio>((ref) {
  return DioClient.createBaseDio();
});

final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  return AuthInterceptor(
    tokenStorage: ref.watch(tokenStorageProvider),
    refreshDio: ref.watch(refreshDioProvider),
    onSessionExpired: () {
      ref.read(authNotifierProvider.notifier).onSessionExpired();
    },
  );
});

final dioProvider = Provider<Dio>((ref) {
  final dio = DioClient.createBaseDio();
  dio.interceptors.add(ref.watch(authInterceptorProvider));
  return dio;
});

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient._(ref.watch(dioProvider));
});