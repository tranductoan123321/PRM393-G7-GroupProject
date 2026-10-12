import '../../../../components/productComponent/domain/entities/home_data.dart';
import '../../../../shared/util/enums.dart';

enum SearchStatus { initial, loading, success, failure }

class SearchFilters {
  const SearchFilters({
    this.categoryIds = const [],
    this.brandIds = const [],
    this.minPrice,
    this.maxPrice,
  });

  final List<String> categoryIds;
  final List<String> brandIds;
  final int? minPrice;
  final int? maxPrice;
}

class SearchState {
  const SearchState({
    this.status = SearchStatus.initial,
    this.products = const [],
    this.query = '',
    this.error,
    this.filters = const SearchFilters(),
    this.page = 1,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.searchState = BlocState.initial,
    this.searchProducts = const [],
    this.searchFailMessage,
    this.hasSearchProductsListReachedMax = false,
    this.loadMoreProductsState = BlocState.initial,
  });

  final SearchStatus status;
  final List<HomeProduct> products;
  final String query;
  final String? error;
  final SearchFilters filters;
  final int page;
  final bool hasReachedMax;
  final bool isLoadingMore;

  final BlocState searchState;
  final List<HomeProduct> searchProducts;
  final String? searchFailMessage;
  final bool hasSearchProductsListReachedMax;
  final BlocState loadMoreProductsState;

  SearchState copyWith({
    SearchStatus? status,
    List<HomeProduct>? products,
    String? query,
    String? error,
    bool clearError = false,
    SearchFilters? filters,
    int? page,
    bool? hasReachedMax,
    bool? isLoadingMore,
    BlocState? searchState,
    List<HomeProduct>? searchProducts,
    String? searchFailMessage,
    bool? hasSearchProductsListReachedMax,
    BlocState? loadMoreProductsState,
  }) => SearchState(
    status: status ?? this.status,
    products: products ?? this.products,
    query: query ?? this.query,
    error: clearError ? null : error ?? this.error,
    filters: filters ?? this.filters,
    page: page ?? this.page,
    hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    searchState: searchState ?? this.searchState,
    searchProducts: searchProducts ?? this.searchProducts,
    searchFailMessage: searchFailMessage ?? this.searchFailMessage,
    hasSearchProductsListReachedMax:
        hasSearchProductsListReachedMax ?? this.hasSearchProductsListReachedMax,
    loadMoreProductsState:
        loadMoreProductsState ?? this.loadMoreProductsState,
  );
}
