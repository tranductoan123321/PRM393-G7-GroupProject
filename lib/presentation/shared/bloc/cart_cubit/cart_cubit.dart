import 'package:efashion_flutter/components/cartComponent/domain/entities/cart.dart';
import 'package:efashion_flutter/components/cartComponent/domain/usecases/add_product_to_cart_usecase.dart';
import 'package:efashion_flutter/components/cartComponent/domain/usecases/create_payment_intent_usecase.dart';
import 'package:efashion_flutter/components/cartComponent/domain/usecases/edit_product_quantity_usecase.dart';
import 'package:efashion_flutter/components/cartComponent/domain/usecases/get_cart_products_usecase.dart';
import 'package:efashion_flutter/components/cartComponent/domain/usecases/remove_product_from_cart_usecase.dart';
import 'package:efashion_flutter/shared/util/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'cart_state.dart';

@injectable
class CartCubit extends Cubit<CartState> {
  final AddProductToCartUseCase _addProductToCartUseCase;
  final RemoveProductFromCartUseCase _removeProductFromCartUseCase;
  final GetCartProductsUseCase _getCartProductsUseCase;
  final EditProductQuantityUseCase _editCartProductQuantityUseCase;
  final CreatePaymentIntentUseCase _createPaymentIntentUseCase;

  CartCubit(
    this._addProductToCartUseCase,
    this._removeProductFromCartUseCase,
    this._getCartProductsUseCase,
    this._editCartProductQuantityUseCase,
    this._createPaymentIntentUseCase,
  ) : super(const CartState());

  bool get _busy =>
      state.isUpdating ||
      state.cartState == CubitState.loading ||
      state.paymentState == CubitState.loading;

  Future<void> getCartProducts() async {
    if (_busy) return;
    emit(state.copyWith(
        cartState: CubitState.loading,
        cartMessage: '',
        paymentClientSecret: '',
        paymentState: CubitState.initial));
    final response = await _getCartProductsUseCase();
    if (isClosed) return;
    response.fold(
      (failure) => emit(
        state.copyWith(
          cartState: CubitState.failure,
          cartMessage: failure.message,
        ),
      ),
      (cartProducts) => emit(
        state.copyWith(
          cart: cartProducts,
          cartState: CubitState.success,
          paymentState: CubitState.initial,
        ),
      ),
    );
  }

  Future<void> addProductToCart({
    required String productId,
  }) async {
    debugPrint('========== ${state.selectedColor} ============ ');
    debugPrint('========== ${state.selectedSize} ============ ');
    emit(
      state.copyWith(
        cartState: CubitState.loading,
        paymentState: CubitState.initial,
      ),
    );
    final response = await _addProductToCartUseCase(
      productId: productId,
      productColor: state.selectedColor,
      productSize: state.selectedSize,
      productQuantity: state.selectedQuantity,
    );
    response.fold(
      (failure) => emit(
        state.copyWith(
          cartState: CubitState.failure,
          cartMessage: failure.message,
        ),
      ),
      (cartProducts) => emit(
        state.copyWith(
          cart: cartProducts,
          cartState: CubitState.success,
        ),
      ),
    );
  }

  Future<void> removeProductFromCart(
      {required String productId, required String productName}) async {
    if (_busy) return;
    emit(state.copyWith(
        isUpdating: true,
        cartMessage: '',
        paymentState: CubitState.initial,
        paymentClientSecret: ''));
    final response = await _removeProductFromCartUseCase(productId: productId);
    if (isClosed) return;
    response.fold(
      (failure) => emit(state.copyWith(
          isUpdating: false,
          cartState: CubitState.failure,
          cartMessage: failure.message)),
      (cart) => emit(state.copyWith(
          isUpdating: false, cart: cart, cartState: CubitState.success)),
    );
  }

  Future<void> createPaymentIntent({String? collectionId}) async {
    if (_busy) return;
    if (state.cart.products.isEmpty || state.cart.total <= 0) {
      emit(state.copyWith(
          paymentState: CubitState.failure,
          paymentClientSecret: '',
          paymentMessage: 'Your cart is empty.'));
      return;
    }
    emit(state.copyWith(
        paymentState: CubitState.loading,
        paymentClientSecret: '',
        paymentMessage: ''));
    final response =
        await _createPaymentIntentUseCase(paymentType: PaymentType.cart);
    if (isClosed) return;
    response.fold(
      (failure) => emit(state.copyWith(
          paymentState: CubitState.failure, paymentMessage: failure.message)),
      (clientSecret) {
        if (clientSecret.trim().isEmpty) {
          emit(state.copyWith(
              paymentState: CubitState.failure,
              paymentMessage: 'Unable to start checkout. Please try again.'));
        } else {
          emit(state.copyWith(
              paymentClientSecret: clientSecret,
              paymentState: CubitState.success));
        }
      },
    );
  }

  Future<void> editProductQuantity(
      {required String productId, required int newQuantity}) async {
    if (_busy) return;
    final products = state.cart.products.where((item) => item.id == productId);
    if (products.isEmpty) return;
    final product = products.first;
    if (newQuantity < 1 ||
        newQuantity == product.quantity ||
        (newQuantity > product.quantity && newQuantity > product.stock)) return;
    emit(state.copyWith(
        isUpdating: true,
        cartMessage: '',
        paymentState: CubitState.initial,
        paymentClientSecret: ''));
    final response = await _editCartProductQuantityUseCase(
        productId: productId, newQuantity: newQuantity);
    if (isClosed) return;
    response.fold(
      (failure) => emit(state.copyWith(
          isUpdating: false,
          cartState: CubitState.failure,
          cartMessage: failure.message)),
      (cart) => emit(state.copyWith(
          isUpdating: false, cart: cart, cartState: CubitState.success)),
    );
  }

  void updateSelectedColor(String? color) {
    emit(state.copyWith(selectedColor: () => color));
  }

  void updateSelectedSize(String? size) {
    emit(state.copyWith(selectedSize: () => size));
  }

  void updateSelectedQuantity(int quantity) {
    emit(state.copyWith(selectedQuantity: quantity));
  }
}
