import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../components/productComponent/domain/repositories/home_repository.dart';
import '../../../../shared/api/home_api_exception.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  SearchCubit(this._repository) : super(const SearchState());

  static const _pageSize = 20;
  final HomeRepository _repository;
  int _requestId = 0;

  Future<void> search(String query, {SearchFilters? filters}) async {
    final normalizedQuery = query.trim();
    final selectedFilters = filters ?? state.filters;
    final requestId = ++_requestId;

    if (normalizedQuery.isEmpty) {
      emit(
        state.copyWith(
          status: SearchStatus.initial,
          query: '',
          products: const [],
          filters: selectedFilters,
          page: 1,
          hasReachedMax: false,
          isLoadingMore: false,
          clearError: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: SearchStatus.loading,
        query: normalizedQuery,
        products: const [],
        filters: selectedFilters,
        page: 1,
        hasReachedMax: false,
        isLoadingMore: false,
        clearError: true,
      ),
    );

    try {
      final products = await _repository.searchProducts(
        query: normalizedQuery,
        page: 1,
        categoryIds: selectedFilters.categoryIds,
        brandIds: selectedFilters.brandIds,
        minPrice: selectedFilters.minPrice,
        maxPrice: selectedFilters.maxPrice,
      );
      if (isClosed || requestId != _requestId) return;
      emit(
        state.copyWith(
          status: SearchStatus.success,
          products: products,
          page: 2,
          hasReachedMax: products.length < _pageSize,
        ),
      );
    } on HomeApiException catch (error) {
      if (isClosed || requestId != _requestId) return;
      emit(state.copyWith(status: SearchStatus.failure, error: error.message));
    }
  }

  Future<void> loadMore() async {
    if (state.status != SearchStatus.success ||
        state.isLoadingMore ||
        state.hasReachedMax ||
        state.query.isEmpty) {
      return;
    }

    final requestId = _requestId;
    emit(state.copyWith(isLoadingMore: true, clearError: true));
    try {
      final products = await _repository.searchProducts(
        query: state.query,
        page: state.page,
        categoryIds: state.filters.categoryIds,
        brandIds: state.filters.brandIds,
        minPrice: state.filters.minPrice,
        maxPrice: state.filters.maxPrice,
      );
      if (isClosed || requestId != _requestId) return;
      emit(
        state.copyWith(
          products: [...state.products, ...products],
          page: state.page + 1,
          hasReachedMax: products.length < _pageSize,
          isLoadingMore: false,
        ),
      );
    } on HomeApiException catch (error) {
      if (isClosed || requestId != _requestId) return;
      emit(state.copyWith(isLoadingMore: false, error: error.message));
    }
  }
}
