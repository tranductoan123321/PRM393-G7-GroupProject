import '../../../../shared/api/home_api_exception.dart';
import '../../domain/entities/brand.dart';
import '../../domain/entities/product.dart';

class HomeBrandModel {
  const HomeBrandModel._(this.id, this.name, this.imageUrl);

  final String id;
  final String name;
  final String imageUrl;

  factory HomeBrandModel.fromJson(Map<String, dynamic> json) {
    final imageUrl = json['logo'];
    return HomeBrandModel._(
      _requiredString(json, 'id'),
      _requiredString(json, 'name'),
      imageUrl is String ? imageUrl : '',
    );
  }

  HomeBrand toEntity(List<HomeProduct> products) =>
      HomeBrand(id: id, name: name, imageUrl: imageUrl, products: products);
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw HomeApiException('Backend item is missing a valid "$key" field.');
}
