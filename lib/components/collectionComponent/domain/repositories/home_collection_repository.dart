import '../entities/collection.dart';

abstract interface class HomeCollectionRepository {
  Future<List<HomeCollection>> getCollections();
}
