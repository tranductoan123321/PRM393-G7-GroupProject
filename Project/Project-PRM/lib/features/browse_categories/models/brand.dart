class ProductBrand {
  const ProductBrand({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory ProductBrand.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    final name = json['name'];

    if (id == null || name is! String) {
      throw const FormatException('Invalid brand returned by the API.');
    }

    return ProductBrand(id: id, name: name);
  }
}
