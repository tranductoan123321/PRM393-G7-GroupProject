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

  test('fetches collection banners', () async {
    final collections = await repository.fetchCollections();

    expect(collections, hasLength(1));
    expect(collections.single.title, 'Summer');
    expect(adapter.requests.single.path, '/collection');
  });

  test('fetches collection items when a banner is opened', () async {
    final items = await repository.fetchCollectionItems(collectionId: 'summer');

    expect(items, hasLength(1));
    expect(items.single.title, 'Linen shirt');
    expect(adapter.requests.single.path, '/collection/summer');
  });

  test('fetches discounted products for the offers carousel', () async {
    final offers = await repository.fetchOffers(categoryIds: '1,2');

    expect(offers, hasLength(1));
    expect(offers.single.oldPrice, '69.99');
    expect(adapter.requests.single.queryParameters['discount'], true);
    expect(adapter.requests.single.queryParameters['categories'], '1,2');
  });

  test('fetches a page of discover products with optional filters', () async {
    final products = await repository.fetchDiscoverProducts(
      page: 3,
      categoryIds: '1,2',
      brandId: 'brand-7',
    );

    expect(products, hasLength(1));
    expect(adapter.requests.single.queryParameters['page'], 3);
    expect(adapter.requests.single.queryParameters['categories'], '1,2');
    expect(adapter.requests.single.queryParameters['brands'], 'brand-7');
    expect(
      adapter.requests.single.queryParameters.containsKey('discount'),
      isFalse,
    );
  });

  test('fetches a page of discover offers', () async {
    final products = await repository.fetchDiscoverProducts(
      page: 2,
      categoryIds: 'women',
      offersOnly: true,
    );

    expect(products, hasLength(1));
    expect(adapter.requests.single.queryParameters['page'], 2);
    expect(adapter.requests.single.queryParameters['categories'], 'women');
    expect(adapter.requests.single.queryParameters['discount'], true);
  });

  test('fetches brands for search filters', () async {
    final brands = await repository.fetchBrands();

    expect(brands, hasLength(1));
    expect(brands.single.name, 'Studio');
    expect(adapter.requests.single.path, '/brand/list');
  });

  test('searches products by keyword and filters', () async {
    final products = await repository.searchProducts(
      query: 'linen shirt',
      page: 2,
      categoryIds: 'women,shirts',
      brandIds: 'studio',
      minPrice: 200,
      maxPrice: 800,
    );

    expect(products, hasLength(1));
    expect(adapter.requests.single.path, '/product/list');
    expect(adapter.requests.single.queryParameters, {
      'page': 2,
      'search': 'linen shirt',
      'categories': 'women,shirts',
      'brands': 'studio',
      'min-price': 200,
      'max-price': 800,
    });
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

    final Object responseData = switch (options.path) {
      '/category/list' => {
        'status': 'success',
        'data': [
          {
            'id': 'women',
            'name': 'Women',
            'imageURL': 'https://example.com/category.jpg',
            'gender': 2,
          },
        ],
      },
      '/brand/list' => {
        'status': 'success',
        'data': [
          {'id': 'studio', 'name': 'Studio'},
        ],
      },
      '/collection' => {
        'status': 'success',
        'data': [
          {
            'id': 'summer',
            'title': 'Summer',
            'description': 'Light looks for warm days.',
            'price': 120,
            'discount': 20,
            'image': 'https://example.com/banner.jpg',
          },
        ],
      },
      '/collection/summer' => {
        'status': 'success',
        'data': {
          'items': [
            {
              'title': 'Linen shirt',
              'description': 'Breathable summer fabric.',
              'image': 'https://example.com/linen.jpg',
            },
          ],
        },
      },
      _ => {
        'status': 'success',
        'data': {
          'products': [
            {
              'id': 'shirt',
              'title': 'Classic shirt',
              'imageUrl': 'https://example.com/product.jpg',
              'price': 49.99,
              'oldPrice': 69.99,
            },
          ],
        },
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
