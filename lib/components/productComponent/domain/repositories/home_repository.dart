import '../entities/home_data.dart';

abstract interface class HomeRepository {
  Future<HomeData> fetchHome({int gender, List<String> categoryIds});

  Future<List<HomeProduct>> searchProducts({
    required String query,
    required int page,
    List<String> categoryIds = const [],
    List<String> brandIds = const [],
    int? minPrice,
    int? maxPrice,
  });
}
