import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:meep/shared/models/post.dart';
import 'package:meep/features/feed/presentation/feed_section.dart';
import 'package:meep/features/reaction/application/reaction_controller.dart';
import 'package:meep/features/reaction/data/reaction_repository.dart';

class MockReactionRepository extends Mock implements ReactionRepository {}

Post _post({DateTime? createdAt}) => Post(
      postId: 'p1',
      authorId: 'uid1',
      authorName: 'Test User',
      imageUrl: 'https://example.com/photo.jpg',
      audienceType: AudienceType.all,
      createdAt: createdAt ?? DateTime(2026, 4, 4),
    );

void main() {
  setUpAll(() => registerFallbackValue(''));

  ProviderScope makeScope(Widget child) {
    final repo = MockReactionRepository();
    when(() => repo.watchReactions(any()))
        .thenAnswer((_) => const Stream.empty());
    return ProviderScope(
      overrides: [reactionRepositoryProvider.overrideWithValue(repo)],
      child: child,
    );
  }

  Future<void> pump(WidgetTester tester, Post post) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      makeScope(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: OwnPostCard(post: post)),
          ),
        ),
      ),
    );
  }

  group('OwnPostCard footer', () {
    testWidgets('renders author label with "d thg M" date', (tester) async {
      await pump(tester, _post());
      // Text.rich → matched as combined plain text.
      expect(find.textContaining('Bạn'), findsWidgets);
      expect(find.textContaining('4 thg 4'), findsWidgets);
    });

    testWidgets('renders activity pill with sparkles icon', (tester) async {
      await pump(tester, _post());
      expect(find.text('Chưa có hoạt động nào!'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_outlined), findsOneWidget);
    });

    testWidgets('footer column is center-aligned', (tester) async {
      await pump(tester, _post());
      // The footer Column is the nearest Column ancestor of the activity text;
      // PostCard's outer Column is start-aligned and must not be matched here.
      final column = tester.widget<Column>(
        find
            .ancestor(
              of: find.text('Chưa có hoạt động nào!'),
              matching: find.byType(Column),
            )
            .first,
      );
      expect(column.crossAxisAlignment, CrossAxisAlignment.center);
    });
  });
}
