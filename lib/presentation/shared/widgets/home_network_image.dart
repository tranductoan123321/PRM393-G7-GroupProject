import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class HomeNetworkImage extends StatelessWidget {
  const HomeNetworkImage(
    this.imageUrl, {
    super.key,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.image_not_supported_outlined,
  });

  final String imageUrl;
  final BoxFit fit;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      placeholder: (context, _) => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      errorWidget: (context, _, __) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(
          fallbackIcon,
          size: 32,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
