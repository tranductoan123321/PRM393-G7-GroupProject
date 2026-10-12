import 'package:flutter/material.dart';

import '../../../../../components/productComponent/domain/entities/product.dart';
import '../../../../shared/widgets/home_network_image.dart';
import '../../../../shared/widgets/home_section_title.dart';

const _ink = Color(0xFF001D34);

class OffersCarouselComponent extends StatelessWidget {
  const OffersCarouselComponent({required this.offers, super.key});

  final List<HomeProduct> offers;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const HomeSectionTitle(title: 'Offers', action: 'Discover'),
      if (offers.isEmpty)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No offers available.'),
        )
      else
        SizedBox(
          height: 180,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: offers.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = offers[index];
              return SizedBox(
                width: 230,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      HomeNetworkImage(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        fallbackIcon: Icons.image_not_supported_outlined,
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 72,
                          color: _ink.withValues(alpha: 0.82),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Text(
                                  product.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '\$${product.oldPrice}',
                                    style: const TextStyle(
                                      color: Color(0xFF99CBFF),
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '\$${product.price}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Positioned(
                        top: 8,
                        right: 8,
                        child: Icon(Icons.favorite_border, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
    ],
  );
}
