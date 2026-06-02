import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/data/firebase_user_repository.dart';
import 'package:meep/features/chat/application/chat_providers.dart';
import 'package:meep/features/chat/data/chat_seed_data.dart';
import 'package:meep/features/chat/presentation/widgets/space_members_sheet.dart';

void main() {
  Future<FakeFirebaseFirestore> seededFirestore() async {
    final firestore = FakeFirebaseFirestore();
    // Seed user profiles so chatUserProfileProvider resolves names + avatars.
    for (final entry in ChatSeed.usersByUid.entries) {
      await firestore.collection('users').doc(entry.key).set(
            entry.value.toJson(),
          );
    }
    return firestore;
  }

  Widget wrap(FakeFirebaseFirestore firestore, Widget child) => ProviderScope(
        overrides: [
          userRepositoryProvider.overrideWithValue(
            FirebaseUserRepository(firestore: firestore),
          ),
          currentChatUidProvider.overrideWith((ref) => ChatSeed.currentUid),
        ],
        child: MaterialApp(home: Scaffold(body: child)),
      );

  testWidgets('lists members with count and labels current user "Bạn"',
      (tester) async {
    final firestore = await seededFirestore();
    await tester.pumpWidget(
      wrap(firestore, const SpaceMembersSheet(spaceId: 'space-fun')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Thành viên Space'), findsOneWidget);
    // 3 seeded members.
    expect(find.text('Mọi người (3)'), findsOneWidget);
    // Current user shows as "Bạn", not their displayName.
    expect(find.text('Bạn'), findsOneWidget);
    // Other members by displayName.
    expect(find.text('Minh Anh'), findsOneWidget);
    expect(find.text('Linh'), findsOneWidget);
  });
}
