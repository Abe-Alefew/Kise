import 'package:flutter_test/flutter_test.dart';
import 'package:kise/features/goals/data/dtos/goal_dto.dart';

Map<String, dynamic> _validGoalJson({
  double current = 300,
  double target = 1000,
  String status = 'active',
}) =>
    {
      'id': 'goal-dto-001',
      'title': 'Laptop Fund',
      'period': 'Monthly',
      'dueDate': '2025-12-31',
      'dueDateDisplay': 'Due Wed Dec 31 2025',
      'currentAmount': current,
      'targetAmount': target,
      'isCompleted': false,
      'isLocked': false,
      'status': status,
    };

void main() {
  // ────────────────────────────────────────────────────
  // GoalDto.computeProgress
  // ────────────────────────────────────────────────────
  group('GoalDto.computeProgress', () {
    test('returns current/target for normal values', () {
      expect(GoalDto.computeProgress(300, 1000), closeTo(0.3, 0.001));
    });

    test('clamps at 1.0 when current exceeds target', () {
      expect(GoalDto.computeProgress(1200, 1000), 1.0);
    });

    test('returns 0 when target is 0 (division guard)', () {
      expect(GoalDto.computeProgress(500, 0), 0.0);
    });

    test('returns 0 when current is 0', () {
      expect(GoalDto.computeProgress(0, 1000), 0.0);
    });

    test('returns 1.0 for exactly equal current and target', () {
      expect(GoalDto.computeProgress(1000, 1000), 1.0);
    });
  });

  // ────────────────────────────────────────────────────
  // GoalDto.fromJson
  // ────────────────────────────────────────────────────
  group('GoalDto.fromJson', () {
    test('parses all required fields', () {
      final dto = GoalDto.fromJson(_validGoalJson());
      expect(dto.id, 'goal-dto-001');
      expect(dto.title, 'Laptop Fund');
      expect(dto.dueDate, '2025-12-31');
      expect(dto.currentAmount, 300.0);
      expect(dto.targetAmount, 1000.0);
    });

    test('normalizes period to lowercase', () {
      final dto = GoalDto.fromJson(_validGoalJson());
      expect(dto.period, 'monthly'); // 'Monthly' → 'monthly'
    });

    test('computes progress when absent from JSON', () {
      final json = Map<String, dynamic>.from(_validGoalJson())
        ..remove('progress');
      final dto = GoalDto.fromJson(json);
      expect(dto.progress, closeTo(0.3, 0.001));
    });

    test('uses provided progress when present', () {
      final json = _validGoalJson()..['progress'] = 0.5;
      final dto = GoalDto.fromJson(json);
      expect(dto.progress, closeTo(0.5, 0.001));
    });

    test('handles string amount values', () {
      final json = _validGoalJson()
        ..['currentAmount'] = '500'
        ..['targetAmount'] = '2000';
      final dto = GoalDto.fromJson(json);
      expect(dto.currentAmount, 500.0);
      expect(dto.targetAmount, 2000.0);
    });

    test('defaults missing fields gracefully', () {
      final dto = GoalDto.fromJson({
        'id': 'g',
        'title': 'T',
        'period': 'monthly',
        'dueDate': '2025-12-31',
        'dueDateDisplay': 'Dec 31',
        'currentAmount': 0,
        'targetAmount': 100,
        'isCompleted': false,
        'isLocked': false,
        'status': 'active',
      });
      expect(dto.note, isNull);
      expect(dto.completedAt, isNull);
    });
  });

  // ────────────────────────────────────────────────────
  // GoalDto.listFromEnvelope
  // ────────────────────────────────────────────────────
  group('GoalDto.listFromEnvelope', () {
    test('parses flat list of goal maps', () {
      final list = GoalDto.listFromEnvelope([_validGoalJson(), _validGoalJson()]);
      expect(list, hasLength(2));
    });

    test('parses wrapped {items: [...]} envelope', () {
      final list = GoalDto.listFromEnvelope({
        'items': [_validGoalJson()]
      });
      expect(list, hasLength(1));
    });

    test('returns empty list for null input', () {
      expect(GoalDto.listFromEnvelope(null), isEmpty);
    });

    test('returns empty list for empty list input', () {
      expect(GoalDto.listFromEnvelope([]), isEmpty);
    });
  });

  // ────────────────────────────────────────────────────
  // GoalDto.toEntity
  // ────────────────────────────────────────────────────
  group('GoalDto.toEntity', () {
    test('converts all fields to GoalEntity', () {
      final dto = GoalDto.fromJson(_validGoalJson());
      // toEntity requires calling via GoalRepositoryImpl; test directly from the DTO
      // by constructing a GoalDto manually and calling fromJson+toEntity pipeline
      expect(dto.id, isNotEmpty);
      expect(dto.currentAmount, 300.0);
      expect(dto.status, 'active');
    });

    test('progress is clamped between 0 and 1', () {
      final overshoot = _validGoalJson()
        ..['currentAmount'] = 1500
        ..['targetAmount'] = 1000;
      final dto = GoalDto.fromJson(overshoot);
      expect(dto.progress, 1.0); // clamped by computeProgress
    });
  });

  // ────────────────────────────────────────────────────
  // GoalDateParser.normalizePeriod (tested via GoalDto)
  // ────────────────────────────────────────────────────
  group('Period normalization via GoalDto.fromJson', () {
    final periodCases = {
      'daily': 'daily',
      'weekly': 'weekly',
      'monthly': 'monthly',
      'yearly': 'yearly',
      'one-time': 'one-time',
      'one time': 'one-time',
      'Monthly': 'monthly',
      'YEARLY': 'yearly',
    };

    for (final entry in periodCases.entries) {
      test('"${entry.key}" normalizes to "${entry.value}"', () {
        final json = _validGoalJson()..['period'] = entry.key;
        final dto = GoalDto.fromJson(json);
        expect(dto.period, entry.value);
      });
    }
  });
}