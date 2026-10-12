import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../components/productComponent/domain/entities/category.dart';
import '../../../bloc/home_bloc/home_cubit.dart';
import '../../../bloc/home_bloc/home_state.dart';
import '../../../../shared/widgets/home_network_image.dart';

const _primary = Color(0xFF00629D);
const _ink = Color(0xFF001D34);
const _cardColor = Color(0xFFDEE3EB);

class CategoriesComponent extends StatelessWidget {
  const CategoriesComponent({
    required this.categories,
    required this.state,
    super.key,
  });

  final List<HomeCategory> categories;
  final HomeState state;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 40,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Categories',
                  style: TextStyle(fontSize: 14, color: _ink),
                ),
              ),
              if (state.selectedCategories.isNotEmpty || state.gender != 0)
                TextButton(
                  onPressed: () => context.read<HomeCubit>().loadHome(),
                  child: const Text('Apply'),
                ),
            ],
          ),
        ),
      ),
      SizedBox(
        height: 90,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          children: [
            _GenderCard(title: 'Woman', gender: 2, state: state),
            const SizedBox(width: 10),
            _GenderCard(title: 'Men', gender: 1, state: state),
            if (categories.isNotEmpty) const SizedBox(width: 14),
            for (final category in categories)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _CategoryCard(category: category, state: state),
              ),
          ],
        ),
      ),
    ],
  );
}

class _GenderCard extends StatelessWidget {
  const _GenderCard({
    required this.title,
    required this.gender,
    required this.state,
  });

  final String title;
  final int gender;
  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final selected = state.gender == gender;
    final imageUrl = gender == 2
        ? 'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=200'
        : 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=200';
    return InkWell(
      onTap: () => context.read<HomeCubit>().loadHome(
        gender: selected ? 0 : gender,
        categoryIds: const [],
      ),
      child: Container(
        width: 72,
        decoration: BoxDecoration(
          color: _cardColor,
          border: selected ? Border.all(color: _primary, width: 2) : null,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipOval(
              child: HomeNetworkImage(
                imageUrl,
                width: 46,
                height: 46,
                fit: BoxFit.cover,
                fallbackIcon: Icons.person_outline,
              ),
            ),
            Text(title, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.state});

  final HomeCategory category;
  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final selected = state.selectedCategories.contains(category.id);
    return InkWell(
      onTap: () => context.read<HomeCubit>().toggleCategory(category.id),
      child: Container(
        width: 82,
        decoration: BoxDecoration(
          color: _cardColor,
          border: selected ? Border.all(color: _primary, width: 2) : null,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipOval(
              child: HomeNetworkImage(
                category.imageUrl,
                width: 46,
                height: 46,
                fit: BoxFit.cover,
                fallbackIcon: Icons.checkroom_outlined,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
