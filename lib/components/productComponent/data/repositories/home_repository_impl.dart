import '../../../../shared/api/home_api_client.dart';
import '../../domain/entities/home_data.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';
import '../models/brand_model.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({HomeApiClient? apiClient})
      : _dataSource = HomeRemoteDataSource(apiClient ?? HomeApiClient());

  final HomeRemoteDataSource _dataSource;

  @override
  Future<HomeData> fetchHome({
    int gender = 0,
    List<String> categoryIds = const [],
  }) async {
    final categories = (await _dataSource.getCategories(gender: gender))
        .map((json) => CategoryModel.fromJson(json))
        .toList(growable: false);

    final offers = (await _dataSource.getOffers(categoryIds: categoryIds))
        .map((json) => ProductModel.fromJson(json))
        .toList(growable: false);

    final brands = (await _dataSource.getBrands())
        .map((json) => BrandModel.fromJson(json))
        .toList(growable: false);

    return HomeData(
      collections: const [],
      categories: categories,
      offers: offers,
      brands: brands,
    );
  }

  @override
  Future<List<HomeProduct>> searchProducts({
    required String query,
    required int page,
    List<String> categoryIds = const [],
    List<String> brandIds = const [],
    int? minPrice,
    int? maxPrice,
  }) async => _productsFromJson(
    await _dataSource.searchProducts(
      query: query,
      page: page,
      categoryIds: categoryIds,
      brandIds: brandIds,
      minPrice: minPrice,
      maxPrice: maxPrice,
    ),
  );
}

List<HomeProduct> _productsFromJson(List<Map<String, dynamic>> jsonList) =>
    jsonList.map((json) => ProductModel.fromJson(json)).toList(growable: false);
