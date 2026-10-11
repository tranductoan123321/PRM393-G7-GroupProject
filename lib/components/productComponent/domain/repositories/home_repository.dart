import '../entities/home_data.dart';

abstract interface class HomeRepository {
  Future<HomeData> fetchHome({int gender, List<String> categoryIds});
}
