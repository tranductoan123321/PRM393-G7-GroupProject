import 'package:efashion_flutter/components/collectionComponent/domain/entities/collection.dart';
import 'package:efashion_flutter/components/productComponent/domain/entities/brand.dart';
import 'package:efashion_flutter/components/productComponent/domain/entities/category.dart';
import 'package:efashion_flutter/components/productComponent/domain/entities/product.dart';

typedef HomeProduct = Product;
typedef HomeCategory = Category;
typedef HomeBrand = Brand;

class HomeData {
  const HomeData({
    this.collections = const [],
    this.categories = const [],
    this.offers = const [],
    this.brands = const [],
  });

  final List<Collection> collections;
  final List<Category> categories;
  final List<Product> offers;
  final List<Brand> brands;
}
