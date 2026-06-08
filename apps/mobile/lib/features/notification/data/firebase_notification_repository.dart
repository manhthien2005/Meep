import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import 'package:meep/core/error/app_error.dart';
import 'package:meep/features/notification/data/app_notification.dart';
import 'package:meep/features/notification/data/notification_preferences.dart';
import 'package:meep/features/notification/data/notification_repository.dart';

class FirebaseNotificationRepository implements NotificationRepository {
  FirebaseNotificationRepository({
    required FirebaseFirestore firestore,
    required NotificationPreferences prefs,
  })  : _firestore = firestore,
        _prefs = prefs;

  final FirebaseFirestore _firestore;
  final NotificationPreferences _prefs;

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
    // NOTIF-PERF-001: skip get + batch write Firestore nếu token cho uid này
    // không đổi so với lần ghi gần nhất (local cache). FCM token ổn định giữa
    // các lần login cùng device → tránh 1 read + 1 batch write mỗi initFcm.
    if (_prefs.cachedFcmToken(uid) == token) return;

    try {
      final tokenId = sha256.convert(utf8.encode(token)).toString();
      final existing = await _fcmTokensRef(uid).get();
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
      await _prefs.setCachedFcmToken(uid, token);
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(e, 'lưu token thông báo');
    }
  }

  /// Logout cleanup — remove every fcmTokens doc for this uid.
  @override
  Future<void> deleteFcmToken(String uid) async {
    // Clear cache trước để lần login kế tiếp (cùng device, có thể khác user)
    // luôn ghi lại token vào Firestore thay vì skip nhầm theo cache cũ.
    await _prefs.clearCachedFcmToken(uid);
    try {
      final snap = await _fcmTokensRef(uid).get();
      if (snap.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(e, 'xoá token thông báo');
    }
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
    try {
      final snap = await _notificationsRef(uid)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs
          .map(
            (doc) => AppNotification.fromJson({
              ...doc.data(),
              'notifId': doc.reference.path,
            }),
          )
          .toList();
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(e, 'tải thông báo');
    }
  }

  /// `notifId` is the full Firestore path produced by [getNotifications].
  /// Single-field update keeps the Firestore rule
  /// `affectedKeys().hasOnly(['read'])` satisfied — owner can mark read,
  /// can't tamper with title/body/type.
  ///
  /// Defensive — rejects short ids early instead of letting `_firestore.doc()`
  /// throw a generic "Invalid document path" deep inside the SDK. Mismatch
  /// usually means a caller forgot to round-trip through [getNotifications]
  /// (vd dùng `doc.id` thẳng từ a query snapshot).
  @override
  Future<void> markAsRead(String notifId) async {
    if (!notifId.contains('/')) {
      throw ArgumentError.value(
        notifId,
        'notifId',
        'markAsRead expects a full Firestore path '
            '(users/{uid}/notifications/{id}) — got a short id. Caller must '
            'use AppNotification.notifId from getNotifications().',
      );
    }
    try {
      await _firestore.doc(notifId).update({'read': true});
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(e, 'đánh dấu đã đọc');
    }
  }

  AppError _mapFirestoreError(FirebaseException e, String action) {
    final serverMessage = e.message;
    return switch (e.code) {
      'permission-denied' => ForbiddenError.message(
          message: serverMessage ?? 'Bạn không có quyền $action',
          code: e.code,
          cause: e,
        ),
      'not-found' => NotFoundError.message(
          message: serverMessage ?? 'Không tìm thấy thông báo',
          code: e.code,
          cause: e,
        ),
      'unavailable' || 'deadline-exceeded' || 'cancelled' => NetworkError(
          message: serverMessage ?? 'Mất kết nối khi $action. Thử lại sau.',
          code: e.code,
          cause: e,
        ),
      'failed-precondition' => ValidationError(
          message: serverMessage ?? 'Không thể $action: dữ liệu không hợp lệ',
          code: e.code,
          cause: e,
        ),
      _ => UnexpectedError(
          message: serverMessage ?? 'Không thể $action. Thử lại sau.',
          code: e.code,
          cause: e,
        ),
    };
  }
}
