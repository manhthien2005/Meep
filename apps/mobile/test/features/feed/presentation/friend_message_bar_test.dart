import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:meep/core/utils/pair_id.dart';
import 'package:meep/features/chat/application/chat_controller.dart';
import 'package:meep/features/chat/application/chat_providers.dart';
import 'package:meep/features/chat/data/conversation.dart';
import 'package:meep/features/chat/data/firebase_conversation_repository.dart';
import 'package:meep/features/feed/presentation/feed_section.dart';
import 'package:meep/features/reaction/application/reaction_controller.dart';
import 'package:meep/features/reaction/data/firebase_reaction_repository.dart';

void main() {
  const myUid = 'uid-me';
  const authorUid = 'uid-author';
  const postId = 'post-1';

  late FakeFirebaseFirestore firestore;
  late FirebaseConversationRepository repo;

  Future<void> seedDirectConversation() async {
    final pairId = pairIdOf(myUid, authorUid);
    final conv = Conversation(
      conversationId: pairId,
      type: ConversationType.direct,
      participantIds: [myUid, authorUid],
      lastMessageAt: DateTime(2026, 6, 1),
      createdAt: DateTime(2026, 6, 1),
    );
    await firestore.collection('conversations').doc(pairId).set(conv.toJson());
  }

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = FirebaseConversationRepository(firestore);
  });

  Future<void> pump(WidgetTester tester) async {
    // Wider physical surface — width: 80% screen + extra room for emoji pills.
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Minimal GoRouter cho test — FriendMessageBar._send navigate `/chat/:id`
    // hoặc `/group-chat/:id` sau khi reply thành công. Test verify side
    // effect (firestore write) đã đủ; routes stub render placeholder để tránh
    // throw khi push.
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(
            body: FriendMessageBar(postId: postId, authorId: authorUid),
          ),
        ),
        GoRoute(
          path: '/chat/:id',
          builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
        ),
        GoRoute(
          path: '/group-chat/:id',
          builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          conversationRepositoryProvider.overrideWithValue(repo),
          currentChatUidProvider.overrideWith((ref) => myUid),
          reactionRepositoryProvider
              .overrideWithValue(FirebaseReactionRepository(firestore)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  group('FriendMessageBar — collapsed state', () {
    testWidgets('renders "Gửi tin nhắn..." hint + 3 emoji pills',
        (tester) async {
      await pump(tester);

      expect(find.text('Gửi tin nhắn...'), findsOneWidget);
      expect(find.text('💙'), findsOneWidget);
      expect(find.text('🤣'), findsOneWidget);
      expect(find.text('🥰'), findsOneWidget);
      expect(find.byIcon(Icons.add_reaction_outlined), findsOneWidget);
      // Composer chưa expand → KHÔNG có TextField.
      expect(find.byType(TextField), findsNothing);
    });
  });

  group('FriendMessageBar — open composer sheet', () {
    testWidgets(
        'tap "Gửi tin nhắn..." → opens modal bottom sheet với TextField',
        (tester) async {
      await pump(tester);
      await tester.tap(find.text('Gửi tin nhắn...'));
      await tester.pumpAndSettle();

      // Modal sheet rendered → TextField + close icon (empty input).
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsNothing);
    });

    testWidgets('typing trong sheet → reveals send icon (hides close)',
        (tester) async {
      await pump(tester);
      await tester.tap(find.text('Gửi tin nhắn...'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'xin chào');
      await tester.pump();

      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('tap close icon → đóng sheet trở về collapsed bar',
        (tester) async {
      await pump(tester);
      await tester.tap(find.text('Gửi tin nhắn...'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Sheet đóng — TextField mất, collapsed bar còn nguyên emoji pills.
      expect(find.byType(TextField), findsNothing);
      expect(find.text('💙'), findsOneWidget);
    });
  });

  group('FriendMessageBar — send', () {
    testWidgets('send trims + writes message to existing conversation',
        (tester) async {
      await seedDirectConversation();
      await pump(tester);
      await tester.tap(find.text('Gửi tin nhắn...'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '  hi đó  ');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      // Pump qua async send + sheet close + navigation.
      await tester.pumpAndSettle();

      // Message ghi xuống Firestore với text đã trim.
      final pairId = pairIdOf(myUid, authorUid);
      final msgs = await firestore
          .collection('conversations')
          .doc(pairId)
          .collection('messages')
          .get();
      expect(msgs.docs.length, 1);
      expect(msgs.docs.first.data()['text'], 'hi đó');
      expect(msgs.docs.first.data()['senderId'], myUid);
    });

    testWidgets('send creates conversation if missing (getOrCreate fallback)',
        (tester) async {
      // KHÔNG seed conversation — sendMessageFromFeed phải getOrCreate trước.
      await pump(tester);
      await tester.tap(find.text('Gửi tin nhắn...'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'first message');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      final pairId = pairIdOf(myUid, authorUid);
      final conv =
          await firestore.collection('conversations').doc(pairId).get();
      expect(conv.exists, isTrue);
      final msgs = await firestore
          .collection('conversations')
          .doc(pairId)
          .collection('messages')
          .get();
      expect(msgs.docs.length, 1);
      expect(msgs.docs.first.data()['text'], 'first message');
    });
  });
}
