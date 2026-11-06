import 'package:flutter_test/flutter_test.dart';
import 'package:efashion_flutter/components/productComponent/domain/entities/home_data.dart';
import 'package:efashion_flutter/components/productComponent/domain/repositories/home_repository.dart';
import 'package:efashion_flutter/presentation/product/bloc/search_bloc/search_cubit.dart';
import 'package:efashion_flutter/presentation/product/bloc/search_bloc/search_state.dart';

void main() {
  test('search forwards query and filters to the repository', () async {
    final repository = _FakeHomeRepository();
    final cubit = SearchCubit(repository);
    addTearDown(cubit.close);

    await cubit.search(
      '  jacket ',
      filters: const SearchFilters(
        categoryIds: ['category-1'],
        brandIds: ['brand-1'],
        minPrice: 20,
        maxPrice: 100,
      ),
    );

    expect(cubit.state.query, 'jacket');
    expect(cubit.state.status, SearchStatus.success);
    expect(repository.lastQuery, 'jacket');
    expect(repository.lastCategoryIds, ['category-1']);
    expect(repository.lastBrandIds, ['brand-1']);
    expect(repository.lastMinPrice, 20);
    expect(repository.lastMaxPrice, 100);
  });

  test('loadMore appends results and requests the next page', () async {
    final repository = _FakeHomeRepository();
    final cubit = SearchCubit(repository);
    addTearDown(cubit.close);

    await cubit.search('shirt');
    expect(cubit.state.products, hasLength(20));

    await cubit.loadMore();

    expect(repository.lastPage, 2);
    expect(cubit.state.products, hasLength(21));
    expect(cubit.state.hasReachedMax, isTrue);
    expect(cubit.state.isLoadingMore, isFalse);
  });
}

class _FakeHomeRepository implements HomeRepository {
  String? lastQuery;
  int? lastPage;
  List<String> lastCategoryIds = const [];
  List<String> lastBrandIds = const [];
  int? lastMinPrice;
  int? lastMaxPrice;

  @override
  Future<HomeData> fetchHome({
    int gender = 0,
    List<String> categoryIds = const [],
  }) => throw UnimplementedError();

  @override
  Future<List<HomeProduct>> searchProducts({
    required String query,
    required int page,
    List<String> categoryIds = const [],
    List<String> brandIds = const [],
    int? minPrice,
    int? maxPrice,
  }) async {
    lastQuery = query;
    lastPage = page;
    lastCategoryIds = categoryIds;
    lastBrandIds = brandIds;
    lastMinPrice = minPrice;
    lastMaxPrice = maxPrice;
    if (page == 1) {
      return List.generate(
        20,
        (index) => HomeProduct(
          id: 'product-$index',
          title: 'Product $index',
          price: 30,
          oldPrice: 40,
          imageUrl: '',
        ),
      );
    }
    return const [
      HomeProduct(
        id: 'product-20',
        title: 'Product 20',
        price: 30,
        oldPrice: 40,
        imageUrl: '',
      ),
    ];
  }
}
