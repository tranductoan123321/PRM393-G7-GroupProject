import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/api/home_api_exception.dart';
import '../../../../components/productComponent/domain/usecases/home/get_home_data_usecase.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._getHomeData) : super(const HomeState());

  final GetHomeDataUseCase _getHomeData;
  int _requestId = 0;

  Future<void> loadHome({int? gender, List<String>? categoryIds}) async {
    final requestId = ++_requestId;
    final requestedGender = gender ?? state.gender;
    final requestedCategories = List<String>.unmodifiable(
      categoryIds ?? state.selectedCategories,
    );
    emit(
      state.copyWith(
        status: HomeStatus.loading,
        error: null,
        gender: requestedGender,
        selectedCategories: requestedCategories,
      ),
    );

    try {
      final data = await _getHomeData(
        gender: requestedGender,
        categoryIds: requestedCategories,
      );
      if (requestId == _requestId && !isClosed) {
        emit(state.copyWith(status: HomeStatus.success, data: data));
      }
    } on HomeApiException catch (error) {
      if (requestId == _requestId && !isClosed) {
        emit(
          state.copyWith(status: HomeStatus.failure, error: error.toString()),
        );
      }
    }
  }

  void toggleCategory(String categoryId) {
    final categories = state.selectedCategories.toSet();
    if (!categories.add(categoryId)) {
      categories.remove(categoryId);
    }
    emit(state.copyWith(selectedCategories: categories.toList()));
  }

  void selectCollection(int index) {
    emit(state.copyWith(collectionIndex: index));
  }
}
