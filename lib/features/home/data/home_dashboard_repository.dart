import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kise/core/network/api_endpoints.dart';
import 'package:kise/core/network/dio_client.dart';
import 'package:kise/features/home/data/home_dashboard_dto.dart';
import 'package:kise/features/home/domain/home_dashboard_models.dart';

abstract class HomeDashboardRepository {
  Future<HomeDashboardBundle> fetchHome({String range = '6m'});
}

class HomeDashboardRepositoryImpl implements HomeDashboardRepository {
  HomeDashboardRepositoryImpl({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  @override
  Future<HomeDashboardBundle> fetchHome({String range = '6m'}) async {
    try {
      final response = await _dioClient.get<Map<String, dynamic>>(
        ApiEndpoints.dashboardHome,
        queryParameters: {'range': range},
      );

      if (response.statusCode != 200) {
        throw _unexpectedStatus(response);
      }

      final data = ApiEnvelopeParser.parseSuccessData(response);
      return HomeDashboardDto.fromJson(data);
    } on DioException catch (error) {
      throw ApiEnvelopeParser.parseDioError(error);
    }
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

final homeDashboardRepositoryProvider = Provider<HomeDashboardRepository>(
  (ref) => HomeDashboardRepositoryImpl(
    dioClient: ref.watch(dioClientProvider),
  ),
);
