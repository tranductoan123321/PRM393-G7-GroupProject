import '../../../../shared/api/home_api_exception.dart';
import '../../domain/entities/collection.dart';

class HomeCollectionModel {
  const HomeCollectionModel._(this.entity);

  final HomeCollection entity;

  factory HomeCollectionModel.fromJson(Map<String, dynamic> json) {
    return HomeCollectionModel._(
      HomeCollection(
        id: _requiredString(json, 'id'),
        title: _requiredString(json, 'title'),
        description: _requiredString(json, 'description'),
        price: _requiredNum(json, 'price'),
        discount: _requiredInt(json, 'discount'),
        imageUrl: _requiredString(json, 'image'),
      ),
    );
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw HomeApiException('Backend item is missing a valid "$key" field.');
}

num _requiredNum(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) return value;
  throw HomeApiException('Backend item is missing a valid "$key" field.');
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) return value;
  throw HomeApiException('Backend item is missing a valid "$key" field.');
}
