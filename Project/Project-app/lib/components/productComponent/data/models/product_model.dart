import '../../../../shared/api/home_api_exception.dart';
import '../../domain/entities/product.dart';

class HomeProductModel {
  const HomeProductModel._(this.entity);

  final HomeProduct entity;

  factory HomeProductModel.fromJson(Map<String, dynamic> json) {
    return HomeProductModel._(
      HomeProduct(
        id: _requiredString(json, 'id'),
        title: _requiredString(json, 'title'),
        price: _requiredNum(json, 'price'),
        oldPrice: _requiredNum(json, 'oldPrice'),
        imageUrl: _requiredString(json, 'imageUrl'),
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
