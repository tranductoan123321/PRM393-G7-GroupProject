import '../../entities/home_data.dart';
import '../../repositories/home_repository.dart';

class GetHomeDataUseCase {
  const GetHomeDataUseCase(this._repository);

  final HomeRepository _repository;

  Future<HomeData> call({
    int gender = 0,
    List<String> categoryIds = const [],
  }) => _repository.fetchHome(gender: gender, categoryIds: categoryIds);
}
