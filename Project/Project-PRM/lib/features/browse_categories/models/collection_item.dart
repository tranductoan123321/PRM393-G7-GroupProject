class CollectionItem {
  const CollectionItem({
    required this.title,
    required this.description,
    required this.imageUrl,
  });

  final String title;
  final String description;
  final String imageUrl;

  factory CollectionItem.fromJson(Map<String, dynamic> json) {
    final title = json['title'];
    final description = json['description'];
    final imageUrl = json['image'];

    if (title is! String || description is! String || imageUrl is! String) {
      throw const FormatException(
        'Invalid collection item returned by the API.',
      );
    }

    return CollectionItem(
      title: title,
      description: description,
      imageUrl: imageUrl,
    );
  }
}
