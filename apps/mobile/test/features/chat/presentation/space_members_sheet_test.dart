import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meep/features/chat/application/chat_providers.dart';
import 'package:meep/features/chat/data/chat_seed_data.dart';
import 'package:meep/features/chat/presentation/widgets/space_members_sheet.dart';

void main() {
  Widget wrap(Widget child) => ProviderScope(
        overrides: [
          currentChatUidProvider.overrideWith((ref) => ChatSeed.currentUid),
        ],
        child: MaterialApp(home: Scaffold(body: child)),
      );

  testWidgets('lists members with count and labels current user "Bạn"',
      (tester) async {
    await tester.pumpWidget(
      wrap(const SpaceMembersSheet(spaceId: 'space-fun')),
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
