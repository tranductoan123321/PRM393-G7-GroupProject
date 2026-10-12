import '../../../../shared/api/home_api_client.dart';
import '../../../collectionComponent/domain/repositories/home_collection_repository.dart';
import '../../../collectionComponent/data/repositories/home_collection_repository_impl.dart';
import '../../../collectionComponent/domain/entities/collection.dart';
import '../../domain/entities/home_data.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';
import '../models/brand_model.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({
    HomeApiClient? apiClient,
    HomeCollectionRepository? collectionRepository,
  }) : _dataSource = HomeRemoteDataSource(apiClient ?? HomeApiClient()),
       _collectionRepository =
           collectionRepository ??
           HomeCollectionRepositoryImpl(apiClient: apiClient);

  final HomeRemoteDataSource _dataSource;
  final HomeCollectionRepository _collectionRepository;

  @override
  Future<HomeData> fetchHome({
    int gender = 0,
    List<String> categoryIds = const [],
  }) async {
    final responses = await Future.wait<Object>([
      _collectionRepository.getCollections(),
      _dataSource.getCategories(gender: gender),
      _dataSource.getOffers(categoryIds: categoryIds),
      _dataSource.getBrands(),
    ]);

    final brandModels = (responses[3] as List<Map<String, dynamic>>)
        .map(HomeBrandModel.fromJson)
        .toList(growable: false);
    final brandProducts = await Future.wait(
      brandModels.map(
        (brand) async => _productsFromJson(
          await _dataSource.getBrandProducts(
            brandId: brand.id,
            categoryIds: categoryIds,
          ),
        ),
      ),
    );
    final categories = (responses[1] as List<Map<String, dynamic>>)
        .map((json) => HomeCategoryModel.fromJson(json).entity)
        .toList(growable: false);
    final offers = _productsFromJson(
      responses[2] as List<Map<String, dynamic>>,
    );

    return HomeData(
      collections: responses[0] as List<HomeCollection>,
      categories: categories,
      offers: offers,
      brands: [
        for (var index = 0; index < brandModels.length; index++)
          brandModels[index].toEntity(brandProducts[index]),
      ],
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
    jsonList
        .map((json) => HomeProductModel.fromJson(json).entity)
        .toList(growable: false);
