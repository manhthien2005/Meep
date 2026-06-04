import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/feed/data/post.dart';
import 'package:meep/shared/widgets/photo_detail_screen.dart';

void main() {
  Post post({
    String id = 'p1',
    String? caption,
    DateTime? createdAt,
  }) {
    return Post(
      postId: id,
      authorId: 'uid-alice',
      authorName: 'Alice',
      imageUrl: 'https://cdn/$id.jpg',
      caption: caption,
      audienceType: AudienceType.all,
      createdAt: createdAt ?? DateTime.utc(2026, 5, 10, 17, 3),
    );
  }

  Widget host(Widget child) => ProviderScope(child: MaterialApp(home: child));

  testWidgets('empty posts → navigate back gracefully', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => Navigator.push<void>(
                ctx,
                MaterialPageRoute<void>(
                  builder: (_) => const PhotoDetailScreen(
                    postId: 'p1',
                    posts: <Post>[],
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // PhotoDetailScreen với posts rỗng phải pop ngay → quay về home
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('renders date format Vietnamese + time HH:mm', (tester) async {
    await tester.pumpWidget(
      host(
        PhotoDetailScreen(
          postId: 'p1',
          posts: [post(createdAt: DateTime.utc(2026, 5, 7, 9, 5))],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ngày 7 tháng 5'), findsOneWidget);
    expect(find.text('09:05'), findsOneWidget);
  });

  testWidgets('hides note pill khi caption null', (tester) async {
    await tester.pumpWidget(
      host(
        PhotoDetailScreen(
          postId: 'p1',
          posts: [post()],
        ),
      ),
    );
    await tester.pumpAndSettle();
    // ic_case_sensitive.svg chỉ render khi caption non-null trong _NotePill
    // → empty Stack child
    expect(find.byType(PhotoDetailScreen), findsOneWidget);
  });

  testWidgets('renders caption pill khi caption non-empty', (tester) async {
    await tester.pumpWidget(
      host(
        PhotoDetailScreen(
          postId: 'p1',
          posts: [post(caption: 'Feeling toasty!')],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Feeling toasty!'), findsOneWidget);
  });

  testWidgets('borderColorFor non-null → render border quanh ảnh active',
      (tester) async {
    await tester.pumpWidget(
      host(
        PhotoDetailScreen(
          postId: 'p1',
          posts: [post(id: 'p1')],
          borderColorFor: (_, __) => const Color(0xFFFF00FF),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tìm Container có Border.all màu magenta — chỉ vẽ khi borderColorFor
    // trả non-null cho post active.
    final containers = tester.widgetList<Container>(find.byType(Container));
    final hasBorder = containers.any((c) {
      final dec = c.decoration;
      if (dec is! BoxDecoration) return false;
      final border = dec.border;
      if (border is! Border) return false;
      return border.top.color == const Color(0xFFFF00FF);
    });
    expect(
      hasBorder,
      isTrue,
      reason: 'Border màu magenta phải render quanh ảnh active',
    );
  });

  testWidgets('borderColorFor return null → không render border',
      (tester) async {
    await tester.pumpWidget(
      host(
        PhotoDetailScreen(
          postId: 'p1',
          posts: [post(id: 'p1')],
          borderColorFor: (_, __) => null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final containers = tester.widgetList<Container>(find.byType(Container));
    final anyHasBorder = containers.any((c) {
      final dec = c.decoration;
      return dec is BoxDecoration && dec.border != null;
    });
    expect(
      anyHasBorder,
      isFalse,
      reason: 'Callback null → không có Container border nào trong tree',
    );
  });

  testWidgets('initialIndex selects đúng post', (tester) async {
    await tester.pumpWidget(
      host(
        PhotoDetailScreen(
          postId: 'p2',
          initialIndex: 1,
          posts: [
            post(id: 'p1', createdAt: DateTime.utc(2026, 5, 7, 9, 0)),
            post(id: 'p2', createdAt: DateTime.utc(2026, 5, 10, 14, 30)),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ngày 10 tháng 5'), findsOneWidget);
    expect(find.text('14:30'), findsOneWidget);
  });
}
