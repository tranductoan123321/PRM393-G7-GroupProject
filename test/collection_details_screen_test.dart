import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_app/components/collectionComponent/domain/entities/collection.dart';
import 'package:project_app/components/collectionComponent/domain/entities/collection_item.dart';
import 'package:project_app/components/collectionComponent/domain/repositories/home_collection_repository.dart';
import 'package:project_app/presentation/product/screens/collection_details_screen.dart';

void main() {
  testWidgets('loads and displays the collection items', (tester) async {
    final repository = _FakeCollectionRepository();
    const collection = HomeCollection(
      id: 'collection-1',
      title: 'Urban Streetwear',
      description: 'Everyday urban styles',
      price: 250,
      discount: 15,
      imageUrl: '',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CollectionDetailsScreen(
          collection: collection,
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.requestedCollectionId, 'collection-1');
    expect(find.text('Canvas jacket'), findsOneWidget);
    expect(find.text('Cotton jacket for everyday wear.'), findsOneWidget);
  });
}

class _FakeCollectionRepository implements HomeCollectionRepository {
  String? requestedCollectionId;

  @override
  Future<List<HomeCollection>> getCollections() async => const [];

  @override
  Future<List<HomeCollectionItem>> getCollectionItems(
    String collectionId,
  ) async {
    requestedCollectionId = collectionId;
    return const [
      HomeCollectionItem(
        title: 'Canvas jacket',
        description: 'Cotton jacket for everyday wear.',
        imageUrl: '',
      ),
    ];
  }
}
