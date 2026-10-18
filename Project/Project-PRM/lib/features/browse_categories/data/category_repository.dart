import 'package:dio/dio.dart';

import '../models/brand.dart';
import '../models/category.dart';
import '../models/collection.dart';
import '../models/collection_item.dart';
import '../models/product.dart';

class CategoryRepository {
  const CategoryRepository(this._dio);

  final Dio _dio;

  Future<List<ProductBrand>> fetchBrands() async {
    final response = await _dio.get<Map<String, dynamic>>('/brand/list');
    final data = response.data;

    if (data == null || data['status'] != 'success' || data['data'] is! List) {
      throw const FormatException('Could not load product brands.');
    }

    return (data['data'] as List)
        .map(
          (item) =>
              ProductBrand.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<List<StoreCollection>> fetchCollections() async {
    final response = await _dio.get<Map<String, dynamic>>('/collection');
    final data = response.data;

    if (data == null || data['status'] != 'success' || data['data'] is! List) {
      throw const FormatException('Could not load collection banners.');
    }

    return (data['data'] as List)
        .map(
          (item) =>
              StoreCollection.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<List<CollectionItem>> fetchCollectionItems({
    required String collectionId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/collection/$collectionId',
    );
    final data = response.data;

    if (data == null ||
        data['status'] != 'success' ||
        data['data'] is! Map ||
        (data['data'] as Map)['items'] is! List) {
      throw const FormatException('Could not load collection details.');
    }

    return ((data['data'] as Map)['items'] as List)
        .map(
          (item) =>
              CollectionItem.fromJson(Map<String, dynamic>.from(item as Map)),
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

    if (data == null || data['status'] != 'success' || data['data'] is! List) {
      throw const FormatException('Could not load product categories.');
    }

    return (data['data'] as List)
        .map(
          (item) =>
              ProductCategory.fromJson(Map<String, dynamic>.from(item as Map)),
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

  Future<List<StoreProduct>> fetchDiscoverProducts({
    required int page,
    String? categoryIds,
    String? brandId,
    bool offersOnly = false,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/product/list',
      queryParameters: {
        'page': page,
        if (offersOnly) 'discount': true,
        if (brandId != null && brandId.isNotEmpty) 'brands': brandId,
        if (categoryIds != null && categoryIds.isNotEmpty)
          'categories': categoryIds,
      },
    );
    return _parseProducts(response.data);
  }

  Future<List<StoreProduct>> searchProducts({
    required String query,
    required int page,
    String? categoryIds,
    String? brandIds,
    int? minPrice,
    int? maxPrice,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/product/list',
      queryParameters: {
        'page': page,
        'search': query,
        ..._optionalParameters({
          'categories': categoryIds,
          'brands': brandIds,
          'min-price': minPrice,
          'max-price': maxPrice,
        }),
      },
    );
    return _parseProducts(response.data);
  }

  Map<String, Object> _optionalParameters(Map<String, Object?> parameters) {
    return {
      for (final entry in parameters.entries)
        if (entry.value != null &&
            (entry.value is! String || (entry.value as String).isNotEmpty))
          entry.key: entry.value!,
    };
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
          (item) =>
              StoreProduct.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }
}
