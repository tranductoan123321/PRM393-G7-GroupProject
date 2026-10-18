import 'package:dio/dio.dart';

import '../models/category.dart';
import '../models/product.dart';

class CategoryRepository {
  const CategoryRepository(this._dio);

  final Dio _dio;

  Future<List<ProductCategory>> fetchCategories({required int genderId}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/category/list',
      queryParameters: {'gender': genderId},
    );
    final data = response.data;

    if (data == null ||
        data['status'] != 'success' ||
        data['data'] is! List) {
      throw const FormatException('Could not load product categories.');
    }

    return (data['data'] as List)
        .map(
          (item) => ProductCategory.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<List<StoreProduct>> fetchProducts({String? categoryIds}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/product/list',
      queryParameters: {
        if (categoryIds != null && categoryIds.isNotEmpty)
          'categories': categoryIds,
      },
    );
    final data = response.data;

    if (data == null ||
        data['status'] != 'success' ||
        data['data'] is! Map ||
        (data['data'] as Map)['products'] is! List) {
      throw const FormatException('Could not load products.');
    }

    return ((data['data'] as Map)['products'] as List)
        .map(
          (item) => StoreProduct.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }
}
