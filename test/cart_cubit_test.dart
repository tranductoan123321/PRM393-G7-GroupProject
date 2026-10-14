import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:efashion_flutter/components/cartComponent/domain/entities/cart.dart';
import 'package:efashion_flutter/components/cartComponent/domain/entities/cart_product.dart';
import 'package:efashion_flutter/components/cartComponent/domain/repositories/cart_repository.dart';
import 'package:efashion_flutter/components/cartComponent/domain/usecases/add_product_to_cart_usecase.dart';
import 'package:efashion_flutter/components/cartComponent/domain/usecases/remove_product_from_cart_usecase.dart';
import 'package:efashion_flutter/components/cartComponent/domain/usecases/get_cart_products_usecase.dart';
import 'package:efashion_flutter/components/cartComponent/domain/usecases/edit_product_quantity_usecase.dart';
import 'package:efashion_flutter/components/cartComponent/domain/usecases/create_payment_intent_usecase.dart';
import 'package:efashion_flutter/presentation/shared/bloc/cart_cubit/cart_cubit.dart';
import 'package:efashion_flutter/shared/error/failure.dart';
import 'package:efashion_flutter/shared/util/enums.dart';

Cart cartWith(int quantity) => Cart(
      products: [
        CartProduct(
            id: 'item-1',
            title: 'Shirt',
            imageUrl: '',
            quantity: quantity,
            stock: 3,
            price: 10,
            totalPrice: quantity * 10)
      ],
      subTotal: quantity * 10,
      tax: 0,
      total: quantity * 10,
    );
const emptyCart = Cart(products: [], subTotal: 0, tax: 0, total: 0);

void main() {
  late FakeCartRepository repository;
  late CartCubit cubit;
  setUp(() {
    repository = FakeCartRepository();
    cubit = CartCubit(
        AddProductToCartUseCase(repository),
        RemoveProductFromCartUseCase(repository),
        GetCartProductsUseCase(repository),
        EditProductQuantityUseCase(repository),
        CreatePaymentIntentUseCase(repository));
  });
  tearDown(() => cubit.close());

  test('view loads server products and totals', () async {
    await cubit.getCartProducts();
    expect(cubit.state.cart.total, 20);
    expect(cubit.state.cart.products.single.quantity, 2);
    expect(cubit.state.cartState, CubitState.success);
  });
  test('quantity rejects zero and exceeding stock; applies server totals',
      () async {
    await cubit.getCartProducts();
    await cubit.editProductQuantity(productId: 'item-1', newQuantity: 0);
    await cubit.editProductQuantity(productId: 'item-1', newQuantity: 4);
    expect(repository.editCalls, 0);
    await cubit.editProductQuantity(productId: 'item-1', newQuantity: 1);
    expect(repository.editCalls, 1);
    expect(cubit.state.cart.total, 10);
  });
  test('failed delete keeps products; successful delete empties cart',
      () async {
    await cubit.getCartProducts();
    repository.failDelete = true;
    await cubit.removeProductFromCart(
        productId: 'item-1', productName: 'Shirt');
    expect(cubit.state.cart.products, hasLength(1));
    expect(cubit.state.cartMessage, 'Delete failed');
    expect(cubit.state.isUpdating, false);
    repository.failDelete = false;
    await cubit.removeProductFromCart(
        productId: 'item-1', productName: 'Shirt');
    expect(cubit.state.cart, emptyCart);
  });
  test('pending quantity blocks another edit and checkout', () async {
    await cubit.getCartProducts();
    repository.pendingEdit = Completer<Either<Failure, Cart>>();
    final pending =
        cubit.editProductQuantity(productId: 'item-1', newQuantity: 3);
    await cubit.editProductQuantity(productId: 'item-1', newQuantity: 1);
    await cubit.createPaymentIntent();
    expect(repository.editCalls, 1);
    expect(repository.paymentCalls, 0);
    repository.pendingEdit!.complete(right(cartWith(3)));
    await pending;
    expect(cubit.state.isUpdating, false);
  });
  test('empty cart cannot create an intent', () async {
    await cubit.createPaymentIntent();
    expect(repository.paymentCalls, 0);
    expect(cubit.state.paymentState, CubitState.failure);
  });
  test('duplicate intent is blocked while awaiting server', () async {
    await cubit.getCartProducts();
    repository.pendingPayment = Completer<Either<Failure, String>>();
    final pending = cubit.createPaymentIntent();
    await cubit.createPaymentIntent();
    expect(repository.paymentCalls, 1);
    repository.pendingPayment!.complete(right('pi_test_secret'));
    await pending;
    expect(cubit.state.paymentClientSecret, 'pi_test_secret');
    expect(cubit.state.paymentState, CubitState.success);
  });
  test('empty secret is rejected and errors retain server message', () async {
    await cubit.getCartProducts();
    repository.secret = '';
    await cubit.createPaymentIntent();
    expect(cubit.state.paymentState, CubitState.failure);
    repository.paymentError = 'Address required';
    await cubit.createPaymentIntent();
    expect(cubit.state.paymentMessage, 'Address required');
  });
}

class FakeCartRepository implements CartRepository {
  int editCalls = 0;
  int paymentCalls = 0;
  bool failDelete = false;
  String secret = 'pi_secret';
  String? paymentError;
  Completer<Either<Failure, Cart>>? pendingEdit;
  Completer<Either<Failure, String>>? pendingPayment;
  @override
  Future<Either<Failure, Cart>> getCartProducts() async => right(cartWith(2));
  @override
  Future<Either<Failure, Cart>> editProductQuantity(
      {required String productId, required int newQuantity}) {
    editCalls++;
    return pendingEdit?.future ?? Future.value(right(cartWith(newQuantity)));
  }

  @override
  Future<Either<Failure, Cart>> removeProductFromCart(
          {required String productId}) async =>
      failDelete ? left(const ApiFailure('Delete failed')) : right(emptyCart);
  @override
  Future<Either<Failure, String>> createPaymentIntent(
      {required PaymentType paymentType, String? collectionId}) {
    paymentCalls++;
    return pendingPayment?.future ??
        Future.value(paymentError == null
            ? right(secret)
            : left(ApiFailure(paymentError!)));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
