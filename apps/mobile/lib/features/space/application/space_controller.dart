import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/features/space/data/space.dart';
import 'package:meep/features/space/data/space_repository.dart';

part 'space_controller.freezed.dart';
part 'space_controller.g.dart';

@freezed
class SpaceState with _$SpaceState {
  const factory SpaceState({
    @Default([]) List<Space> spaces,
    @Default(false) bool isLoading,
  }) = _SpaceState;
}

@Riverpod(keepAlive: true)
SpaceRepository spaceRepository(Ref ref) => throw UnimplementedError(
      'spaceRepositoryProvider must be overridden — '
      'wire FirestoreSpaceRepository in main.dart (TODO: SP/T1/TBD)',
    );

@riverpod
class SpaceController extends _$SpaceController {
  @override
  SpaceState build() => const SpaceState();

  Future<void> createSpace({
    required String name,
    required String iconEmoji,
    required String colorHex,
    // friendUids: list of friend uids to invite (max 9 — creator is auto-added, total ≤ 10)
    required List<String> friendUids,
  }) async {
    // TODO(SP/T2/TBD): call createSpace CF
    throw UnimplementedError('createSpace — TODO: SP/T2/TBD');
  }

  Future<void> leaveSpace(String spaceId) async {
    // TODO(SP/T3/TBD): call leaveSpace CF
    throw UnimplementedError('leaveSpace — TODO: SP/T3/TBD');
  }

  Future<void> kickMember(String spaceId, String targetUid) async {
    // TODO(SP/T4/TBD): call kickMember CF
    throw UnimplementedError('kickMember — TODO: SP/T4/TBD');
  }

  Future<void> transferOwnership(String spaceId, String newCreatorUid) async {
    // TODO(SP/T5/TBD): call transferOwnership CF
    throw UnimplementedError('transferOwnership — TODO: SP/T5/TBD');
  }
}
