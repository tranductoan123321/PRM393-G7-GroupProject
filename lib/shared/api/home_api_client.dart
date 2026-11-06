import 'package:dio/dio.dart';

class HomeApiClient {
  HomeApiClient({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(baseUrl: 'https://example.com'));

  final Dio _dio;

  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get(path, queryParameters: queryParameters);
    final data = response.data;

    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList(growable: false);
    }

    if (data is Map<String, dynamic>) {
      final dynamic payload = data['data'];
      if (payload is List) {
        return payload
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
      }
    }

    return const <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> getProducts({
    Map<String, dynamic>? queryParameters,
  }) async => getList('/products', queryParameters: queryParameters);
}
