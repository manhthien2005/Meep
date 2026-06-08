import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:meep/features/reaction/application/reaction_controller.dart';
import 'package:meep/features/reaction/data/reaction_repository.dart';
import 'package:meep/features/reaction/presentation/emoji_picker_sheet.dart';
import 'package:meep/features/reaction/presentation/reaction_list_sheet.dart';

class MockReactionRepository extends Mock implements ReactionRepository {}

Widget _makeScope(Widget child) {
  final repo = MockReactionRepository();
  when(() => repo.watchReactions(any()))
      .thenAnswer((_) => const Stream.empty());
  return ProviderScope(
    overrides: [reactionRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  setUpAll(() => registerFallbackValue(''));

  group('EmojiPickerSheet', () {
    testWidgets('renders emoji grid with presets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmojiPickerSheet(onEmojiSelected: (_) {}),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('🤣'), findsOneWidget);
    });

    testWidgets('tap emoji fires callback', (tester) async {
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmojiPickerSheet(onEmojiSelected: (e) => selected = e),
          ),
        ),
      );

      await tester.tap(find.text('🤣'));
      expect(selected, '🤣');
    });
  });

  group('ReactionListSheet', () {
    testWidgets('renders title with reaction count', (tester) async {
      await tester
          .pumpWidget(_makeScope(const ReactionListSheet(postId: 'p1')));
      expect(find.text('Phản ứng (0)'), findsOneWidget);
    });
  });
}
