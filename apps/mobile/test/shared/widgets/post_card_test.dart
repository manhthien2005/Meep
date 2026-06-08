import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meep/shared/models/post.dart';
import 'package:meep/shared/widgets/app_note_pill.dart';
import 'package:meep/shared/widgets/post_card.dart';

Post _post({String? caption}) => Post(
      postId: 'p1',
      authorId: 'uid1',
      authorName: 'Test User',
      imageUrl: 'https://example.com/photo.jpg',
      caption: caption,
      audienceType: AudienceType.all,
      createdAt: DateTime(2026, 5, 31),
    );

void main() {
  // Phone-sized surface so photoSize ≥ pill width (no overlay overflow).
  Widget wrap(Widget w) => MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(412, 917)),
          child: Scaffold(body: w),
        ),
      );

  group('PostCard caption overlay', () {
    testWidgets('hides note pill when caption is null', (tester) async {
      await tester.pumpWidget(wrap(PostCard(post: _post())));
      expect(find.byType(AppNotePill), findsNothing);
    });

    testWidgets('hides note pill when caption is empty', (tester) async {
      await tester.pumpWidget(wrap(PostCard(post: _post(caption: ''))));
      expect(find.byType(AppNotePill), findsNothing);
    });

    testWidgets('hides note pill when caption is whitespace only',
        (tester) async {
      await tester.pumpWidget(wrap(PostCard(post: _post(caption: '   '))));
      expect(find.byType(AppNotePill), findsNothing);
    });

    testWidgets('shows note pill when caption has text', (tester) async {
      await tester.pumpWidget(wrap(PostCard(post: _post(caption: 'Hi'))));
      expect(find.byType(AppNotePill), findsOneWidget);
    });
  });
}
