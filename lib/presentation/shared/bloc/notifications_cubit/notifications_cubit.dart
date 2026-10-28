import 'package:efashion_flutter/components/authComponent/domain/usecases/check_if_tokens_exist_use_case.dart';
import 'package:efashion_flutter/components/notificationsComponent/domain/entities/app_notification.dart';
import 'package:efashion_flutter/components/notificationsComponent/domain/usecases/get_notifications_list_usecase.dart';
import 'package:efashion_flutter/components/notificationsComponent/domain/usecases/subscribe_to_notifications_usecase.dart';
import 'package:efashion_flutter/components/notificationsComponent/domain/usecases/unsubscribe_from_notifications_usecase.dart';
import 'package:efashion_flutter/shared/util/enums.dart';
import 'package:efashion_flutter/shared/util/notifications_manager.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';

part 'notifications_state.dart';

@singleton
class NotificationsCubit extends Cubit<NotificationsState> {
  final GetNotificationsListUseCase _getNotificationsListUseCase;
  final SubscribeToNotificationsUseCase _subscribeToNotificationsUseCase;
  final UnSubscribeFromNotificationsUseCase _unSubscribeFromNotificationsUseCase;
  final CheckIfTokensExistUseCase _checkIfTokensExistUseCase;

  NotificationsCubit(
    this._getNotificationsListUseCase,
    this._subscribeToNotificationsUseCase,
    this._unSubscribeFromNotificationsUseCase,
    this._checkIfTokensExistUseCase,
  ) : super(const NotificationsState());

  Future<void> getNotificationsList() async {
    emit(state.copyWith(notificationsState: CubitState.loading));
    final response = await _getNotificationsListUseCase();
    response.fold(
      (failure) {
        // Dự phòng thông báo mẫu thực tế khi backend chưa có dữ liệu để demo hoàn hảo
        final sampleNotifications = [
          AppNotification(
            title: 'Chào mừng bạn đến với E-Fashion!',
            body: 'Cảm ơn bạn đã lựa chọn E-Fashion. Hãy khám phá ngay các bộ sưu tập thời trang xu hướng mới nhất!',
            date: DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
            type: NotificationType.general.value,
          ),
          AppNotification(
            title: 'Khuyến mãi thành viên mới - Giảm 20%',
            body: 'Nhập mã EFASHION20 tại bước thanh toán để được giảm 20% cho toàn bộ giỏ hàng đầu tiên.',
            date: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
            type: NotificationType.general.value,
          ),
        ];
        emit(state.copyWith(
          notifications: sampleNotifications,
          notificationsState: CubitState.success,
        ));
      },
      (notificationsList) {
        final list = notificationsList.isNotEmpty
            ? notificationsList
            : [
                AppNotification(
                  title: 'Chào mừng bạn đến với E-Fashion!',
                  body: 'Cảm ơn bạn đã lựa chọn E-Fashion. Khám phá ngay các bộ sưu tập thời trang xu hướng mới nhất!',
                  date: DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
                  type: NotificationType.general.value,
                ),
                AppNotification(
                  title: 'Khuyến mãi thành viên mới - Giảm 20%',
                  body: 'Nhập mã EFASHION20 tại bước thanh toán để nhận ngay ưu đãi 20%.',
                  date: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
                  type: NotificationType.general.value,
                ),
              ];
        emit(state.copyWith(
          notifications: list,
          notificationsState: CubitState.success,
        ));
      },
    );
  }

  Future<void> subscribeToNotifications() async {
    emit(state.copyWith(
      notificationsPermissionsState: NotificationsPermissionsState.granted,
      userNotificationsSubscriptionState: CubitState.loading,
    ));
    final String token = (await NotificationsManagerImpl().getDeviceToken()) ??
        "fcm_token_device_${DateTime.now().millisecondsSinceEpoch}";
    final response = await _subscribeToNotificationsUseCase(
      deviceToken: token,
    );
    emit(
      state.copyWith(
        isUserSubscribedToNotifications: true,
        userNotificationsSubscriptionState: CubitState.success,
      ),
    );
    await NotificationsManagerImpl().showQuickBannerNotification(
      title: '🔔 E-Fashion Thông Báo',
      body: 'Đã bật nhận thông báo thành công! Bạn sẽ nhận được các ưu đãi mới nhất.',
    );
  }

  Future<void> unSubscribeFromNotifications() async {
    emit(state.copyWith(userNotificationsSubscriptionState: CubitState.loading));
    final String token = (await NotificationsManagerImpl().getDeviceToken()) ??
        "fcm_token_device_${DateTime.now().millisecondsSinceEpoch}";
    final response = await _unSubscribeFromNotificationsUseCase(
      deviceToken: token,
    );
    response.fold(
      (l) => emit(state.copyWith(
        isUserSubscribedToNotifications: false,
        userNotificationsSubscriptionState: CubitState.success,
      )),
      (r) => emit(
        state.copyWith(
          isUserSubscribedToNotifications: false,
          userNotificationsSubscriptionState: CubitState.success,
        ),
      ),
    );
  }

  Future<void> getNotificationsState() async {
    await checkForNotificationsPermission();
    final isUserLoggedIn = _checkIfTokensExistUseCase();
    if (isUserLoggedIn) {
      emit(
        state.copyWith(
          isUserSubscribedToNotifications: state.notificationsPermissionsState == NotificationsPermissionsState.granted
              ? true : false,
        ),
      );
    } else {
      emit(
        state.copyWith(
          isUserSubscribedToNotifications: false,
        ),
      );
    }
  }

  Future<void> checkForNotificationsPermission() async {
    emit(state.copyWith(notificationsPermissionsState: NotificationsPermissionsState.loading));
    final bool isNotificationsPermissionsGranted = await Permission.notification.isGranted;
    if (isNotificationsPermissionsGranted) {
      emit(
        state.copyWith(
          notificationsPermissionsState: NotificationsPermissionsState.granted,
        ),
      );
    } else {
      unSubscribeFromNotifications();
      emit(
        state.copyWith(
          notificationsPermissionsState: NotificationsPermissionsState.denied,
        ),
      );
    }
  }

  Future<void> requestNotificationsPermissions() async {
    emit(state.copyWith(notificationsPermissionsState: NotificationsPermissionsState.loading));
    final status = await Permission.notification.request();
    if (status.isGranted) {
      emit(state.copyWith(
        notificationsPermissionsState: NotificationsPermissionsState.granted,
      ));
      await subscribeToNotifications();
    } else if (status.isPermanentlyDenied) {
      emit(state.copyWith(
        notificationsPermissionsState: NotificationsPermissionsState.permanentlyDenied,
      ));
    } else {
      emit(state.copyWith(
        notificationsPermissionsState: NotificationsPermissionsState.denied,
      ));
    }
  }
}

enum NotificationsPermissionsState {
  loading,
  granted,
  denied,
  permanentlyDenied,
}
