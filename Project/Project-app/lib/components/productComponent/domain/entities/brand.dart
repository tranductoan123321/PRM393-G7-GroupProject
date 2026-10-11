import 'product.dart';

class HomeBrand {
  const HomeBrand({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.products,
  });

  final String id;
  final String name;
  final String imageUrl;
  final List<HomeProduct> products;
}
