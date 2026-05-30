import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/chat/application/chat_controller.dart';
import 'package:meep/features/chat/data/conversation.dart';
import 'package:meep/features/chat/data/conversation_repository.dart';
import 'package:meep/features/chat/data/fake_conversation_repository.dart';
import 'package:meep/features/chat/presentation/inbox_screen.dart';
import 'package:meep/features/chat/presentation/widgets/conversation_tile.dart';

/// Repository that always emits an empty conversation list.
class _EmptyRepo extends FakeConversationRepository {
  @override
  Stream<List<Conversation>> watchConversations(String uid) async* {
    yield const [];
  }
}

void main() {
  Widget wrap(ConversationRepository repo) => ProviderScope(
        overrides: [conversationRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: InboxScreen()),
      );

  testWidgets('renders title and seeded conversation tiles', (tester) async {
    await tester.pumpWidget(wrap(FakeConversationRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Tin nhắn'), findsOneWidget);
    // 3 seeded conversations → 3 tiles.
    expect(find.byType(ConversationTile), findsNWidgets(3));
  });

  testWidgets('shows 1-1 name and group name', (tester) async {
    await tester.pumpWidget(wrap(FakeConversationRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Talaki'), findsOneWidget); // direct
    expect(find.text('Hội bạn thân'), findsOneWidget); // group/space
  });

  testWidgets('empty state shows Vietnamese CTA', (tester) async {
    await tester.pumpWidget(wrap(_EmptyRepo()));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Chưa có tin nhắn nào'),
      findsOneWidget,
    );
    expect(find.byType(ConversationTile), findsNothing);
  });
}
