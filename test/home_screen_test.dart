import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_app/components/productComponent/domain/entities/brand.dart';
import 'package:project_app/components/productComponent/domain/entities/category.dart';
import 'package:project_app/components/productComponent/domain/entities/home_data.dart';
import 'package:project_app/components/productComponent/domain/entities/product.dart';
import 'package:project_app/components/productComponent/domain/repositories/home_repository.dart';
import 'package:project_app/components/productComponent/domain/usecases/home/get_home_data_usecase.dart';
import 'package:project_app/components/collectionComponent/domain/entities/collection.dart';
import 'package:project_app/presentation/product/bloc/home_bloc/home_cubit.dart';
import 'package:project_app/presentation/product/screens/home_screen.dart';

void main() {
  testWidgets('shows Home sections using repository data', (tester) async {
    final getHomeData = GetHomeDataUseCase(_FakeHomeRepository());

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => HomeCubit(getHomeData)..loadHome(),
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('URBAN STREETWEAR 2026 COLLECTION'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Offers'), findsOneWidget);
    expect(find.text('Nike Air Max Pulse Roam'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('applies the selected category to the Home request', (
    tester,
  ) async {
    final repository = _FakeHomeRepository();
    final getHomeData = GetHomeDataUseCase(repository);

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => HomeCubit(getHomeData)..loadHome(),
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Shoes'));
    await tester.pump();
    await tester.tap(find.text('Apply'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(repository.lastCategoryIds, ['category-1']);
  });

  testWidgets('opens Search from the Home collection', (tester) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) =>
            HomeCubit(GetHomeDataUseCase(_FakeHomeRepository()))..loadHome(),
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byTooltip('Search products'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Search'), findsOneWidget);
    expect(
      find.text('Enter a product name to start searching.'),
      findsOneWidget,
    );
  });
}

class _FakeHomeRepository implements HomeRepository {
  int lastGender = 0;
  List<String> lastCategoryIds = const [];

  @override
  Future<HomeData> fetchHome({
    int gender = 0,
    List<String> categoryIds = const [],
  }) async {
    lastGender = gender;
    lastCategoryIds = List.unmodifiable(categoryIds);
    const product = HomeProduct(
      id: 'product-1',
      title: 'Nike Air Max Pulse Roam',
      price: 140,
      oldPrice: 150,
      imageUrl: '',
    );
    return const HomeData(
      collections: [
        HomeCollection(
          id: 'collection-1',
          title: 'Urban Streetwear 2026',
          description: 'Urban wear',
          price: 250,
          discount: 15,
          imageUrl: '',
        ),
      ],
      categories: [
        HomeCategory(id: 'category-1', name: 'Shoes', imageUrl: '', gender: 1),
      ],
      offers: [product],
      brands: [
        HomeBrand(
          id: 'brand-1',
          name: 'Nike',
          imageUrl: '',
          products: [product],
        ),
      ],
    );
  }

  @override
  Future<List<HomeProduct>> searchProducts({
    required String query,
    required int page,
    List<String> categoryIds = const [],
    List<String> brandIds = const [],
    int? minPrice,
    int? maxPrice,
  }) async => const [];
}
