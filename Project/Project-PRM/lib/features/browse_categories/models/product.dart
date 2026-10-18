class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.oldPrice,
  });

  final String id;
  final String title;
  final String imageUrl;
  final String price;
  final String oldPrice;

  factory StoreProduct.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    final title = json['title'];
    final imageUrl = json['imageUrl'];
    final price = json['price'];
    final oldPrice = json['oldPrice'] ?? price;

    if (id == null ||
        title is! String ||
        imageUrl is! String ||
        price == null ||
        oldPrice == null) {
      throw const FormatException('Invalid product returned by the API.');
    }

    return StoreProduct(
      id: id,
      title: title,
      imageUrl: imageUrl,
      price: price.toString(),
      oldPrice: oldPrice.toString(),
    );
  }
}
