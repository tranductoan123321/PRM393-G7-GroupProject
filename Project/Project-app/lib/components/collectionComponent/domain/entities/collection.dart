class HomeCollection {
  const HomeCollection({
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
  final num price;
  final int discount;
  final String imageUrl;
}
