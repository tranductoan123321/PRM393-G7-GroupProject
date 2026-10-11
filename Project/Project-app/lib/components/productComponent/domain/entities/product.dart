class HomeProduct {
  const HomeProduct({
    required this.id,
    required this.title,
    required this.price,
    required this.oldPrice,
    required this.imageUrl,
  });

  final String id;
  final String title;
  final num price;
  final num oldPrice;
  final String imageUrl;
}
