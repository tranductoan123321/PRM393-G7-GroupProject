import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_prm/features/browse_categories/data/category_repository.dart';

void main() {
  late _FakeAdapter adapter;
  late CategoryRepository repository;

  setUp(() {
    adapter = _FakeAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'))
      ..httpClientAdapter = adapter;
    repository = CategoryRepository(dio);
  });

  test('fetches categories for the selected gender', () async {
    final categories = await repository.fetchCategories(genderId: 2);

    expect(categories, hasLength(1));
    expect(categories.single.name, 'Women');
    expect(adapter.requests.single.path, '/category/list');
    expect(adapter.requests.single.queryParameters['gender'], 2);
  });

  test('applies selected category IDs to the product request', () async {
    final products = await repository.fetchProducts(categoryIds: '1,2');

    expect(products, hasLength(1));
    expect(products.single.title, 'Classic shirt');
    expect(adapter.requests.single.path, '/product/list');
    expect(adapter.requests.single.queryParameters['categories'], '1,2');
  });
}

class _FakeAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    final Object responseData = options.path == '/category/list'
        ? {
            'status': 'success',
            'data': [
              {
                'id': 'women',
                'name': 'Women',
                'imageURL': 'https://example.com/category.jpg',
                'gender': 2,
              },
            ],
          }
        : {
            'status': 'success',
            'data': {
              'products': [
                {
                  'id': 'shirt',
                  'title': 'Classic shirt',
                  'imageUrl': 'https://example.com/product.jpg',
                  'price': 49.99,
                },
              ],
            },
          };

    return ResponseBody.fromString(
      jsonEncode(responseData),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
