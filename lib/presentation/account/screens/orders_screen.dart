import 'package:auto_route/auto_route.dart';
import 'package:efashion_flutter/injection_container.dart';
import 'package:efashion_flutter/presentation/account/bloc/orders_cubit/orders_cubit.dart';
import 'package:efashion_flutter/presentation/account/components/order_status/shimmer_loading_order_status_card.dart';
import 'package:efashion_flutter/presentation/shared/animations/custom_fade_animation.dart';
import 'package:efashion_flutter/presentation/shared/widgets/custom_appbar.dart';
import 'package:efashion_flutter/presentation/account/components/order_status/order_status_card.dart';
import 'package:efashion_flutter/presentation/shared/widgets/no_internet_connection_widget.dart';
import 'package:efashion_flutter/shared/util/enums.dart';
import 'package:efashion_flutter/shared/util/strings_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

@RoutePage()
class OrdersScreen extends StatefulWidget implements AutoRouteWrapper {
  const OrdersScreen({super.key});
  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<OrdersCubit>()..getOrdersList(),
      child: this,
    );
  }

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 50.0, left: 24, right: 24).r,
        child: Column(
          children: [
            const CustomAppBar(
              appBarTitle: StringsManager.orderScreenTitle,
              appBarType: AppBarType.normal,
            ),
            Expanded(
              child: BlocConsumer<OrdersCubit, OrdersState>(
                listener: (context, state) {
                  if (state.ordersState == CubitState.loading) {
                    isLoading = true;
                  } else {
                    isLoading = false;
                  }
                },
                builder: (context, state) {
                  if (state.ordersState == CubitState.failure) {
                    return NoInternetConnectionWidget(
                      onButtonTap: () {
                        context.read<OrdersCubit>().getOrdersList();
                      },
                      isButtonLoading: isLoading,
                    );
                  } else {
                    return ListView.builder(
                      itemCount: state.ordersState == CubitState.loading
                          ? 5
                          : state.orders.length,
                      itemBuilder: (context, index) {
                        if (state.ordersState == CubitState.initial ||
                            state.ordersState == CubitState.loading) {
                          return const ShimmerLoadingOrderStatusCard();
                        } else {
                          return CustomFadeAnimation(
                            duration: const Duration(milliseconds: 500),
                            child: InkWell(
                              onTap: () {
                                final order = state.orders[index];
                                showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (context) => SafeArea(
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            StringsManager.orderReceiptTitle,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.headlineSmall,
                                          ),
                                          const SizedBox(height: 24),
                                          SelectableText(
                                            'Order ID: ${order.id}',
                                          ),
                                          const SizedBox(height: 12),
                                          Text('Items: ${order.totalQuantity}'),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Total: ${StringsManager.currencySign}${order.totalPrice}',
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            order.status == 1
                                                ? StringsManager.orderInItsWay
                                                : order.status == 2
                                                    ? StringsManager
                                                        .orderInProgress
                                                    : StringsManager
                                                        .orderDelivered,
                                          ),
                                          const SizedBox(height: 24),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Close'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: OrderStatusCard(
                                orderId: state.orders[index].id,
                                orderCost: state.orders[index].totalPrice,
                                orderStatus: state.orders[index].status,
                              ),
                            ),
                          );
                        }
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
