import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kise/core/network/dio_client.dart';

void main() {
  // ────────────────────────────────────────────────────
  // ApiException basic behaviour
  // ────────────────────────────────────────────────────
  group('ApiException', () {
    test('toString includes code and message', () {
      const ex = ApiException(message: 'Not found', code: 'NOT_FOUND');
      expect(ex.toString(), contains('NOT_FOUND'));
      expect(ex.toString(), contains('Not found'));
    });

    test('userMessage returns message when details are empty', () {
      const ex = ApiException(message: 'Server error', code: 'SERVER_ERROR');
      expect(ex.userMessage, 'Server error');
    });

    test('userMessage returns formatted detail lines for VALIDATION_ERROR', () {
      const ex = ApiException(
        message: 'Request validation failed',
        code: 'VALIDATION_ERROR',
        details: [
          ApiFieldError(field: 'title', message: 'is required'),
          ApiFieldError(field: 'amount', message: 'must be positive'),
        ],
      );
      final msg = ex.userMessage;
      expect(msg, contains('Title: is required'));
      expect(msg, contains('Amount: must be positive'));
      // Should NOT start with the envelope message for VALIDATION_ERROR
      expect(msg, isNot(contains('Request validation failed\n')));
    });

    test('userMessage includes envelope + detail lines for other codes', () {
      const ex = ApiException(
        message: 'Something went wrong',
        code: 'CUSTOM_ERROR',
        details: [
          ApiFieldError(field: 'email', message: 'already taken'),
        ],
      );
      expect(ex.userMessage, contains('Something went wrong'));
      expect(ex.userMessage, contains('already taken'));
    });

    test('statusCode is accessible', () {
      const ex =
          ApiException(message: 'Forbidden', code: 'FORBIDDEN', statusCode: 403);
      expect(ex.statusCode, 403);
    });

    test('details defaults to empty list', () {
      const ex = ApiException(message: 'test', code: 'TEST');
      expect(ex.details, isEmpty);
    });
  });

  // ────────────────────────────────────────────────────
  // ApiFieldError
  // ────────────────────────────────────────────────────
  group('ApiFieldError.fromJson', () {
    test('parses field and message', () {
      final err = ApiFieldError.fromJson({'field': 'email', 'message': 'invalid'});
      expect(err.field, 'email');
      expect(err.message, 'invalid');
    });

    test('defaults message to "Invalid value" when missing', () {
      final err = ApiFieldError.fromJson({'field': 'name'});
      expect(err.message, 'Invalid value');
    });

    test('defaults field to empty string when missing', () {
      final err = ApiFieldError.fromJson({'message': 'bad input'});
      expect(err.field, '');
    });
  });

  // ────────────────────────────────────────────────────
  // ApiEnvelopeParser
  // ────────────────────────────────────────────────────
  group('ApiEnvelopeParser.parseErrorFromMap', () {
    test('parses structured error envelope', () {
      final body = {
        'error': {
          'message': 'Unauthorized',
          'code': 'UNAUTHORIZED',
          'details': [],
        }
      };
      final ex = ApiEnvelopeParser.parseErrorFromMap(body, 401);
      expect(ex.message, 'Unauthorized');
      expect(ex.code, 'UNAUTHORIZED');
      expect(ex.statusCode, 401);
    });

    test('parses error with field details', () {
      final body = {
        'error': {
          'message': 'Validation failed',
          'code': 'VALIDATION_ERROR',
          'details': [
            {'field': 'title', 'message': 'required'},
          ],
        }
      };
      final ex = ApiEnvelopeParser.parseErrorFromMap(body, 422);
      expect(ex.details, hasLength(1));
      expect(ex.details.first.field, 'title');
    });

    test('falls back to generic error when error is not a map', () {
      final body = {'error': 'something went wrong'};
      final ex = ApiEnvelopeParser.parseErrorFromMap(body, 500);
      expect(ex.message, 'Request failed');
      expect(ex.code, 'REQUEST_ERROR');
    });
  });

  group('ApiEnvelopeParser.parseDioError', () {
    test('returns TIMEOUT for connectionTimeout', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );
      final ex = ApiEnvelopeParser.parseDioError(dioError);
      expect(ex.code, 'TIMEOUT');
    });

    test('returns CONNECTION_ERROR for connectionError', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionError,
      );
      final ex = ApiEnvelopeParser.parseDioError(dioError);
      expect(ex.code, 'CONNECTION_ERROR');
    });

    test('returns REQUEST_CANCELLED for cancel', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.cancel,
      );
      final ex = ApiEnvelopeParser.parseDioError(dioError);
      expect(ex.code, 'REQUEST_CANCELLED');
    });

    test('returns NETWORK_ERROR for unknown DioExceptionType', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.unknown,
        message: 'Unknown error',
      );
      final ex = ApiEnvelopeParser.parseDioError(dioError);
      expect(ex.code, 'NETWORK_ERROR');
    });
  });

  group('ApiEnvelopeParser._fieldLabel (via userMessage)', () {
    void expectLabel(String field, String expectedLabel) {
      final ex = ApiException(
        message: 'validation',
        code: 'VALIDATION_ERROR',
        details: [ApiFieldError(field: field, message: 'error')],
      );
      expect(ex.userMessage, contains('$expectedLabel: error'));
    }

    test('title field → "Title"', () => expectLabel('title', 'Title'));
    test('targetAmount field → "Target amount"',
        () => expectLabel('targetAmount', 'Target amount'));
    test('currentAmount field → "Current amount"',
        () => expectLabel('currentAmount', 'Current amount'));
    test('dueDate field → "Due date"',
        () => expectLabel('dueDate', 'Due date'));
    test('amount field → "Amount"', () => expectLabel('amount', 'Amount'));
    test('source field → "Source"', () => expectLabel('source', 'Source'));

    test('unknown field capitalizes first letter', () {
      final ex = ApiException(
        message: 'validation',
        code: 'VALIDATION_ERROR',
        details: [ApiFieldError(field: 'customField', message: 'bad')],
      );
      expect(ex.userMessage, contains('CustomField: bad'));
    });

    test('empty field omits label prefix', () {
      final ex = ApiException(
        message: 'validation',
        code: 'VALIDATION_ERROR',
        details: [ApiFieldError(field: '', message: 'general error')],
      );
      expect(ex.userMessage, contains('general error'));
      expect(ex.userMessage, isNot(contains(': general error')));
    });
  });
}
