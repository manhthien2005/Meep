import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'widget_data_service.g.dart';

/// SharedPreferences keys — must match [WidgetDataStore.kt][1] contract exactly.
///
/// The shared_preferences plugin auto-prefixes keys with `flutter.` on Android,
/// so the raw key `widget_post_id` becomes `flutter.widget_post_id` in the
/// `FlutterSharedPreferences` file that WidgetDataStore.kt reads.
///
/// [1]: android/app/src/main/kotlin/dev/meep/meep/WidgetDataStore.kt
class _WidgetKeys {
  static const postId = 'widget_post_id';
  static const imageUrl = 'widget_image_url';
  static const authorAvatarUrl = 'widget_author_avatar_url';
  static const caption = 'widget_caption';
  static const captionType = 'widget_caption_type';
  static const lastViewedAt = 'widget_last_viewed_at';

  static const all = [
    postId,
    imageUrl,
    authorAvatarUrl,
    caption,
    captionType,
    lastViewedAt,
  ];
}

class WidgetDataService {
  WidgetDataService({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;

  static const _channel = MethodChannel('meep/widget');

  /// Write latest post data to SharedPreferences so WidgetSyncWorker (Kotlin)
  /// can pick it up on the next sync cycle.
  ///
  /// Nullable fields are removed from prefs when absent — Kotlin's
  /// WidgetDataStore.read() uses `takeIf { it.isNotBlank() }` and treats
  /// missing keys the same as empty strings.
  ///
  /// IMPORTANT — does NOT touch `lastViewedAt`. The unread badge is reset
  /// only via [recordLastViewedAt] when the user actually views the feed
  /// (`AppLifecycleState.resumed` in main.dart). Resetting here would zero
  /// the badge on every feed stream emit because this method is called from
  /// `FeedController` for the latest all-friends post regardless of author.
  Future<void> updateWidgetData({
    required String postId,
    required String imageUrl,
    String? authorAvatarUrl,
    String? caption,
    String? captionType,
  }) async {
    await _prefs.setString(_WidgetKeys.postId, postId);
    await _prefs.setString(_WidgetKeys.imageUrl, imageUrl);

    await _setOrRemove(_WidgetKeys.authorAvatarUrl, authorAvatarUrl);
    await _setOrRemove(_WidgetKeys.caption, caption);
    await _setOrRemove(_WidgetKeys.captionType, captionType);

    // Poke Kotlin to enqueue an immediate one-time refresh
    await _safePoke('updateWidget');
  }

  /// Record the moment the user opened the app (resumed).
  ///
  /// On the next WidgetSyncWorker tick, posts with createdAt > this timestamp
  /// are counted as unread. Must be called on every
  /// [AppLifecycleState.resumed], regardless of entry point.
  Future<void> recordLastViewedAt() async {
    await _prefs.setInt(
      _WidgetKeys.lastViewedAt,
      DateTime.now().millisecondsSinceEpoch,
    );
    // Poke Kotlin to recalculate badge count
    await _safePoke('updateWidget');
  }

  /// Open Android launcher's native widget picker.
  ///
  /// Maps to `AppWidgetManager.requestPinAppWidget()` (API 26+). Returns
  /// `true` when the intent was fired. Returns `false` when the launcher
  /// doesn't support automatic pinning (Android < 8.0, some custom ROMs) —
  /// caller should show manual instructions.
  ///
  /// Native errors are swallowed (returns false) — caller's UI flow uses
  /// the boolean to decide whether to show manual instructions, and a
  /// MissingPluginException on iOS shouldn't crash the settings screen.
  Future<bool> requestPinAppWidget() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestPinAppWidget');
      return result ?? false;
    } on PlatformException catch (e, st) {
      debugPrint('[WidgetDataService] requestPinAppWidget failed: $e\n$st');
      return false;
    } on MissingPluginException catch (e, st) {
      debugPrint('[WidgetDataService] requestPinAppWidget missing: $e\n$st');
      return false;
    }
  }

  /// Wipe all widget cached data from SharedPreferences.
  ///
  /// On the next WidgetSyncWorker tick, WidgetDataStore.read() returns null →
  /// placeholder displayed. Call on logout.
  Future<void> clearData() async {
    for (final key in _WidgetKeys.all) {
      await _prefs.remove(key);
    }
    await _safePoke('updateWidget');
  }

  Future<void> _setOrRemove(String key, String? value) async {
    if (value != null) {
      await _prefs.setString(key, value);
    } else {
      await _prefs.remove(key);
    }
  }

  /// Fire-and-forget MethodChannel ping — Kotlin side just enqueues a
  /// background refresh. Failure modes (`PlatformException` from a Kotlin
  /// crash, `MissingPluginException` on iOS / unit tests) are swallowed
  /// so widget syncing never blocks the feed stream / lifecycle callback.
  Future<void> _safePoke(String method) async {
    try {
      await _channel.invokeMethod(method);
    } on PlatformException catch (e, st) {
      debugPrint('[WidgetDataService] $method failed: $e\n$st');
    } on MissingPluginException catch (e, st) {
      debugPrint('[WidgetDataService] $method missing: $e\n$st');
    }
  }
}

@Riverpod(keepAlive: true)
WidgetDataService widgetDataService(Ref ref) => throw UnimplementedError(
      'wire WidgetDataService in main.dart — needs SharedPreferences.getInstance()',
    );
