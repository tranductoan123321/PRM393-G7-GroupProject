import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../components/productComponent/domain/entities/home_data.dart';
import '../bloc/home_bloc/home_cubit.dart';
import '../bloc/home_bloc/home_state.dart';
import '../components/home/brands/brand_component.dart';
import '../components/home/categories/categories_component.dart';
import '../components/home/collection/collection_carousel_component.dart';
import '../components/home/offers/offers_carousel_component.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state.status == HomeStatus.failure) {
          return _buildError(
            context,
            state.error ?? 'Could not load Home data.',
          );
        }
        if (state.status == HomeStatus.loading || state.data == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _buildHome(state.data!, state);
      },
    );
  }

  Widget _buildHome(HomeData data, HomeState state) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F0F4),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          CollectionCarouselComponent(
            collections: data.collections,
            collectionIndex: state.collectionIndex,
            categories: data.categories,
            brands: data.brands,
          ),
          const SizedBox(height: 10),
          CategoriesComponent(categories: data.categories, state: state),
          const SizedBox(height: 20),
          OffersCarouselComponent(offers: data.offers),
          const SizedBox(height: 20),
          BrandComponent(brands: data.brands),
          const SizedBox(height: 100),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Could not load Home data',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.read<HomeCubit>().loadHome(),
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BottomNavigationBar(
          currentIndex: 0,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.black.withValues(alpha: 0.8),
          selectedItemColor: const Color(0xFF00629D),
          unselectedItemColor: Colors.white.withValues(alpha: 0.6),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          onTap: null,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              label: 'Favorite',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
