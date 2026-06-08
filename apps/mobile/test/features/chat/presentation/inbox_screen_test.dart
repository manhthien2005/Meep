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
import 'package:meep/features/space/application/space_controller.dart';
import 'package:meep/features/space/data/space.dart';
import 'package:meep/features/space/data/space_member.dart';
import 'package:meep/features/space/data/space_repository.dart';

/// Minimal in-memory SpaceRepository — chỉ implement 2 method chat dùng.
/// Các method khác throw `UnimplementedError` (mutations CF không test tới).
class _FakeSpaceRepository implements SpaceRepository {
  @override
  Stream<Space?> watchSpace(String spaceId) =>
      Stream<Space?>.value(ChatSeed.seedSpace());

  @override
  Stream<List<SpaceMember>> watchMembers(String spaceId) =>
      Stream<List<SpaceMember>>.value(ChatSeed.seedMembers());

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
        '_FakeSpaceRepository: ${invocation.memberName} not implemented',
      );
}

void main() {
  /// Seed ChatSeed conversations into fake Firestore so the inbox renders
  /// the same 3 tiles as the FE-first round.
  Future<void> seedSeedData(FakeFirebaseFirestore firestore) async {
    for (final c in ChatSeed.seedConversations()) {
      await firestore.collection('conversations').doc(c.conversationId).set(
            c.toJson(),
          );
    }
    // Also seed public profiles so chatUserProfileProvider can resolve them.
    for (final entry in ChatSeed.usersByUid.entries) {
      await firestore.doc('users/${entry.key}/public/profile').set(
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
          spaceRepositoryProvider.overrideWithValue(_FakeSpaceRepository()),
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
