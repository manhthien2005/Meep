import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/space/data/space.dart';

part 'feed_filter_controller.freezed.dart';
part 'feed_filter_controller.g.dart';

/// Shared filter selection cho Feed (HomeScreen) và GridView. Cùng 1
/// provider → user đổi filter ở Home, Grid mở ra giữ nguyên (và ngược lại).
///
/// Mutually exclusive: chọn author → reset space (và ngược lại). Khi cả
/// hai null = "Mọi người" (FeedFilter.all).
@freezed
class FeedFilterSelection with _$FeedFilterSelection {
  const factory FeedFilterSelection({
    /// Author uid filter — non-null → FeedFilter.person.
    String? authorUid,

    /// Space id filter — non-null → FeedFilter.space.
    String? spaceId,

    /// Label hiển thị trên topbar pill ("Mọi người" / "Bạn" / friend name / space name).
    @Default('Mọi người') String label,
  }) = _FeedFilterSelection;
}

/// keepAlive: persist xuyên route Home ↔ Grid (autoDispose sẽ reset).
/// Auto-reset khi `currentUidProvider` đổi (signOut → signIn user khác)
/// để không leak filter state qua user khác.
@Riverpod(keepAlive: true)
class FeedFilterController extends _$FeedFilterController {
  @override
  FeedFilterSelection build() {
    // Reset state khi user thật sự đổi (signOut hoặc switch account). Skip
    // initial load — prev có thể là AsyncLoading (uid chưa biết) → next emit
    // uid lần đầu KHÔNG phải user switch.
    ref.listen<AsyncValue<String?>>(currentUidProvider, (prev, next) {
      final prevUid = prev?.valueOrNull;
      final nextUid = next.valueOrNull;
      if (prevUid != null && prevUid != nextUid) {
        state = const FeedFilterSelection();
      }
    });
    return const FeedFilterSelection();
  }

  /// "Mọi người" — bỏ cả author và space.
  void selectAll() {
    debugPrint(
      '[Space Feed] FilterController.selectAll() — reset về "Mọi người"',
    );
    state = const FeedFilterSelection();
  }

  /// Filter theo author uid ("Bạn" = currentUid, hoặc friend uid).
  /// Reset space để mutual exclusive.
  void selectAuthor(String authorUid, String label) {
    debugPrint(
      '[Space Feed] FilterController.selectAuthor(authorUid=$authorUid, label="$label")',
    );
    state = FeedFilterSelection(authorUid: authorUid, label: label);
  }

  /// Filter theo Space. Reset author để mutual exclusive.
  void selectSpace(Space space) {
    debugPrint(
      '[Space Feed] FilterController.selectSpace(spaceId=${space.spaceId}, '
      'name="${space.name}", colorHex=${space.colorHex})',
    );
    state = FeedFilterSelection(spaceId: space.spaceId, label: space.name);
  }

  /// Seed từ deeplink `/space/:spaceId` — luôn override state.
  /// HomeScreen `initState` post-frame gọi method này khi route param
  /// non-null. Quyết định UX: deeplink luôn thắng filter cũ.
  void seedFromRoute({required String spaceId, required String label}) {
    debugPrint(
      '[Space Feed] FilterController.seedFromRoute(spaceId=$spaceId, label="$label") — deeplink',
    );
    state = FeedFilterSelection(spaceId: spaceId, label: label);
  }
}
