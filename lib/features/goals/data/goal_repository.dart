import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kise/core/cache/cache_policy.dart';
import 'package:kise/core/database/app_database.dart';
import 'package:kise/core/database/daos/goal_cache_dao.dart';
import 'package:kise/core/network/api_endpoints.dart';
import 'package:kise/core/network/dio_client.dart';
import 'package:kise/features/auth/presentation/providers/auth_notifier.dart';
import 'package:kise/features/goals/data/goal_dto.dart';
import 'package:kise/features/goals/domain/goal_entity.dart';
import 'package:kise/features/goals/domain/goal_filters.dart';
import 'package:kise/features/goals/domain/goal_inputs.dart';
import 'package:uuid/uuid.dart';

class GoalListResult {
  final List<GoalEntity> items;
  final bool fromCache;
  final bool isStale;

  const GoalListResult({
    required this.items,
    required this.fromCache,
    required this.isStale,
  });
}

class GoalDepositResult {
  final GoalEntity goal;
  final GoalDepositEntity deposit;

  const GoalDepositResult({
    required this.goal,
    required this.deposit,
  });
}

abstract class GoalRepository {
  Future<GoalListResult> getGoals({
    required GoalStatusFilter status,
    bool forceRefresh = false,
  });

  Future<GoalEntity> createGoal(CreateGoalInput input);

  Future<GoalEntity> updateGoal(String goalId, UpdateGoalInput input);

  Future<void> deleteGoal(String goalId);

  Future<GoalDepositResult> logDeposit(
    String goalId,
    LogDepositInput input,
  );
}

class GoalRepositoryImpl implements GoalRepository {
  GoalRepositoryImpl({
    required DioClient dioClient,
    required Future<AppDatabase> appDatabase,
    required String? Function() currentUserId,
    CachePolicy? cachePolicy,
    Uuid? uuid,
  })  : _dioClient = dioClient,
        _appDatabaseFuture = appDatabase,
        _currentUserId = currentUserId,
        _cachePolicy = cachePolicy ?? const CachePolicy(),
        _uuid = uuid ?? const Uuid();

  final DioClient _dioClient;
  final Future<AppDatabase> _appDatabaseFuture;
  final String? Function() _currentUserId;
  final CachePolicy _cachePolicy;
  final Uuid _uuid;

  Future<GoalCacheDao> _dao() async {
    final db = await _appDatabaseFuture;
    await GoalCacheDao.ensureSchema(db.database);
    return GoalCacheDao(db.database);
  }

  String _requireUserId() {
    final userId = _currentUserId();
    if (userId == null || userId.isEmpty) {
      throw const ApiException(
        message: 'You must be signed in to access goals',
        code: 'UNAUTHORIZED',
        statusCode: 401,
      );
    }
    return userId;
  }

