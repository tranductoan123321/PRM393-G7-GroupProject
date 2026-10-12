import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import 'home_api_exception.dart';

class HomeApiClient {
  HomeApiClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 20),
              headers: {
                if (ApiConstants.accessToken.isNotEmpty)
                  'Authorization': 'Bearer ${ApiConstants.accessToken}',
              },
            ),
          );

  final Dio _dio;

  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, Object?> queryParameters = const {},
  }) async {
    final data = await _getData(path, queryParameters: queryParameters);
    if (data is! List) {
      throw HomeApiException('Invalid list response from $path.');
    }
    return data.map(_asJsonMap).toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> getProducts({
    required Map<String, Object?> queryParameters,
  }) async {
    final data = await _getData(
      '/product/list',
      queryParameters: queryParameters,
    );
    if (data is! Map<String, dynamic> || data['products'] is! List) {
      throw const HomeApiException('Invalid products response from backend.');
    }
    return (data['products'] as List).map(_asJsonMap).toList(growable: false);
  }

  Future<dynamic> _getData(
    String path, {
    required Map<String, Object?> queryParameters,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '${ApiConstants.baseUrl}$path',
        queryParameters: queryParameters,
      );
      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw HomeApiException('Invalid response from backend ($path).');
      }
      if (body['status'] != 'success') {
        final message = body['message'];
        throw HomeApiException(
          message is String && message.isNotEmpty
              ? message
              : 'Backend rejected request ($path).',
        );
      }
      return body['data'];
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        throw const HomeApiException(
          'Backend authorization failed. Check API_ACCESS_TOKEN or backend access rules.',
        );
      }
      throw HomeApiException(
        'Could not load Home data ($path): '
        '${error.message ?? 'network request failed'}'
        '${statusCode == null ? '' : ' (HTTP $statusCode)'}.',
      );
    }
  }
}

Map<String, dynamic> _asJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  throw const HomeApiException('Backend returned an invalid item.');
}
