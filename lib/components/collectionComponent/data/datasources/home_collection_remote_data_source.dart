import '../../../../shared/api/home_api_client.dart';

class HomeCollectionRemoteDataSource {
  const HomeCollectionRemoteDataSource(this._apiClient);

  final HomeApiClient _apiClient;

  Future<List<Map<String, dynamic>>> getCollections() =>
      _apiClient.getList('/collection');
}
