import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/shared/models/post.dart';
import 'package:meep/shared/widgets/share_photo_sheet.dart';

void main() {
  Post makePost() => Post(
        postId: 'p1',
        authorId: 'uid-alice',
        authorName: 'Alice',
        imageUrl: 'https://cdn/p1.jpg',
        audienceType: AudienceType.all,
        createdAt: DateTime.utc(2026, 5, 22, 17, 3),
      );

  Widget host(Widget child) =>
      ProviderScope(child: MaterialApp(home: Scaffold(body: child)));

  testWidgets('isAuthor=true → Xoá button visible', (tester) async {
    await tester.pumpWidget(
      host(SharePhotoSheet(post: makePost(), isAuthor: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lưu'), findsOneWidget);
    expect(find.text('Xoá'), findsOneWidget);
  });

  testWidgets('isAuthor=false → Xoá button ẩn, chỉ Lưu', (tester) async {
    await tester.pumpWidget(
      host(SharePhotoSheet(post: makePost(), isAuthor: false)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lưu'), findsOneWidget);
    expect(find.text('Xoá'), findsNothing);
  });

  testWidgets('share targets render với label đúng', (tester) async {
    await tester.pumpWidget(
      host(SharePhotoSheet(post: makePost(), isAuthor: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chia sẻ đến...'), findsOneWidget);
    expect(find.text('Chia sẻ'), findsOneWidget);
    expect(find.text('Messenger'), findsOneWidget);
    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('Tin nhắn'), findsOneWidget);
  });

  testWidgets('Tin nhắn disabled (opacity 0.5, không respond tap)',
      (tester) async {
    await tester.pumpWidget(
      host(SharePhotoSheet(post: makePost(), isAuthor: true)),
    );
    await tester.pumpAndSettle();

    // "Tin nhắn" target có Opacity wrapper với opacity = 0.5 (disabled state).
    final tinNhanLabel = find.text('Tin nhắn');
    expect(tinNhanLabel, findsOneWidget);
    final opacity = tester.widget<Opacity>(
      find.ancestor(of: tinNhanLabel, matching: find.byType(Opacity)).first,
    );
    expect(opacity.opacity, 0.5);
  });
}
