import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kise/core/network/api_endpoints.dart';
import 'package:kise/core/network/dio_client.dart';
import 'package:kise/features/settings/data/dtos/settings_dto.dart';
import 'package:kise/features/settings/domain/settings_models.dart';

abstract class SettingsRepository {
  Future<SettingsBundle> fetchSettings();

  Future<AllowanceSettings> updateAllowance({
    required double monthlyAmount,
    required int cycleStartDay,
  });

  Future<UserPreferencesSettings> updatePreferences({
    String? preferredLanguage,
    String? themeMode,
  });

  Future<PaymentAccountSettings> createAccount({
    required String name,
    required String type,
  });

  Future<void> deleteAccount(String accountId);

  Future<void> deleteUserAccount();
}

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({required DioClient dioClient}) : _dioClient = dioClient;

  final DioClient _dioClient;

  ApiException _toApiException(Object error, String fallbackMessage) {
    if (error is ApiException) {
      return error;
    }
    if (error is DioException) {
      return ApiEnvelopeParser.parseDioError(error);
    }
    return ApiException(
      message: '$fallbackMessage: $error',
      code: 'SETTINGS_ERROR',
    );
  }

  @override
  Future<SettingsBundle> fetchSettings() async {
    try {
      final results = await Future.wait([
        _dioClient.get<Map<String, dynamic>>(ApiEndpoints.settingsAccounts),
        _dioClient.get<Map<String, dynamic>>(ApiEndpoints.settingsAllowance),
        _dioClient.get<Map<String, dynamic>>(ApiEndpoints.settingsPreferences),
      ]);

      for (final response in results) {
        if (response.statusCode != 200) {
          throw _unexpectedStatus(response);
        }
      }

      final accountsList = ApiEnvelopeParser.parseSuccessList(results[0]);
      final allowanceData = ApiEnvelopeParser.parseSuccessData(results[1]);
      final preferencesData = ApiEnvelopeParser.parseSuccessData(results[2]);

      return SettingsBundle(
        accounts: SettingsDto.accountListFromJson(accountsList),
        allowance: SettingsDto.allowanceFromJson(allowanceData),
        preferences: SettingsDto.preferencesFromJson(preferencesData),
      );
    } catch (error) {
      throw _toApiException(error, 'Could not load settings');
    }
  }

  @override
  Future<AllowanceSettings> updateAllowance({
    required double monthlyAmount,
    required int cycleStartDay,
  }) async {
    try {
      final response = await _dioClient.put<Map<String, dynamic>>(
        ApiEndpoints.settingsAllowance,
        data: {
          'monthlyAmount': monthlyAmount,
          'cycleStartDay': cycleStartDay,
        },
      );

      if (response.statusCode != 200) {
        throw _unexpectedStatus(response);
      }

      final data = ApiEnvelopeParser.parseSuccessData(response);
      return SettingsDto.allowanceFromJson(data);
    } catch (error) {
      throw _toApiException(error, 'Could not save allowance settings');
    }
  }

  @override
  Future<UserPreferencesSettings> updatePreferences({
    String? preferredLanguage,
    String? themeMode,
  }) async {
    try {
      final response = await _dioClient.patch<Map<String, dynamic>>(
        ApiEndpoints.settingsPreferences,
        data: {
          if (preferredLanguage != null) 'preferredLanguage': preferredLanguage,
          if (themeMode != null) 'themeMode': themeMode,
        },
      );

      if (response.statusCode != 200) {
        throw _unexpectedStatus(response);
      }

      final data = ApiEnvelopeParser.parseSuccessData(response);
      return SettingsDto.preferencesFromJson(data);
    } catch (error) {
      throw _toApiException(error, 'Could not update preferences');
    }
  }

  @override
  Future<PaymentAccountSettings> createAccount({
    required String name,
    required String type,
  }) async {
    try {
      final response = await _dioClient.post<Map<String, dynamic>>(
        ApiEndpoints.settingsAccounts,
        data: {
          'name': name,
          'type': type,
        },
      );

      if (response.statusCode != 201) {
        throw _unexpectedStatus(response);
      }

      final data = ApiEnvelopeParser.parseSuccessData(response);
      return SettingsDto.accountFromJson(data);
    } catch (error) {
      throw _toApiException(error, 'Could not add account');
    }
  }

  @override
  Future<void> deleteAccount(String accountId) async {
    try {
      final response = await _dioClient.delete<Map<String, dynamic>>(
        '${ApiEndpoints.settingsAccounts}/$accountId',
      );

      if (response.statusCode != 200) {
        throw _unexpectedStatus(response);
      }
    } catch (error) {
      throw _toApiException(error, 'Could not remove account');
    }
  }

  @override
  Future<void> deleteUserAccount() async {
    try {
      final response = await _dioClient.delete<Map<String, dynamic>>(
        ApiEndpoints.usersMe,
      );

      if (response.statusCode != 200) {
        throw _unexpectedStatus(response);
      }
    } catch (error) {
      throw _toApiException(error, 'Could not delete account');
    }
  }

  ApiException _unexpectedStatus(Response<dynamic> response) {
    final body = ApiEnvelopeParser.responseBodyMap(response.data);
    if (body != null) {
      return ApiEnvelopeParser.parseErrorFromMap(
        body,
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

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(
    dioClient: ref.watch(dioClientProvider),
  );
});
