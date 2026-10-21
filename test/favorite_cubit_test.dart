import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:efashion_flutter/components/productComponent/domain/entities/product_details.dart';
import 'package:efashion_flutter/components/productComponent/domain/repositories/product_repository.dart';
import 'package:efashion_flutter/components/productComponent/domain/usecases/favorite/add_product_to_favorite_list_usecase.dart';
import 'package:efashion_flutter/components/productComponent/domain/usecases/favorite/get_favorite_products_usecase.dart';
import 'package:efashion_flutter/components/productComponent/domain/usecases/favorite/get_user_favorite_products_ids.dart';
import 'package:efashion_flutter/components/productComponent/domain/usecases/favorite/remove_product_from_favorite_list_usecase.dart';
import 'package:efashion_flutter/components/productComponent/domain/usecases/home/get_product_details_usecase.dart';
import 'package:efashion_flutter/presentation/shared/bloc/favorite_cubit/favorite_cubit.dart';
import 'package:efashion_flutter/shared/error/failure.dart';
import 'package:efashion_flutter/shared/util/enums.dart';

const product = ProductDetails(
    id: 'shirt',
    title: 'Shirt',
    description: '',
    images: [],
    price: 10,
    colors: [],
    sizes: [],
    stock: 5);

class FavoriteRepositoryStub implements ProductRepository {
  bool failLoad = false;
  bool failRemove = false;
  int removes = 0;
  Completer<void>? pendingRemove;
  final ids = <String>{product.id};
  @override
  Future<Either<Failure, Set<String>>> getUserFavoriteProductIds() async =>
      failLoad ? const Left(Failure('Offline')) : Right(Set.of(ids));
  @override
  Future<Either<Failure, List<ProductDetails>>> getFavoriteProducts(
          {required Set<String> favoriteIds}) async =>
      Right(favoriteIds.contains(product.id) ? [product] : []);
  @override
  Future<Either<Failure, String>> removeProductFromFavoriteList(
      {required String productId}) async {
    removes++;
    if (pendingRemove != null) await pendingRemove!.future;
    if (failRemove) return const Left(Failure('Offline'));
    ids.remove(productId);
    return Right(productId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

FavoriteCubit cubitFor(FavoriteRepositoryStub repository) => FavoriteCubit(
    GetUserFavoriteProductsIdsUseCase(repository),
    AddProductToFavoriteListUseCase(repository),
    RemoveProductFromFavoriteListUseCase(repository),
    GetProductDetailsUseCase(repository),
    GetFavoriteProductsUseCase(repository));
void main() {
  test('wishlist load awaits product details and reports load errors',
      () async {
    final repository = FavoriteRepositoryStub();
    final cubit = cubitFor(repository);
    addTearDown(cubit.close);
    await cubit.getUserFavoriteIdList();
    expect(cubit.state.favoriteListState, CubitState.success);
    expect(cubit.state.favoriteList, [product]);
    repository.failLoad = true;
    await cubit.getUserFavoriteIdList();
    expect(cubit.state.favoriteListState, CubitState.failure);
    expect(cubit.state.favoriteListFailMessage, 'Offline');
  });
  test('successful removal updates IDs and product list', () async {
    final cubit = cubitFor(FavoriteRepositoryStub());
    addTearDown(cubit.close);
    await cubit.getUserFavoriteIdList();
    await cubit.addOrRemoveProductFromFavoriteListEvent(productId: product.id);
    expect(cubit.state.favoritesIds, isEmpty);
    expect(cubit.state.favoriteList, isEmpty);
  });
  test('failed removal retains wishlist data and exposes error', () async {
    final repository = FavoriteRepositoryStub()..failRemove = true;
    final cubit = cubitFor(repository);
    addTearDown(cubit.close);
    await cubit.getUserFavoriteIdList();
    await cubit.addOrRemoveProductFromFavoriteListEvent(productId: product.id);
    expect(cubit.state.favoritesIds, contains(product.id));
    expect(cubit.state.favoriteList, [product]);
    expect(cubit.state.addOrRemoveFromFavoriteFailMessage, 'Offline');
  });
  test('repeated taps send only one removal while request is pending',
      () async {
    final repository = FavoriteRepositoryStub()
      ..pendingRemove = Completer<void>();
    final cubit = cubitFor(repository);
    addTearDown(cubit.close);
    await cubit.getUserFavoriteIdList();
    final first =
        cubit.addOrRemoveProductFromFavoriteListEvent(productId: product.id);
    await cubit.addOrRemoveProductFromFavoriteListEvent(productId: product.id);
    expect(repository.removes, 1);
    repository.pendingRemove!.complete();
    await first;
    expect(cubit.state.favoriteList, isEmpty);
  });
}
