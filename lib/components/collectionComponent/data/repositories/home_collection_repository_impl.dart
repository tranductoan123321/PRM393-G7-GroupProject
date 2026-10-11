import '../../../../shared/api/home_api_client.dart';
import '../../domain/entities/collection.dart';
import '../../domain/repositories/home_collection_repository.dart';
import '../datasources/home_collection_remote_data_source.dart';
import '../models/collection_model.dart';

class HomeCollectionRepositoryImpl implements HomeCollectionRepository {
  HomeCollectionRepositoryImpl({HomeApiClient? apiClient})
    : _dataSource = HomeCollectionRemoteDataSource(
        apiClient ?? HomeApiClient(),
      );

  final HomeCollectionRemoteDataSource _dataSource;

  @override
  Future<List<HomeCollection>> getCollections() async {
    final jsonList = await _dataSource.getCollections();
    return jsonList
        .map((json) => HomeCollectionModel.fromJson(json).entity)
        .toList(growable: false);
  }
}
