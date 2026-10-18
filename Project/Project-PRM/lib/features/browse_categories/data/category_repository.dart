import 'package:dio/dio.dart';

import '../models/category.dart';
import '../models/collection.dart';
import '../models/collection_item.dart';
import '../models/product.dart';

class CategoryRepository {
  const CategoryRepository(this._dio);

  final Dio _dio;

  Future<List<StoreCollection>> fetchCollections() async {
    final response = await _dio.get<Map<String, dynamic>>('/collection');
    final data = response.data;

    if (data == null || data['status'] != 'success' || data['data'] is! List) {
      throw const FormatException('Could not load collection banners.');
    }

    return (data['data'] as List)
        .map(
          (item) => StoreCollection.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<List<CollectionItem>> fetchCollectionItems({
    required String collectionId,
  }) async {
    final response =
        await _dio.get<Map<String, dynamic>>('/collection/$collectionId');
    final data = response.data;

    if (data == null ||
        data['status'] != 'success' ||
        data['data'] is! Map ||
        (data['data'] as Map)['items'] is! List) {
      throw const FormatException('Could not load collection details.');
    }

    return ((data['data'] as Map)['items'] as List)
        .map(
          (item) => CollectionItem.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<List<StoreProduct>> fetchOffers({String? categoryIds}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/product/list',
      queryParameters: {
        'discount': true,
        if (categoryIds != null && categoryIds.isNotEmpty)
          'categories': categoryIds,
      },
    );
    return _parseProducts(response.data);
  }

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
    return _parseProducts(response.data);
  }

  List<StoreProduct> _parseProducts(Map<String, dynamic>? data) {
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
