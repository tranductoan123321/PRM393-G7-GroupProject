import '../../domain/entities/category.dart';
import '../../../../shared/api/home_api_exception.dart';

class HomeCategoryModel {
  const HomeCategoryModel._(this.entity);

  final HomeCategory entity;

  factory HomeCategoryModel.fromJson(Map<String, dynamic> json) {
    final gender = json['gender'];
    if (gender is! int) {
      throw const HomeApiException(
        'Backend item is missing a valid "gender" field.',
      );
    }
    return HomeCategoryModel._(
      HomeCategory(
        id: _requiredString(json, 'id'),
        name: _requiredString(json, 'name'),
        imageUrl: _requiredString(json, 'imageURL'),
        gender: gender,
      ),
    );
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw HomeApiException('Backend item is missing a valid "$key" field.');
}
