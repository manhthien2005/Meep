import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/data/firebase_user_repository.dart';
import 'package:meep/features/chat/application/chat_controller.dart';
import 'package:meep/features/chat/application/chat_providers.dart';
import 'package:meep/features/chat/data/chat_seed_data.dart';
import 'package:meep/features/chat/data/firebase_conversation_repository.dart';
import 'package:meep/features/chat/presentation/inbox_screen.dart';
import 'package:meep/features/chat/presentation/widgets/conversation_tile.dart';

void main() {
  /// Seed ChatSeed conversations into fake Firestore so the inbox renders
  /// the same 3 tiles as the FE-first round.
  Future<void> seedSeedData(FakeFirebaseFirestore firestore) async {
    for (final c in ChatSeed.seedConversations()) {
      await firestore.collection('conversations').doc(c.conversationId).set(
            c.toJson(),
          );
    }
    // Also seed user profiles so chatUserProfileProvider can resolve them.
    for (final entry in ChatSeed.usersByUid.entries) {
      await firestore.collection('users').doc(entry.key).set(
            entry.value.toJson(),
          );
    }
  }

  Widget wrap(FakeFirebaseFirestore firestore) => ProviderScope(
        overrides: [
          conversationRepositoryProvider.overrideWithValue(
            FirebaseConversationRepository(firestore),
          ),
          userRepositoryProvider.overrideWithValue(
            FirebaseUserRepository(firestore: firestore),
          ),
          currentChatUidProvider.overrideWith((ref) => ChatSeed.currentUid),
        ],
        child: const MaterialApp(home: InboxScreen()),
      );

  testWidgets('renders title and seeded conversation tiles', (tester) async {
    final firestore = FakeFirebaseFirestore();
    await seedSeedData(firestore);

    await tester.pumpWidget(wrap(firestore));
    await tester.pumpAndSettle();

    expect(find.text('Tin nhắn'), findsOneWidget);
    expect(find.byType(ConversationTile), findsNWidgets(3));
  });

  testWidgets('shows 1-1 name and group name', (tester) async {
    final firestore = FakeFirebaseFirestore();
    await seedSeedData(firestore);

    await tester.pumpWidget(wrap(firestore));
    await tester.pumpAndSettle();

    expect(find.text('Talaki'), findsOneWidget); // direct
    expect(find.text('Hội bạn thân'), findsOneWidget); // group/space
  });

  testWidgets('empty state shows Vietnamese CTA', (tester) async {
    // Don't seed — Firestore starts empty.
    final firestore = FakeFirebaseFirestore();

    await tester.pumpWidget(wrap(firestore));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Chưa có tin nhắn nào'),
      findsOneWidget,
    );
    expect(find.byType(ConversationTile), findsNothing);
  });
}
