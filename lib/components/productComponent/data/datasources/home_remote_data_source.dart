import '../../../../shared/api/home_api_client.dart';

class HomeRemoteDataSource {
  const HomeRemoteDataSource(this._apiClient);

  final HomeApiClient _apiClient;

  Future<List<Map<String, dynamic>>> getCategories({required int gender}) =>
      _apiClient.getList('/category/list', queryParameters: {'gender': gender});

  Future<List<Map<String, dynamic>>> getOffers({
    required List<String> categoryIds,
  }) => _apiClient.getProducts(
    queryParameters: {
      'discount': true,
      'page': 1,
      'categories': ?_categoriesQuery(categoryIds),
    },
  );

  Future<List<Map<String, dynamic>>> getBrands() =>
      _apiClient.getList('/brand/list');

  Future<List<Map<String, dynamic>>> getBrandProducts({
    required String brandId,
    required List<String> categoryIds,
  }) => _apiClient.getProducts(
    queryParameters: {
      'brands': brandId,
      'categories': ?_categoriesQuery(categoryIds),
    },
  );
}

String? _categoriesQuery(List<String> categoryIds) =>
    categoryIds.isEmpty ? null : categoryIds.join(',');
