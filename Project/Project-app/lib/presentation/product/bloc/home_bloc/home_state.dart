import '../../../../components/productComponent/domain/entities/home_data.dart';

enum HomeStatus { loading, success, failure }

class HomeState {
  const HomeState({
    this.status = HomeStatus.loading,
    this.data,
    this.error,
    this.gender = 0,
    this.selectedCategories = const [],
    this.collectionIndex = 0,
  });

  final HomeStatus status;
  final HomeData? data;
  final String? error;
  final int gender;
  final List<String> selectedCategories;
  final int collectionIndex;

  HomeState copyWith({
    HomeStatus? status,
    HomeData? data,
    String? error,
    int? gender,
    List<String>? selectedCategories,
    int? collectionIndex,
  }) => HomeState(
    status: status ?? this.status,
    data: data ?? this.data,
    error: error,
    gender: gender ?? this.gender,
    selectedCategories: selectedCategories ?? this.selectedCategories,
    collectionIndex: collectionIndex ?? this.collectionIndex,
  );
}
