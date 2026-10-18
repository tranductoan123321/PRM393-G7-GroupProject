class ProductCategory {
  const ProductCategory({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.gender,
  });

  final String id;
  final String name;
  final String imageUrl;
  final int gender;

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    final name = json['name'];
    final imageUrl = json['imageURL'];
    final gender = json['gender'];

    if (id == null ||
        name is! String ||
        imageUrl is! String ||
        gender is! num) {
      throw const FormatException('Invalid category returned by the API.');
    }

    return ProductCategory(
      id: id,
      name: name,
      imageUrl: imageUrl,
      gender: gender.toInt(),
    );
  }
}
