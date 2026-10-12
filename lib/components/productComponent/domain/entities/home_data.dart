import '../../../collectionComponent/domain/entities/collection.dart';
import 'brand.dart';
import 'category.dart';
import 'product.dart';

class HomeData {
  const HomeData({
    required this.collections,
    required this.categories,
    required this.offers,
    required this.brands,
  });

  final List<HomeCollection> collections;
  final List<HomeCategory> categories;
  final List<HomeProduct> offers;
  final List<HomeBrand> brands;
}
