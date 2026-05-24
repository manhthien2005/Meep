import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/features/settings/data/block_repository.dart';

part 'settings_controller.g.dart';

@Riverpod(keepAlive: true)
BlockRepository blockRepository(Ref ref) => throw UnimplementedError(
      'blockRepositoryProvider must be overridden — '
      'wire FirestoreBlockRepository in main.dart (TODO: SE/T1/TBD)',
    );

@riverpod
class SettingsController extends _$SettingsController {
  @override
  void build() {}

  Future<void> blockUser(String targetUid) async {
    // TODO(SE/T2/TBD): implement blockUser
    throw UnimplementedError('blockUser — TODO: SE/T2/TBD');
  }

  Future<void> unblockUser(String targetUid) async {
    // TODO(SE/T3/TBD): implement unblockUser
    throw UnimplementedError('unblockUser — TODO: SE/T3/TBD');
  }

  Future<void> logout() async {
    // TODO(SE/T4/TBD): implement logout — clear session + navigate to intro
    throw UnimplementedError('logout — TODO: SE/T4/TBD');
  }

  Future<void> deleteAccount() async {
    // TODO(SE/T5/TBD): implement deleteAccount — re-auth + cascade delete
    throw UnimplementedError('deleteAccount — TODO: SE/T5/TBD');
  }
}
