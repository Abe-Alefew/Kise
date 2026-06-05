import 'package:flutter_test/flutter_test.dart';
import 'package:kise/core/widgets/kise_form_system/form_validation.dart';

void main() {
  // ────────────────────────────────────────────────────
  // Validators.requiredField
  // ────────────────────────────────────────────────────
  group('Validators.requiredField', () {
    test('returns null when value is non-empty', () {
      expect(Validators.requiredField('hello'), isNull);
    });

    test('returns error message when value is null', () {
      expect(Validators.requiredField(null), 'This field is required');
    });

    test('returns error message when value is empty string', () {
      expect(Validators.requiredField(''), 'This field is required');
    });

    test('returns null for whitespace-only string', () {
      // Whitespace is truthy — requiredField only checks isEmpty
      expect(Validators.requiredField('   '), isNull);
    });

    test('returns null for single character', () {
      expect(Validators.requiredField('a'), isNull);
    });
  });

  // ────────────────────────────────────────────────────
  // Validators.email
  // ────────────────────────────────────────────────────
  group('Validators.email', () {
    test('returns null for well-formed email', () {
      expect(Validators.email('test@example.com'), isNull);
    });

    test('returns error for null value', () {
      expect(Validators.email(null), 'Enter a valid email');
    });

    test('returns error when @ is missing', () {
      expect(Validators.email('notanemail'), 'Enter a valid email');
    });

    test('returns null when @ is present anywhere', () {
      // Implementation only checks for presence of '@', not full RFC validation
      expect(Validators.email('@'), isNull);
      expect(Validators.email('a@'), isNull);
      expect(Validators.email('@b'), isNull);
    });

    test('returns error for empty string', () {
      expect(Validators.email(''), 'Enter a valid email');
    });
  });

  // ────────────────────────────────────────────────────
  // Validators.password
  // ────────────────────────────────────────────────────
  group('Validators.password', () {
    test('returns null for password with exactly 6 characters', () {
      expect(Validators.password('abc123'), isNull);
    });

    test('returns null for password longer than 6 characters', () {
      expect(Validators.password('securepassword!'), isNull);
    });

    test('returns error for null value', () {
      expect(Validators.password(null),
          'Password must be at least 6 characters');
    });

    test('returns error for password with 5 characters', () {
      expect(Validators.password('abc12'),
          'Password must be at least 6 characters');
    });

    test('returns error for empty string', () {
      expect(Validators.password(''), 'Password must be at least 6 characters');
    });

    test('boundary: 7-character password is accepted', () {
      expect(Validators.password('abc1234'), isNull);
    });
  });
}