  @override
  Future<GoalListResult> getGoals({
    required GoalStatusFilter status,
    bool forceRefresh = false,
  }) async {
    final userId = _requireUserId();
    final dao = await _dao();

    final cachedRows = await dao.queryGoals(
      userId: userId,
      status: status.apiValue,
    );

    final lastSyncAt = await dao.getLastSyncAt();
    final cacheIsFresh = !forceRefresh &&
        _cachePolicy.isFresh(lastSyncAt) &&
        cachedRows.isNotEmpty;

    if (cacheIsFresh) {
      return GoalListResult(
        items: cachedRows
            .map(GoalDto.fromCacheRow)
            .map((dto) => dto.toEntity())
            .toList(),
        fromCache: true,
        isStale: false,
      );
    }

    try {
      final response = await _dioClient.get<Map<String, dynamic>>(
        ApiEndpoints.goals,
        queryParameters: status.toQueryParameters(),
      );

      if (response.statusCode != 200) {
        throw _unexpectedStatus(response);
      }

      final envelopeData = ApiEnvelopeParser.parseSuccessData(response);
      final serverGoals = GoalDto.listFromEnvelope(envelopeData);
      final syncedAt = DateTime.now().toUtc();

      await dao.replaceAllGoalsForUser(
        userId,
        serverGoals
            .map(
              (goal) => goal.toCacheRow(
                userId: userId,
                syncedAt: syncedAt,
                isDirty: false,
              ),
            )
            .toList(),
      );
      await dao.setLastSyncAt(syncedAt);

      final dirtyRows = await dao.getDirtyGoals(userId);
      final dirtyEntities = dirtyRows
          .map(GoalDto.fromCacheRow)
          .map((dto) => dto.toEntity(isDirty: true))
          .toList();

      return GoalListResult(
        items: _mergeServerAndDirty(
          serverItems: serverGoals.map((dto) => dto.toEntity()).toList(),
          dirtyItems: dirtyEntities,
          status: status,
        ),
        fromCache: false,
        isStale: false,
      );
    } on DioException catch (error) {
      if (cachedRows.isNotEmpty) {
        return GoalListResult(
          items: cachedRows
              .map(GoalDto.fromCacheRow)
              .map((dto) => dto.toEntity())
              .toList(),
          fromCache: true,
          isStale: true,
        );
      }
      throw ApiEnvelopeParser.parseDioError(error);
    } on ApiException {
      rethrow;
    } catch (error) {
      if (cachedRows.isNotEmpty) {
        return GoalListResult(
          items: cachedRows
              .map(GoalDto.fromCacheRow)
              .map((dto) => dto.toEntity())
              .toList(),
          fromCache: true,
          isStale: true,
        );
      }
      throw ApiException(
        message: error.toString(),
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  @override
  Future<GoalEntity> createGoal(CreateGoalInput input) async {
    final userId = _requireUserId();
    final dao = await _dao();
    final localId = _uuid.v4();
    final now = DateTime.now().toUtc();

    final localDto = GoalDto.fromCreateInput(
      id: localId,
      input: input,
      createdAt: now,
    );

    await dao.upsertGoal(
      localDto.toCacheRow(
        userId: userId,
        syncedAt: now,
        isDirty: true,
      ),
    );

    final optimistic = localDto.toEntity(isDirty: true);
    unawaited(_syncCreateGoal(userId: userId, localId: localId, input: input));
    return optimistic;
  }

  @override
  Future<GoalEntity> updateGoal(String goalId, UpdateGoalInput input) async {
    if (input.isEmpty) {
      throw const ApiException(
        message: 'No fields provided to update',
        code: 'VALIDATION_ERROR',
        statusCode: 400,
      );
    }

    final userId = _requireUserId();
    final dao = await _dao();

    final existingRow = await dao.findGoalById(userId, goalId);
    if (existingRow == null) {
      throw const ApiException(
        message: 'Goal not found locally',
        code: 'NOT_FOUND',
        statusCode: 404,
      );
    }

    final now = DateTime.now().toUtc();
    final patched =
        GoalDto.fromCacheRow(existingRow).applyUpdate(input, updatedAt: now);

    await dao.upsertGoal(
      patched.toCacheRow(
        userId: userId,
        syncedAt: now,
        isDirty: true,
      ),
    );

    final optimistic = patched.toEntity(isDirty: true);
    unawaited(_syncUpdateGoal(userId: userId, goalId: goalId, input: input));
    return optimistic;
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    final userId = _requireUserId();
    final dao = await _dao();
    await dao.softDeleteGoalById(userId, goalId);
    unawaited(_syncDeleteGoal(userId: userId, goalId: goalId));
  }

  @override
  Future<GoalDepositResult> logDeposit(
    String goalId,
    LogDepositInput input,
  ) async {
    final userId = _requireUserId();
    final dao = await _dao();

    final goalRow = await dao.findGoalById(userId, goalId);
    if (goalRow == null) {
      throw const ApiException(
        message: 'Goal not found locally',
        code: 'NOT_FOUND',
        statusCode: 404,
      );
    }

    final localDepositId = _uuid.v4();
    final now = DateTime.now().toUtc();

    final updatedGoalDto = GoalDto.fromCacheRow(goalRow).applyDeposit(
      amount: input.amount,
      updatedAt: now,
    );

    await dao.upsertGoal(
      updatedGoalDto.toCacheRow(
        userId: userId,
        syncedAt: now,
        isDirty: true,
      ),
    );

    final localDepositDto = GoalDepositDto.fromLocalLog(
      id: localDepositId,
      goalId: goalId,
      input: input,
      createdAt: now,
    );

    await dao.upsertDeposit(
      localDepositDto.toCacheRow(
        userId: userId,
        syncedAt: now,
        isDirty: true,
      ),
    );

    final result = GoalDepositResult(
      goal: updatedGoalDto.toEntity(isDirty: true),
      deposit: localDepositDto.toEntity(isDirty: true),
    );

    unawaited(
      _syncLogDeposit(
        userId: userId,
        goalId: goalId,
        localDepositId: localDepositId,
        input: input,
      ),
    );

    return result;
  }

  Future<void> _syncCreateGoal({
    required String userId,
    required String localId,
    required CreateGoalInput input,
  }) async {
    final dao = await _dao();

    try {
      final response = await _dioClient.post<Map<String, dynamic>>(
        ApiEndpoints.goals,
        data: input.toJson(),
      );

      if (response.statusCode != 201) {
        throw _unexpectedStatus(response);
      }

      final data = ApiEnvelopeParser.parseSuccessData(response);
      final serverDto = GoalDto.fromJson(data);
      final syncedAt = DateTime.now().toUtc();

      await dao.deleteGoalById(userId, localId);
      await dao.upsertGoal(
        serverDto.toCacheRow(
          userId: userId,
          syncedAt: syncedAt,
          isDirty: false,
        ),
      );
    } catch (_) {}
  }

  Future<void> _syncUpdateGoal({
    required String userId,
    required String goalId,
    required UpdateGoalInput input,
  }) async {
    final dao = await _dao();

    try {
      final response = await _dioClient.patch<Map<String, dynamic>>(
        '${ApiEndpoints.goals}/$goalId',
        data: input.toJson(),
      );

      if (response.statusCode != 200) {
        throw _unexpectedStatus(response);
      }

      final data = ApiEnvelopeParser.parseSuccessData(response);
      final serverDto = GoalDto.fromJson(data);
      final syncedAt = DateTime.now().toUtc();

      await dao.upsertGoal(
        serverDto.toCacheRow(
          userId: userId,
          syncedAt: syncedAt,
          isDirty: false,
        ),
      );
    } catch (_) {}
  }

  Future<void> _syncDeleteGoal({
    required String userId,
    required String goalId,
  }) async {
    final dao = await _dao();

    try {
      final response = await _dioClient.delete<Map<String, dynamic>>(
        '${ApiEndpoints.goals}/$goalId',
      );

      if (response.statusCode != 200) {
        throw _unexpectedStatus(response);
      }

      await dao.deleteGoalById(userId, goalId);
    } catch (_) {}
  }

  Future<void> _syncLogDeposit({
    required String userId,
    required String goalId,
    required String localDepositId,
    required LogDepositInput input,
  }) async {
    final dao = await _dao();

    try {
      final response = await _dioClient.post<Map<String, dynamic>>(
        '${ApiEndpoints.goals}/$goalId/deposits',
        data: input.toJson(),
      );

      if (response.statusCode != 200) {
        throw _unexpectedStatus(response);
      }

      final data = ApiEnvelopeParser.parseSuccessData(response);
      final goalJson = data['goal'];
      final depositJson = data['deposit'];

      if (goalJson is! Map<String, dynamic> ||
          depositJson is! Map<String, dynamic>) {
        throw const ApiException(
          message: 'Invalid deposit response payload',
          code: 'INVALID_RESPONSE',
        );
      }

      final syncedAt = DateTime.now().toUtc();
      final serverGoal = GoalDto.fromJson(goalJson);
      final serverDeposit = GoalDepositDto.fromJson(depositJson);

      await dao.upsertGoal(
        serverGoal.toCacheRow(
          userId: userId,
          syncedAt: syncedAt,
          isDirty: false,
        ),
      );

      await dao.deleteDepositById(userId, localDepositId);
      await dao.upsertDeposit(
        serverDeposit.toCacheRow(
          userId: userId,
          syncedAt: syncedAt,
          isDirty: false,
        ),
      );
    } catch (_) {}
  }

  List<GoalEntity> _mergeServerAndDirty({
    required List<GoalEntity> serverItems,
    required List<GoalEntity> dirtyItems,
    required GoalStatusFilter status,
  }) {
    final dirtyIds = dirtyItems.map((goal) => goal.id).toSet();

    var merged = <GoalEntity>[
      ...dirtyItems,
      ...serverItems.where((goal) => !dirtyIds.contains(goal.id)),
    ];

    if (status != GoalStatusFilter.all) {
      merged =
          merged.where((goal) => goal.status == status.apiValue).toList();
    }

    merged.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return merged;
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

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepositoryImpl(
    dioClient: ref.watch(dioClientProvider),
    appDatabase: ref.watch(appDatabaseProvider.future),
    currentUserId: () => ref.watch(authStateProvider)?.user?.id,
  );
});