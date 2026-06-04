import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import 'package:meep/features/notification/data/app_notification.dart';
import 'package:meep/features/notification/data/notification_repository.dart';

/// Helper log tiếng Việt — filter trong DevTools/logcat theo tag `MEEP-NOTI-REPO`.
void _repoLog(String message, {Object? error}) {
  developer.log(message, name: 'MEEP-NOTI-REPO', error: error);
}

class FirebaseNotificationRepository implements NotificationRepository {
  FirebaseNotificationRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _fcmTokensRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('fcmTokens');

  CollectionReference<Map<String, dynamic>> _notificationsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('notifications');

  /// 1-token/user policy [OQ3]: wipe every existing fcmToken doc, then write
  /// the new one keyed by `tokenId = SHA-256(token)` (hex). Same device
  /// re-login lands on the same `tokenId` — skip the delete-then-set on the
  /// identity doc to avoid mixing delete+set for the same path inside one
  /// batch (Firestore applies in commit order, but skipping is both safer
  /// and one fewer write).
  @override
  Future<void> saveFcmToken(String uid, String token) async {
    final tokenId = sha256.convert(utf8.encode(token)).toString();
    _repoLog(
      'saveFcmToken bắt đầu: uid=$uid, tokenId=${tokenId.substring(0, 12)}..., '
      'sẽ ghi vào path users/$uid/fcmTokens/$tokenId',
    );
    try {
      final existing = await _fcmTokensRef(uid).get();
      _repoLog(
        'Tìm thấy ${existing.size} doc token cũ — sẽ xóa các doc khác tokenId hiện tại',
      );
      final batch = _firestore.batch();
      for (final doc in existing.docs) {
        if (doc.id == tokenId) continue;
        batch.delete(doc.reference);
      }
      batch.set(_fcmTokensRef(uid).doc(tokenId), {
        'token': token,
        'platform': 'android',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      _repoLog('✓ Save token thành công vào users/$uid/fcmTokens/$tokenId');
    } catch (e, st) {
      _repoLog(
        '❌ Save token THẤT BẠI cho uid=$uid — kiểm tra Firestore rules cho users/$uid/fcmTokens (cần allow write nếu isOwner)',
        error: e,
      );
      developer.log('stacktrace', name: 'MEEP-NOTI-REPO', stackTrace: st);
      rethrow;
    }
  }

  /// Logout cleanup — remove every fcmTokens doc for this uid.
  @override
  Future<void> deleteFcmToken(String uid) async {
    final snap = await _fcmTokensRef(uid).get();
    if (snap.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Newest first. `new_post` notifications are push-only and never persisted
  /// (spec §Data model, OQ2) so no client-side type filter is needed —
  /// Cloud Functions simply skip the doc write for that type.
  ///
  /// `notifId` is populated with the full Firestore path (e.g.
  /// `users/{uid}/notifications/{id}`) so [markAsRead] can resolve the doc
  /// without re-passing uid through the abstract API.
  @override
  Future<List<AppNotification>> getNotifications(String uid) async {
    _repoLog(
      'getNotifications: đọc users/$uid/notifications, order by createdAt desc',
    );
    try {
      final snap = await _notificationsRef(uid)
          .orderBy('createdAt', descending: true)
          .get();
      _repoLog('✓ Đọc xong, tìm thấy ${snap.size} notification cho uid=$uid');
      return snap.docs
          .map(
            (doc) => AppNotification.fromJson({
              ...doc.data(),
              'notifId': doc.reference.path,
            }),
          )
          .toList();
    } catch (e, st) {
      _repoLog(
        '❌ getNotifications THẤT BẠI cho uid=$uid — có thể Firestore rules chặn read hoặc index thiếu',
        error: e,
      );
      developer.log('stacktrace', name: 'MEEP-NOTI-REPO', stackTrace: st);
      rethrow;
    }
  }

  /// `notifId` is the full Firestore path produced by [getNotifications].
  /// Single-field update keeps the Firestore rule
  /// `affectedKeys().hasOnly(['read'])` satisfied — owner can mark read,
  /// can't tamper with title/body/type.
  @override
  Future<void> markAsRead(String notifId) async {
    await _firestore.doc(notifId).update({'read': true});
  }
}
