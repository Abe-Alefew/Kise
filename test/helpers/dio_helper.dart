// Mock Dio client factory for unit and provider tests.
//
// DioClient has a private constructor so we mock it directly at the
// DioClient level rather than wrapping a MockDio.
//
// Usage:
//   final mockClient = createMockDioClient();
//   stubGetSuccess(mockClient, '/goals', {'items': []});
//   stubPostSuccess(mockClient, '/auth/login', {'tokens': {...}});
//   stubError(mockClient, '/transactions', statusCode: 404);
//
// Inject via:
//   dioClientProvider.overrideWithValue(mockClient)

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:kise/core/network/dio_client.dart';

// ── Mock class ─────────────────────────────────────────────────────────────────

class MockDioClient extends Mock implements DioClient {}

// ── Factory ───────────────────────────────────────────────────────────────────

/// Creates a [MockDioClient] with fallback values pre-registered.
/// Call once per test (or in [setUp]).
MockDioClient createMockDioClient() {
  final client = MockDioClient();
  // Register fallback values for all named parameters so any(named:) works.
  registerFallbackValue(<String, dynamic>{});
  registerFallbackValue(Options());
  return client;
}

// ── Envelope helpers ──────────────────────────────────────────────────────────

/// Wraps [data] in the standard Kise API success envelope:
/// `{ "success": true, "data": <data> }`
Map<String, dynamic> successEnvelope(dynamic data) => {
      'success': true,
      'data': data,
    };

/// Wraps an error in the standard Kise API error envelope.
Map<String, dynamic> errorEnvelope({
  required String message,
  String code = 'REQUEST_ERROR',
  List<Map<String, dynamic>> details = const [],
}) =>
    {
      'success': false,
      'error': {
        'message': message,
        'code': code,
        if (details.isNotEmpty) 'details': details,
      },
    };

// ── Response builder ──────────────────────────────────────────────────────────

Response<Map<String, dynamic>> _makeResponse(
  String path,
  int statusCode,
  dynamic data,
) =>
    Response<Map<String, dynamic>>(
      requestOptions: RequestOptions(path: path),
      statusCode: statusCode,
      data: data,
    );

DioException _makeDioError(String path, int statusCode, dynamic data) =>
    DioException(
      requestOptions: RequestOptions(path: path),
      response: _makeResponse(path, statusCode, data),
      type: DioExceptionType.badResponse,
    );

// ── GET stubs ─────────────────────────────────────────────────────────────────

/// Stubs `client.get(path, ...)` to return a 200 success envelope with [data].
void stubGetSuccess(
  MockDioClient client,
  String path,
  dynamic data, {
  int statusCode = 200,
}) {
  when(() => client.get<Map<String, dynamic>>(
        path,
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      )).thenAnswer(
    (_) async => _makeResponse(path, statusCode, successEnvelope(data)),
  );
}

/// Stubs `client.get(path, ...)` to throw a [DioException] with an error envelope.
void stubGetError(
  MockDioClient client,
  String path, {
  int statusCode = 400,
  String message = 'Bad request',
  String code = 'REQUEST_ERROR',
  List<Map<String, dynamic>> details = const [],
}) {
  when(() => client.get<Map<String, dynamic>>(
        path,
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      )).thenThrow(
    _makeDioError(
      path,
      statusCode,
      errorEnvelope(message: message, code: code, details: details),
    ),
  );
}

// ── POST stubs ────────────────────────────────────────────────────────────────

/// Stubs `client.post(path, ...)` to return a success envelope with [data].
void stubPostSuccess(
  MockDioClient client,
  String path,
  dynamic data, {
  int statusCode = 200,
}) {
  when(() => client.post<Map<String, dynamic>>(
        path,
        data: any(named: 'data'),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      )).thenAnswer(
    (_) async => _makeResponse(path, statusCode, successEnvelope(data)),
  );
}

/// Stubs `client.post(path, ...)` to throw a [DioException].
void stubPostError(
  MockDioClient client,
  String path, {
  int statusCode = 400,
  String message = 'Bad request',
  String code = 'REQUEST_ERROR',
  List<Map<String, dynamic>> details = const [],
}) {
  when(() => client.post<Map<String, dynamic>>(
        path,
        data: any(named: 'data'),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      )).thenThrow(
    _makeDioError(
      path,
      statusCode,
      errorEnvelope(message: message, code: code, details: details),
    ),
  );
}

// ── PUT stubs ─────────────────────────────────────────────────────────────────

/// Stubs `client.put(path, ...)` to return a success envelope.
void stubPutSuccess(
  MockDioClient client,
  String path,
  dynamic data, {
  int statusCode = 200,
}) {
  when(() => client.put<Map<String, dynamic>>(
        path,
        data: any(named: 'data'),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      )).thenAnswer(
    (_) async => _makeResponse(path, statusCode, successEnvelope(data)),
  );
}

/// Stubs `client.put(path, ...)` to throw a [DioException].
void stubPutError(
  MockDioClient client,
  String path, {
  int statusCode = 400,
  String message = 'Bad request',
  String code = 'REQUEST_ERROR',
}) {
  when(() => client.put<Map<String, dynamic>>(
        path,
        data: any(named: 'data'),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      )).thenThrow(
    _makeDioError(
        path, statusCode, errorEnvelope(message: message, code: code)),
  );
}

// ── PATCH stubs ───────────────────────────────────────────────────────────────

/// Stubs `client.patch(path, ...)` to return a success envelope.
void stubPatchSuccess(
  MockDioClient client,
  String path,
  dynamic data, {
  int statusCode = 200,
}) {
  when(() => client.patch<Map<String, dynamic>>(
        path,
        data: any(named: 'data'),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      )).thenAnswer(
    (_) async => _makeResponse(path, statusCode, successEnvelope(data)),
  );
}

// ── DELETE stubs ──────────────────────────────────────────────────────────────

/// Stubs `client.delete(path, ...)` to return a 204 with no body.
void stubDeleteSuccess(
  MockDioClient client,
  String path, {
  int statusCode = 204,
}) {
  when(() => client.delete<Map<String, dynamic>>(
        path,
        data: any(named: 'data'),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      )).thenAnswer(
    (_) async => _makeResponse(path, statusCode, null),
  );
}

/// Stubs `client.delete(path, ...)` to throw a [DioException].
void stubDeleteError(
  MockDioClient client,
  String path, {
  int statusCode = 404,
  String message = 'Not found',
  String code = 'NOT_FOUND',
}) {
  when(() => client.delete<Map<String, dynamic>>(
        path,
        data: any(named: 'data'),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      )).thenThrow(
    _makeDioError(
        path, statusCode, errorEnvelope(message: message, code: code)),
  );
}

// ── Timeout stub ──────────────────────────────────────────────────────────────

/// Stubs `client.get(path, ...)` to throw a connection-timeout [DioException].
/// Use to test offline-first fallback / cache behaviour.
void stubTimeout(MockDioClient client, String path) {
  when(() => client.get<Map<String, dynamic>>(
        path,
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      )).thenThrow(
    DioException(
      requestOptions: RequestOptions(path: path),
      type: DioExceptionType.connectionTimeout,
    ),
  );
}
