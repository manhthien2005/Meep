import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:meep/core/error/app_error.dart';
import 'package:meep/core/utils/pair_id.dart';
import 'package:meep/features/chat/data/conversation.dart';
import 'package:meep/features/chat/data/conversation_repository.dart';
import 'package:meep/features/chat/data/message.dart';

class FirebaseConversationRepository implements ConversationRepository {
  FirebaseConversationRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const _conversationsCol = 'conversations';
  static const _messagesSub = 'messages';
  static const _maxTextLength = 500;

  // --- Reads ---------------------------------------------------------------

  @override
  Stream<List<Conversation>> watchConversations(String uid) {
    // Guard against unauthenticated callers (currentChatUidProvider returns
    // '' when auth state is loading/null) — avoid a wasted Firestore round-trip
    // that returns empty anyway.
    if (uid.isEmpty) return Stream.value(const []);
    return _firestore
        .collection(_conversationsCol)
        .where('participantIds', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => Conversation.fromJson({
                  ...doc.data(),
                  'conversationId': doc.id,
                }),
              )
              .where((c) => c.status != ConversationStatus.blocked)
              .toList(),
        )
        .handleError((Object e, StackTrace s) {
      developer.log(
        'watchConversations failed: uid=$uid err=$e',
        name: 'chat',
        error: e,
        stackTrace: s,
      );
      if (e is FirebaseException) {
        throw _mapFirestoreException(e, 'tải danh sách tin nhắn');
      }
      Error.throwWithStackTrace(e, s);
    });
  }

  @override
  Stream<List<Message>> watchMessages(
    String conversationId, {
    int limit = 50,
  }) {
    return _firestore
        .collection(_conversationsCol)
        .doc(conversationId)
        .collection(_messagesSub)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      final messages = snap.docs
          .map(
            (doc) => Message.fromJson({
              ...doc.data(),
              'messageId': doc.id,
            }),
          )
          .toList();
      // Reverse to chronological ASC (oldest first) for display.
      return messages.reversed.toList();
    }).handleError((Object e, StackTrace s) {
      developer.log(
        'watchMessages failed: convId=$conversationId err=$e',
        name: 'chat',
        error: e,
        stackTrace: s,
      );
      if (e is FirebaseException) {
        throw _mapFirestoreException(e, 'tải tin nhắn');
      }
      Error.throwWithStackTrace(e, s);
    });
  }

  // --- Writes --------------------------------------------------------------

  @override
  Future<Conversation> getOrCreateConversation({
    required String uid,
    required String otherUid,
  }) async {
    if (uid.isEmpty || otherUid.isEmpty) {
      throw const ValidationError(message: 'Thiếu thông tin người dùng');
    }
    if (uid == otherUid) {
      throw const ValidationError(message: 'Không thể nhắn tin cho chính mình');
    }
    try {
      final pairId = pairIdOf(uid, otherUid);
      final docRef = _firestore.collection(_conversationsCol).doc(pairId);
      final doc = await docRef.get();

      if (doc.exists) {
        return Conversation.fromJson({
          ...doc.data()!,
          'conversationId': doc.id,
        });
      }

      // Fallback: CF acceptFriendRequest normally creates this. Idempotent.
      // Write with serverTimestamp() then re-read to return actual server time.
      await docRef.set({
        'conversationId': pairId,
        'type': 'direct',
        'participantIds': [uid, otherUid],
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': '',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        // Seed lastReadAt cho cả 2 user — tránh false-positive unread badge khi
        // mở conversation lần đầu (xem Bug #11 plan).
        'lastReadAt': {
          uid: FieldValue.serverTimestamp(),
          otherUid: FieldValue.serverTimestamp(),
        },
      });
      final created = await docRef.get();
      return Conversation.fromJson({
        ...created.data()!,
        'conversationId': created.id,
      });
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e, 'mở cuộc trò chuyện');
    }
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
    String? senderDisplayName,
    String? quotedPostId,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const ValidationError(message: 'Tin nhắn không được để trống');
    }
    if (trimmed.length > _maxTextLength) {
      throw const ValidationError(
        message: 'Tin nhắn tối đa $_maxTextLength ký tự',
      );
    }

    try {
      final msgRef = _firestore
          .collection(_conversationsCol)
          .doc(conversationId)
          .collection(_messagesSub)
          .doc(); // auto-generated ID

      final conversationRef =
          _firestore.collection(_conversationsCol).doc(conversationId);

      final batch = _firestore.batch();
      batch.set(msgRef, {
        'messageId': msgRef.id,
        'senderId': senderId,
        'text': trimmed,
        'createdAt': FieldValue.serverTimestamp(),
        if (senderDisplayName != null && senderDisplayName.isNotEmpty)
          'senderDisplayName': senderDisplayName,
        if (quotedPostId != null && quotedPostId.isNotEmpty)
          'quotedPostId': quotedPostId,
      });
      batch.update(conversationRef, {
        'lastMessage': trimmed,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': senderId,
      });
      await batch.commit();
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e, 'gửi tin nhắn');
    }
  }

  @override
  Future<void> markAsRead({
    required String conversationId,
    required String uid,
  }) async {
    if (uid.isEmpty) return;
    try {
      // Dot-notation update: chỉ ghi `lastReadAt.{uid}`, KHÔNG overwrite cả map.
      // Firestore merge field này vào doc — các uid khác giữ nguyên timestamp.
      await _firestore
          .collection(_conversationsCol)
          .doc(conversationId)
          .update({'lastReadAt.$uid': FieldValue.serverTimestamp()});
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e, 'cập nhật trạng thái đã đọc');
    }
  }

  // --- Error mapping -------------------------------------------------------

  /// Map [FirebaseException] (Firestore) sang [AppError] tương ứng.
  /// [action] = động từ tiếng Việt mô tả thao tác cho fallback message.
  AppError _mapFirestoreException(FirebaseException e, String action) {
    final serverMessage = e.message;
    switch (e.code) {
      case 'permission-denied':
        return ForbiddenError(
          '$action — kiểm tra trạng thái đăng nhập + kết bạn',
        );
      case 'not-found':
        return NotFoundError(serverMessage ?? action);
      case 'unavailable':
      case 'deadline-exceeded':
      case 'cancelled':
        return NetworkError(
          message: serverMessage ?? 'Mất kết nối khi $action. Thử lại sau.',
          code: e.code,
          cause: e,
        );
      case 'failed-precondition':
        return ValidationError(
          message: serverMessage ?? 'Không thể $action: dữ liệu không hợp lệ',
          code: e.code,
          cause: e,
        );
      default:
        return UnexpectedError(
          message: serverMessage ?? 'Không thể $action. Thử lại sau.',
          code: e.code,
          cause: e,
        );
    }
  }
}
