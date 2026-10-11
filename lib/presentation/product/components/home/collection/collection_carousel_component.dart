import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../components/collectionComponent/domain/entities/collection.dart';
import '../../../bloc/home_bloc/home_cubit.dart';
import '../../../../shared/widgets/home_network_image.dart';

const _primary = Color(0xFF00629D);

class CollectionCarouselComponent extends StatelessWidget {
  const CollectionCarouselComponent({
    required this.collections,
    required this.collectionIndex,
    super.key,
  });

  final List<HomeCollection> collections;
  final int collectionIndex;

  @override
  Widget build(BuildContext context) {
    if (collections.isEmpty) {
      return const SizedBox(
        height: 320,
        child: Center(child: Text('No collections available.')),
      );
    }
    final index = collectionIndex % collections.length;
    final collection = collections[index];
    return SizedBox(
      height: 320,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
            child: HomeNetworkImage(
              collection.imageUrl,
              fit: BoxFit.cover,
              fallbackIcon: Icons.checkroom_outlined,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.12),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.62),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: 36,
            child: IconButton(
              onPressed: null,
              tooltip: 'Search is not part of this Home-only project.',
              icon: const Icon(Icons.search_rounded, color: Colors.white),
            ),
          ),
          Positioned(
            right: 20,
            top: 36,
            child: IconButton(
              onPressed: null,
              tooltip: 'Notifications are not part of this Home-only project.',
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${collection.title.toUpperCase()} COLLECTION',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(width: 150, height: 2, color: Colors.white),
                Text(
                  '${collection.discount}%OFF',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 46,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  'For Selected collection',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          Positioned(
            right: 10,
            bottom: 24,
            child: FilledButton(
              onPressed: null,
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                disabledBackgroundColor: _primary,
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white,
                minimumSize: const Size(100, 48),
              ),
              child: const Text('Shop Now'),
            ),
          ),
          Positioned(
            left: 10,
            bottom: 34,
            child: Row(
              children: [
                for (var dot = 0; dot < collections.length; dot++)
                  Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: GestureDetector(
                      onTap: () =>
                          context.read<HomeCubit>().selectCollection(dot),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: dot == index ? 30 : 10,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: dot == index ? 1 : 0.5,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
