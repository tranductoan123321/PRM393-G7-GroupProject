class StoreCollection {
  const StoreCollection({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.discount,
    required this.imageUrl,
  });

  final String id;
  final String title;
  final String description;
  final int price;
  final int discount;
  final String imageUrl;

  factory StoreCollection.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    final title = json['title'];
    final description = json['description'];
    final imageUrl = json['image'];
    final price = json['price'];
    final discount = json['discount'];

    if (id == null ||
        title is! String ||
        description is! String ||
        imageUrl is! String ||
        price is! num ||
        discount is! num) {
      throw const FormatException('Invalid collection returned by the API.');
    }

    return StoreCollection(
      id: id,
      title: title,
      description: description,
      price: price.toInt(),
      discount: discount.toInt(),
      imageUrl: imageUrl,
    );
  }
}
