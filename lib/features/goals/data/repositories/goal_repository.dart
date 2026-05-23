import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kise/core/cache/cache_policy.dart';
import 'package:kise/core/database/app_database.dart';
import 'package:kise/core/database/daos/goal_cache_dao.dart';
import 'package:kise/core/network/api_endpoints.dart';
import 'package:kise/core/network/dio_client.dart';
import 'package:kise/features/auth/presentation/state/auth_notifier.dart';
import 'package:kise/features/goals/data/dtos/goal_dto.dart';
import 'package:kise/features/goals/domain/goal_entity.dart';
import 'package:kise/features/goals/domain/goal_filters.dart';
import 'package:kise/features/goals/domain/goal_inputs.dart';

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
  })  : _dioClient = dioClient,
        _appDatabaseFuture = appDatabase,
        _currentUserId = currentUserId,
        _cachePolicy = cachePolicy ?? const CachePolicy();

  final DioClient _dioClient;
  final Future<AppDatabase> _appDatabaseFuture;
  final String? Function() _currentUserId;
  final CachePolicy _cachePolicy;

  static const Duration _dbTimeout = Duration(seconds: 8);

  Future<GoalCacheDao?> _tryDao() async {
    try {
      final db = await _appDatabaseFuture.timeout(_dbTimeout);
      await GoalCacheDao.ensureSchema(db.database);
      return GoalCacheDao(db.database);
    } catch (_) {
      return null;
    }
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
    final dao = await _tryDao();

    var cachedRows = <Map<String, dynamic>>[];
    DateTime? lastSyncAt;
    var hasDirtyGoals = false;

    if (dao != null) {
      cachedRows = await dao.queryGoals(
        userId: userId,
        status: status.apiValue,
      );
      lastSyncAt = await dao.getLastSyncAt();
      final dirtyRows = await dao.getDirtyGoals(userId);
      hasDirtyGoals = dirtyRows.isNotEmpty;

      final cacheIsFresh = !forceRefresh &&
          !hasDirtyGoals &&
          _cachePolicy.isFresh(lastSyncAt) &&
          cachedRows.isNotEmpty;

      if (cacheIsFresh) {
        final cachedEntities = cachedRows
            .map(GoalDto.fromCacheRow)
            .map((dto) => dto.toEntity())
            .toList();

        return GoalListResult(
          items: _mergeServerAndDirty(
            serverItems: cachedEntities,
            dirtyItems: const [],
            status: status,
          ),
          fromCache: true,
          isStale: false,
        );
      }
    }

    try {
      final response = await _dioClient.get<Map<String, dynamic>>(
        ApiEndpoints.goals,
        queryParameters: status.toQueryParameters(),
      );

      if (response.statusCode != 200) {
        throw _unexpectedStatus(response);
      }

      final envelopeData = ApiEnvelopeParser.parseSuccessPayload(response);
      final serverGoals = GoalDto.listFromEnvelope(envelopeData);
      final syncedAt = DateTime.now().toUtc();
      final serverEntities =
          serverGoals.map((dto) => dto.toEntity()).toList();

      if (dao != null) {
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

        final pendingDirtyRows = await dao.getDirtyGoals(userId);
        final dirtyEntities = pendingDirtyRows
            .map(GoalDto.fromCacheRow)
            .map((dto) => dto.toEntity(isDirty: true))
            .toList();

        return GoalListResult(
          items: _mergeServerAndDirty(
            serverItems: serverEntities,
            dirtyItems: dirtyEntities,
            status: status,
          ),
          fromCache: false,
          isStale: false,
        );
      }

      return GoalListResult(
        items: _mergeServerAndDirty(
          serverItems: serverEntities,
          dirtyItems: const [],
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
    return _syncCreateGoal(
      userId: userId,
      localId: null,
      input: input,
    );
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
    final dao = await _tryDao();

    await _syncUpdateGoal(userId: userId, goalId: goalId, input: input);

    if (dao != null) {
      final syncedRow = await dao.findGoalById(userId, goalId);
      if (syncedRow != null) {
        return GoalDto.fromCacheRow(syncedRow).toEntity();
      }
    }

    return _fetchGoalFromServer(userId, goalId);
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    final userId = _requireUserId();
    await _syncDeleteGoal(userId: userId, goalId: goalId);
  }

  @override
  Future<GoalDepositResult> logDeposit(
    String goalId,
    LogDepositInput input,
  ) async {
    final userId = _requireUserId();
    final goal = await _requireGoalForMutation(userId, goalId);

    if (goal.isLocked) {
      throw const ApiException(
        message: 'Deposits cannot be added to a locked goal',
        code: 'BUSINESS_RULE',
        statusCode: 422,
      );
    }

    return _syncLogDeposit(
      userId: userId,
      goalId: goalId,
      localDepositId: null,
      input: input,
    );
  }

  Future<GoalEntity> _requireGoalForMutation(
    String userId,
    String goalId,
  ) async {
    final dao = await _tryDao();
    if (dao != null) {
      final row = await dao.findGoalById(userId, goalId);
      if (row != null) {
        return GoalDto.fromCacheRow(row).toEntity();
      }
    }

    return _fetchGoalFromServer(userId, goalId);
  }

  Future<GoalEntity> _syncCreateGoal({
    required String userId,
    required String? localId,
    required CreateGoalInput input,
  }) async {
    final dao = await _tryDao();

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

    if (dao != null) {
      if (localId != null) {
        await dao.deleteGoalById(userId, localId);
      }
      await dao.upsertGoal(
        serverDto.toCacheRow(
          userId: userId,
          syncedAt: syncedAt,
          isDirty: false,
        ),
      );
      await dao.setLastSyncAt(syncedAt);
    }

    return serverDto.toEntity();
  }

  Future<GoalEntity> _fetchGoalFromServer(String userId, String goalId) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      '${ApiEndpoints.goals}/$goalId',
    );

    if (response.statusCode != 200) {
      throw _unexpectedStatus(response);
    }

    final data = ApiEnvelopeParser.parseSuccessData(response);
    return GoalDto.fromJson(data).toEntity();
  }

  Future<void> _syncUpdateGoal({
    required String userId,
    required String goalId,
    required UpdateGoalInput input,
  }) async {
    final dao = await _tryDao();

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

    if (dao != null) {
      await dao.upsertGoal(
        serverDto.toCacheRow(
          userId: userId,
          syncedAt: syncedAt,
          isDirty: false,
        ),
      );
      await dao.setLastSyncAt(syncedAt);
    }
  }

  Future<void> _syncDeleteGoal({
    required String userId,
    required String goalId,
  }) async {
    final dao = await _tryDao();

    final response = await _dioClient.delete<Map<String, dynamic>>(
      '${ApiEndpoints.goals}/$goalId',
    );

    if (response.statusCode != 200) {
      throw _unexpectedStatus(response);
    }

    if (dao != null) {
      await dao.deleteGoalById(userId, goalId);
      await dao.setLastSyncAt(DateTime.now().toUtc());
    }
  }

  Future<GoalDepositResult> _syncLogDeposit({
    required String userId,
    required String goalId,
    required String? localDepositId,
    required LogDepositInput input,
  }) async {
    final dao = await _tryDao();

    final response = await _dioClient.post<Map<String, dynamic>>(
      '${ApiEndpoints.goals}/$goalId/deposits',
      data: input.toJson(),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
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

    if (dao != null) {
      await dao.upsertGoal(
        serverGoal.toCacheRow(
          userId: userId,
          syncedAt: syncedAt,
          isDirty: false,
        ),
      );

      if (localDepositId != null) {
        await dao.deleteDepositById(userId, localDepositId);
      }
      await dao.upsertDeposit(
        serverDeposit.toCacheRow(
          userId: userId,
          syncedAt: syncedAt,
          isDirty: false,
        ),
      );
      await dao.setLastSyncAt(syncedAt);
    }

    return GoalDepositResult(
      goal: serverGoal.toEntity(),
      deposit: serverDeposit.toEntity(),
    );
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
      merged = merged.where(status.matches).toList();
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
    appDatabase: ref.read(appDatabaseProvider.future),
    currentUserId: () => ref.watch(authStateProvider)?.user?.id,
  );
});