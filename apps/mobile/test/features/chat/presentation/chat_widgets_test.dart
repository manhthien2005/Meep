import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:meep/features/chat/presentation/widgets/message_bubble.dart';
import 'package:meep/shared/widgets/app_avatar.dart';

void main() {
  group('MessageBubble', () {
    testWidgets('mine: no avatar, aligned end', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MessageBubble(text: 'Hi', isMine: true, avatarUrl: 'x'),
          ),
        ),
      );

      expect(find.text('Hi'), findsOneWidget);
      final row = tester.widget<Row>(find.byType(Row).first);
      expect(row.mainAxisAlignment, MainAxisAlignment.end);
    });

    testWidgets('theirs: shows avatar, aligned start', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MessageBubble(text: 'Yo', isMine: false),
          ),
        ),
      );

      final row = tester.widget<Row>(find.byType(Row).first);
      expect(row.mainAxisAlignment, MainAxisAlignment.start);
      expect(find.byType(AppAvatar), findsOneWidget);
    });

    testWidgets('theirs: hides avatar when isLastInGroup=false (Bug #4 dedupe)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              text: 'Yo',
              isMine: false,
              isLastInGroup: false,
            ),
          ),
        ),
      );

      // Avatar không render — thay bằng SizedBox spacer giữ alignment.
      expect(find.byType(AppAvatar), findsNothing);
    });

    testWidgets('theirs: shows senderName when showSenderName=true (Bug #2)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              text: 'Hello group',
              isMine: false,
              senderName: 'Khoa',
              showSenderName: true,
            ),
          ),
        ),
      );

      expect(find.text('Khoa'), findsOneWidget);
    });

    testWidgets('theirs: KHÔNG render senderName label khi null (clean UI)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              text: 'Hello',
              isMine: false,
              showSenderName: true,
            ),
          ),
        ),
      );

      // KHÔNG fallback "Người dùng" — UI sạch hơn cho messages cũ chưa có
      // senderDisplayName + profile chưa resolve. ChatThreadView pass realtime
      // displayName từ chatUserProfileProvider — null chỉ trong test edge case.
      expect(find.text('Người dùng'), findsNothing);
    });

    testWidgets('mine: never shows senderName even when showSenderName=true',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              text: 'My msg',
              isMine: true,
              senderName: 'Me',
              showSenderName: true,
            ),
          ),
        ),
      );

      expect(find.text('Me'), findsNothing);
    });
  });

  group('ChatInputBar 2-state', () {
    testWidgets('blurred shows quick-send emoji, no send icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ChatInputBar(onSend: (_) {})),
        ),
      );

      expect(find.text('💙'), findsOneWidget);
      expect(find.text('🤣'), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsNothing);
    });

    testWidgets('typing hides quick-send and reveals send', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ChatInputBar(onSend: (_) {})),
        ),
      );

      await tester.enterText(find.byType(TextField), 'xin chào');
      await tester.pump();

      expect(find.text('💙'), findsNothing);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('quick-send emoji fires onSend immediately', (tester) async {
      final sent = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ChatInputBar(onSend: sent.add)),
        ),
      );

      await tester.tap(find.text('🥰'));
      await tester.pump();

      expect(sent, ['🥰']);
    });

    testWidgets('send button submits trimmed text and clears', (tester) async {
      final sent = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ChatInputBar(onSend: sent.add)),
        ),
      );

      await tester.enterText(find.byType(TextField), '  hello  ');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      expect(sent, ['hello']);
      expect(find.text('  hello  '), findsNothing);
    });

    testWidgets('tap emoji picker icon opens EmojiPicker bottom sheet (Bug #6)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ChatInputBar(onSend: (_) {})),
        ),
      );

      expect(find.byType(EmojiPicker), findsNothing);

      await tester.tap(find.byIcon(Icons.add_reaction_outlined));
      // Bottom sheet animation — settle để render hoàn tất.
      await tester.pumpAndSettle();

      expect(find.byType(EmojiPicker), findsOneWidget);
    });

    testWidgets('emoji picker icon is disabled while isSending=true',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInputBar(onSend: (_) {}, isSending: true),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add_reaction_outlined));
      await tester.pumpAndSettle();

      // KHÔNG hiện picker khi isSending — tránh duplicate send.
      expect(find.byType(EmojiPicker), findsNothing);
    });
  });
}
