import 'package:flutter/material.dart';

import '../../../../../components/productComponent/domain/entities/brand.dart';
import '../../../../shared/widgets/home_network_image.dart';
import '../../../../shared/widgets/home_section_title.dart';

const _ink = Color(0xFF001D34);
const _primary = Color(0xFF00629D);

class BrandComponent extends StatelessWidget {
  const BrandComponent({required this.brands, super.key});

  final List<HomeBrand> brands;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final brand in brands)
        if (brand.products.isNotEmpty) ...[
          HomeSectionTitle(title: brand.name, action: 'Discover'),
          SizedBox(
            height: 200,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              scrollDirection: Axis.horizontal,
              itemCount: brand.products.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final product = brand.products[index];
                return SizedBox(
                  width: 150,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: HomeNetworkImage(
                            product.imageUrl,
                            width: 150,
                            fit: BoxFit.cover,
                            fallbackIcon: Icons.image_not_supported_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _ink, fontSize: 13),
                      ),
                      Text(
                        '\$${product.price}',
                        style: const TextStyle(
                          color: _primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
    ],
  );
}
