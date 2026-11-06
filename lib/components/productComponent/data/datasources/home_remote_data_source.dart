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
      'categories': _categoriesQuery(categoryIds),
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
      'categories': _categoriesQuery(categoryIds),
    },
  );

  Future<List<Map<String, dynamic>>> searchProducts({
    required String query,
    required int page,
    List<String> categoryIds = const [],
    List<String> brandIds = const [],
    int? minPrice,
    int? maxPrice,
  }) => _apiClient.getProducts(
    queryParameters: {
      'search': query,
      'page': page,
      'categories': _idsQuery(categoryIds),
      'brands': _idsQuery(brandIds),
      'min-price': minPrice,
      'max-price': maxPrice,
    },
  );
}

String? _categoriesQuery(List<String> categoryIds) =>
    categoryIds.isEmpty ? null : categoryIds.join(',');

String? _idsQuery(List<String> ids) => ids.isEmpty ? null : ids.join(',');
