import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meep/features/notification/data/app_notification.dart';
import 'package:meep/features/notification/data/firebase_notification_repository.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirebaseNotificationRepository repo;

  const uid = 'uid-alice';
  const otherUid = 'uid-bob';

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirebaseNotificationRepository(firestore: db);
  });

  CollectionReference<Map<String, dynamic>> fcmTokensRef(String forUid) =>
      db.collection('users').doc(forUid).collection('fcmTokens');

  CollectionReference<Map<String, dynamic>> notificationsRef(String forUid) =>
      db.collection('users').doc(forUid).collection('notifications');

  String tokenIdOf(String token) =>
      sha256.convert(utf8.encode(token)).toString();

  group('saveFcmToken', () {
    const token = 'fcm-token-abc123';

    test('creates doc with tokenId = SHA-256(token), platform=android',
        () async {
      await repo.saveFcmToken(uid, token);

      final expectedId = tokenIdOf(token);
      final doc = await fcmTokensRef(uid).doc(expectedId).get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['token'], token);
      expect(doc.data()!['platform'], 'android');
      expect(doc.data()!['updatedAt'], isA<Timestamp>());
    });

    test('SHA-256 tokenId is deterministic — hex, 64 chars', () async {
      await repo.saveFcmToken(uid, token);

      final snap = await fcmTokensRef(uid).get();
      expect(snap.docs.length, 1);
      final id = snap.docs.first.id;
      expect(id.length, 64);
      expect(RegExp(r'^[0-9a-f]+$').hasMatch(id), isTrue);
    });

    test('1-token/user policy: wipes existing docs then writes new one',
        () async {
      // Seed 2 stale token docs under different ids — simulating older sessions
      // or hash mismatch from a prior bug.
      await fcmTokensRef(uid).doc('stale-1').set({
        'token': 'old-token-1',
        'platform': 'android',
        'updatedAt': Timestamp.now(),
      });
      await fcmTokensRef(uid).doc('stale-2').set({
        'token': 'old-token-2',
        'platform': 'android',
        'updatedAt': Timestamp.now(),
      });

      await repo.saveFcmToken(uid, token);

      final all = await fcmTokensRef(uid).get();
      expect(all.docs.length, 1, reason: 'exactly 1 doc after replace');
      expect(all.docs.first.id, tokenIdOf(token));
      expect(all.docs.first.data()['token'], token);
    });

    test('re-save same token is idempotent — single doc, stable tokenId',
        () async {
      await repo.saveFcmToken(uid, token);
      await repo.saveFcmToken(uid, token);

      final all = await fcmTokensRef(uid).get();
      expect(all.docs.length, 1);
      expect(all.docs.first.id, tokenIdOf(token));
    });

    test('does not touch other users fcmTokens', () async {
      await fcmTokensRef(otherUid).doc('other-token-id').set({
        'token': 'other-token',
        'platform': 'android',
        'updatedAt': Timestamp.now(),
      });

      await repo.saveFcmToken(uid, token);

      final otherSnap = await fcmTokensRef(otherUid).get();
      expect(otherSnap.docs.length, 1);
      expect(otherSnap.docs.first.data()['token'], 'other-token');
    });
  });

  group('deleteFcmToken', () {
    test('removes all docs for uid', () async {
      await fcmTokensRef(uid).doc('t1').set({
        'token': 't1',
        'platform': 'android',
        'updatedAt': Timestamp.now(),
      });
      await fcmTokensRef(uid).doc('t2').set({
        'token': 't2',
        'platform': 'android',
        'updatedAt': Timestamp.now(),
      });
      await fcmTokensRef(uid).doc('t3').set({
        'token': 't3',
        'platform': 'android',
        'updatedAt': Timestamp.now(),
      });

      await repo.deleteFcmToken(uid);

      final snap = await fcmTokensRef(uid).get();
      expect(snap.docs, isEmpty);
    });

    test('no-op when uid has no tokens — does not throw', () async {
      await expectLater(repo.deleteFcmToken(uid), completes);
    });

    test('does not touch other users fcmTokens', () async {
      await fcmTokensRef(uid).doc('mine').set({
        'token': 'mine',
        'platform': 'android',
        'updatedAt': Timestamp.now(),
      });
      await fcmTokensRef(otherUid).doc('theirs').set({
        'token': 'theirs',
        'platform': 'android',
        'updatedAt': Timestamp.now(),
      });

      await repo.deleteFcmToken(uid);

      final mine = await fcmTokensRef(uid).get();
      expect(mine.docs, isEmpty);
      final theirs = await fcmTokensRef(otherUid).get();
      expect(theirs.docs.length, 1);
    });
  });

  group('getNotifications', () {
    test('empty subcollection → empty list', () async {
      final result = await repo.getNotifications(uid);
      expect(result, isEmpty);
    });

    test('orders by createdAt DESC (newest first)', () async {
      final older = Timestamp.fromDate(DateTime(2026, 1, 1, 10));
      final middle = Timestamp.fromDate(DateTime(2026, 1, 2, 10));
      final newest = Timestamp.fromDate(DateTime(2026, 1, 3, 10));

      await notificationsRef(uid).doc('n-old').set({
        'type': 'friendRequest',
        'title': 'Old',
        'body': 'old body',
        'data': <String, String>{},
        'read': false,
        'createdAt': older,
      });
      await notificationsRef(uid).doc('n-new').set({
        'type': 'reaction',
        'title': 'New',
        'body': 'new body',
        'data': <String, String>{'postId': 'p1'},
        'read': false,
        'createdAt': newest,
      });
      await notificationsRef(uid).doc('n-mid').set({
        'type': 'friendAccepted',
        'title': 'Mid',
        'body': 'mid body',
        'data': <String, String>{},
        'read': true,
        'createdAt': middle,
      });

      final list = await repo.getNotifications(uid);

      expect(list.length, 3);
      expect(list.map((n) => n.title).toList(), ['New', 'Mid', 'Old']);
      expect(list.first.type, NotificationType.reaction);
      expect(list.first.data['postId'], 'p1');
    });

    test('notifId is populated with the full Firestore path', () async {
      await notificationsRef(uid).doc('abc').set({
        'type': 'friendRequest',
        'title': 't',
        'body': 'b',
        'data': <String, String>{},
        'read': false,
        'createdAt': Timestamp.now(),
      });

      final list = await repo.getNotifications(uid);
      expect(list.single.notifId, 'users/$uid/notifications/abc');
    });

    test('does not return notifications from other users', () async {
      await notificationsRef(uid).doc('mine').set({
        'type': 'friendRequest',
        'title': 'Mine',
        'body': '',
        'data': <String, String>{},
        'read': false,
        'createdAt': Timestamp.now(),
      });
      await notificationsRef(otherUid).doc('theirs').set({
        'type': 'friendRequest',
        'title': 'Theirs',
        'body': '',
        'data': <String, String>{},
        'read': false,
        'createdAt': Timestamp.now(),
      });

      final list = await repo.getNotifications(uid);
      expect(list.length, 1);
      expect(list.single.title, 'Mine');
    });
  });

  group('markAsRead', () {
    test('flips read to true and leaves other fields untouched', () async {
      final created = Timestamp.fromDate(DateTime(2026, 1, 1, 12));
      await notificationsRef(uid).doc('n1').set({
        'type': 'friendRequest',
        'title': 'Tin nhắn kết bạn',
        'body': 'Tap để xem',
        'data': <String, String>{'requestId': 'req-1'},
        'read': false,
        'createdAt': created,
      });

      await repo.markAsRead('users/$uid/notifications/n1');

      final snap = await notificationsRef(uid).doc('n1').get();
      final data = snap.data()!;
      expect(data['read'], isTrue);
      expect(data['type'], 'friendRequest');
      expect(data['title'], 'Tin nhắn kết bạn');
      expect(data['body'], 'Tap để xem');
      expect(data['data'], {'requestId': 'req-1'});
      expect(data['createdAt'], created);
    });

    test('only the read field is written (single-field update)', () async {
      await notificationsRef(uid).doc('n1').set({
        'type': 'reaction',
        'title': 'x',
        'body': 'y',
        'data': <String, String>{'postId': 'p1'},
        'read': false,
        'createdAt': Timestamp.now(),
      });
      final before = (await notificationsRef(uid).doc('n1').get()).data()!;

      await repo.markAsRead('users/$uid/notifications/n1');

      final after = (await notificationsRef(uid).doc('n1').get()).data()!;
      // No new keys added.
      expect(after.keys.toSet(), before.keys.toSet());
      // Only `read` changed value; every other field deep-equals the snapshot
      // (Flutter `expect` does deep equality on Map / Timestamp).
      expect(after['read'], isTrue);
      expect(after['type'], before['type']);
      expect(after['title'], before['title']);
      expect(after['body'], before['body']);
      expect(after['data'], before['data']);
      expect(after['createdAt'], before['createdAt']);
    });

    test('round-trip: getNotifications().notifId feeds markAsRead', () async {
      await notificationsRef(uid).doc('rt').set({
        'type': 'friendAccepted',
        'title': 't',
        'body': 'b',
        'data': <String, String>{},
        'read': false,
        'createdAt': Timestamp.now(),
      });

      final list = await repo.getNotifications(uid);
      await repo.markAsRead(list.single.notifId);

      final snap = await notificationsRef(uid).doc('rt').get();
      expect(snap.data()!['read'], isTrue);
    });

    test(
      'throws ArgumentError when caller passes a short id instead of a path '
      '— regression N5',
      () async {
        // Defensive guard: short id like `n1` would hit `_firestore.doc(n1)`
        // and trigger "Invalid document path" from deep inside the SDK. Reject
        // explicitly so callers get a clear error message pointing at the
        // contract (must use AppNotification.notifId from getNotifications).
        await expectLater(
          repo.markAsRead('n1'),
          throwsA(isA<ArgumentError>()),
        );
        await expectLater(
          repo.markAsRead(''),
          throwsA(isA<ArgumentError>()),
        );
      },
    );
  });
}
