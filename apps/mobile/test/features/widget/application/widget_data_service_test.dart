import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meep/features/widget/application/widget_data_service.dart';

/// SharedPreferences keys mirrored from [WidgetDataService]. The plugin auto-
/// prefixes every key with `flutter.` on the Android side, but the in-memory
/// `setMockInitialValues` test backend stores them WITHOUT the prefix.
const _kPostId = 'widget_post_id';
const _kImageUrl = 'widget_image_url';
const _kAuthorAvatarUrl = 'widget_author_avatar_url';
const _kCaption = 'widget_caption';
const _kCaptionType = 'widget_caption_type';
const _kLastViewedAt = 'widget_last_viewed_at';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late WidgetDataService service;
  late List<MethodCall> channelCalls;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    service = WidgetDataService(prefs: prefs);

    channelCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('meep/widget'),
      (call) async {
        channelCalls.add(call);
        if (call.method == 'requestPinAppWidget') return true;
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('meep/widget'), null);
  });

  group('updateWidgetData', () {
    test('writes required keys and pokes Kotlin', () async {
      await service.updateWidgetData(
        postId: 'post-1',
        imageUrl: 'https://cdn/photo.jpg',
      );

      expect(prefs.getString(_kPostId), 'post-1');
      expect(prefs.getString(_kImageUrl), 'https://cdn/photo.jpg');
      expect(channelCalls.single.method, 'updateWidget');
    });

    test('persists nullable fields when provided', () async {
      await service.updateWidgetData(
        postId: 'post-1',
        imageUrl: 'https://cdn/photo.jpg',
        authorAvatarUrl: 'https://cdn/avatar.jpg',
        caption: 'hello',
        captionType: 'text',
      );

      expect(prefs.getString(_kAuthorAvatarUrl), 'https://cdn/avatar.jpg');
      expect(prefs.getString(_kCaption), 'hello');
      expect(prefs.getString(_kCaptionType), 'text');
    });

    test('removes nullable fields when absent', () async {
      // Seed values then call with nulls — expected behaviour for a post that
      // dropped its caption / avatar between two refreshes.
      await prefs.setString(_kAuthorAvatarUrl, 'old-avatar');
      await prefs.setString(_kCaption, 'old-caption');
      await prefs.setString(_kCaptionType, 'text');

      await service.updateWidgetData(
        postId: 'post-1',
        imageUrl: 'https://cdn/photo.jpg',
      );

      expect(prefs.getString(_kAuthorAvatarUrl), isNull);
      expect(prefs.getString(_kCaption), isNull);
      expect(prefs.getString(_kCaptionType), isNull);
    });

    test('does NOT touch lastViewedAt — regression W1', () async {
      // Bug: previous impl reset `lastViewedAt = now` on every call, but
      // FeedController calls updateWidgetData on every feed stream emit
      // regardless of authorship → unread badge never grew above 0.
      // Fix: lastViewedAt is owned exclusively by recordLastViewedAt.
      const seededLastViewed = 1700000000000;
      await prefs.setInt(_kLastViewedAt, seededLastViewed);

      await service.updateWidgetData(
        postId: 'post-1',
        imageUrl: 'https://cdn/photo.jpg',
      );

      expect(
        prefs.getInt(_kLastViewedAt),
        seededLastViewed,
        reason: 'updateWidgetData must NOT reset lastViewedAt — owned by '
            'recordLastViewedAt only',
      );
    });

    test('leaves lastViewedAt unset when previously unset', () async {
      // Same regression — when first post lands before user has ever resumed
      // the app, lastViewedAt should stay null (which Kotlin treats as 0L,
      // meaning every feed post counts as unread, which is the desired UX).
      expect(prefs.getInt(_kLastViewedAt), isNull);

      await service.updateWidgetData(
        postId: 'post-1',
        imageUrl: 'https://cdn/photo.jpg',
      );

      expect(prefs.getInt(_kLastViewedAt), isNull);
    });
  });

  group('recordLastViewedAt', () {
    test('writes a fresh timestamp and pokes Kotlin', () async {
      final before = DateTime.now().millisecondsSinceEpoch;
      await service.recordLastViewedAt();
      final after = DateTime.now().millisecondsSinceEpoch;

      final stored = prefs.getInt(_kLastViewedAt);
      expect(stored, isNotNull);
      expect(stored, greaterThanOrEqualTo(before));
      expect(stored, lessThanOrEqualTo(after));
      expect(channelCalls.single.method, 'updateWidget');
    });
  });

  group('clearData', () {
    test('removes every widget key and pokes Kotlin', () async {
      // Seed every key.
      await prefs.setString(_kPostId, 'post-1');
      await prefs.setString(_kImageUrl, 'url');
      await prefs.setString(_kAuthorAvatarUrl, 'avatar');
      await prefs.setString(_kCaption, 'cap');
      await prefs.setString(_kCaptionType, 'text');
      await prefs.setInt(_kLastViewedAt, 123);

      await service.clearData();

      expect(prefs.getString(_kPostId), isNull);
      expect(prefs.getString(_kImageUrl), isNull);
      expect(prefs.getString(_kAuthorAvatarUrl), isNull);
      expect(prefs.getString(_kCaption), isNull);
      expect(prefs.getString(_kCaptionType), isNull);
      expect(prefs.getInt(_kLastViewedAt), isNull);
      expect(channelCalls.single.method, 'updateWidget');
    });
  });

  group('requestPinAppWidget', () {
    test('returns true when launcher supports pinning', () async {
      final result = await service.requestPinAppWidget();
      expect(result, isTrue);
      expect(channelCalls.single.method, 'requestPinAppWidget');
    });

    test('returns false when native returns null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('meep/widget'),
        (call) async => null,
      );
      final result = await service.requestPinAppWidget();
      expect(result, isFalse);
    });

    test('returns false when native throws PlatformException — W2', () async {
      // Older Android / custom ROMs can throw if widget pin isn't supported.
      // Caller's UI flow uses the bool to decide whether to show manual
      // instructions, so a thrown exception must NOT bubble.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('meep/widget'),
        (call) async => throw PlatformException(code: 'UNSUPPORTED'),
      );
      final result = await service.requestPinAppWidget();
      expect(result, isFalse);
    });
  });

  group('channel error handling — W2 regression', () {
    // FeedController + main.dart lifecycle hook gọi update / record /
    // clear không có try/catch của riêng. Service phải swallow native
    // errors để feed stream / lifecycle callback không crash.

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('meep/widget'),
        (call) async => throw PlatformException(code: 'NATIVE_FAIL'),
      );
    });

    test('updateWidgetData completes when native throws', () async {
      await expectLater(
        service.updateWidgetData(
          postId: 'p1',
          imageUrl: 'https://cdn/x.jpg',
        ),
        completes,
      );
      // Prefs still written even when the poke failed.
      expect(prefs.getString(_kPostId), 'p1');
    });

    test('recordLastViewedAt completes when native throws', () async {
      await expectLater(service.recordLastViewedAt(), completes);
      expect(prefs.getInt(_kLastViewedAt), isNotNull);
    });

    test('clearData completes when native throws', () async {
      await prefs.setString(_kPostId, 'p1');
      await expectLater(service.clearData(), completes);
      // Prefs still cleared even when the poke failed.
      expect(prefs.getString(_kPostId), isNull);
    });
  });
}
