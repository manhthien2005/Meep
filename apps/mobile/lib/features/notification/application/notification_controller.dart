import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/features/notification/data/notification_repository.dart';

part 'notification_controller.g.dart';

@Riverpod(keepAlive: true)
NotificationRepository notificationRepository(Ref ref) =>
    throw UnimplementedError(
      'notificationRepositoryProvider must be overridden — '
      'wire FirestoreNotificationRepository in main.dart (TODO: N/T1/TBD)',
    );

@riverpod
class NotificationController extends _$NotificationController {
  @override
  void build() {}

  Future<void> initFcm() async {
    // TODO(N/T2/TBD): request permission + get token + saveFcmToken
    throw UnimplementedError('initFcm — TODO: N/T2/TBD');
  }

  Future<void> markAsRead(String notifId) async {
    // TODO(N/T3/TBD): implement markAsRead
    throw UnimplementedError('markAsRead — TODO: N/T3/TBD');
  }
}
