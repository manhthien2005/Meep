import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/space/application/space_controller.dart';
import 'package:meep/features/space/data/space.dart';
import 'package:meep/features/space/data/space_member.dart';
import 'package:meep/features/space/data/space_repository.dart';
import 'package:meep/features/space/presentation/space_edit_sheet.dart';

class MockSpaceRepository extends Mock implements SpaceRepository {}

Space _spaceFixture({
  required String creatorId,
  String name = 'Family',
  String iconEmoji = '👨‍👩‍👧‍👦',
  String colorHex = '#BFD5FF',
}) {
  return Space(
    spaceId: 's1',
    name: name,
    iconEmoji: iconEmoji,
    colorHex: colorHex,
    creatorId: creatorId,
    memberCount: 1,
    memberIds: [creatorId],
    createdAt: DateTime(2026, 6, 1),
  );
}

Widget _wrap({
  required SpaceRepository repo,
  required String? currentUid,
}) {
  return ProviderScope(
    overrides: [
      spaceRepositoryProvider.overrideWithValue(repo),
      currentUidProvider.overrideWith((ref) => Stream.value(currentUid)),
    ],
    child: const MaterialApp(
      home: Scaffold(body: SpaceEditSheet(spaceId: 's1')),
    ),
  );
}

void setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  late MockSpaceRepository repo;

  setUp(() {
    repo = MockSpaceRepository();
    // Default — empty watchMembers (controller subscribes by side effect via family)
    when(() => repo.watchMembers(any())).thenAnswer(
      (_) => Stream.value(<SpaceMember>[]),
    );
    when(() => repo.watchMySpaces(any())).thenAnswer(
      (_) => Stream.value(<Space>[]),
    );
  });

  testWidgets('renders form with initial values when creator', (tester) async {
    setTallSurface(tester);
    when(() => repo.watchSpace('s1')).thenAnswer(
      (_) => Stream.value(_spaceFixture(creatorId: 'user1')),
    );

    await tester.pumpWidget(_wrap(repo: repo, currentUid: 'user1'));
    await tester.pumpAndSettle();

    // Title duy nhất
    expect(find.text('Chỉnh sửa Space'), findsOneWidget);
    // Section header Theme duy nhất
    expect(find.text('Space theme'), findsOneWidget);
    // Save button
    expect(find.text('Lưu thay đổi'), findsOneWidget);
    // Initial name pre-filled — TextField không rỗng
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text, 'Family');
  });

  testWidgets('shows error view when user is not creator', (tester) async {
    when(() => repo.watchSpace('s1')).thenAnswer(
      (_) => Stream.value(_spaceFixture(creatorId: 'creator-other')),
    );

    await tester.pumpWidget(_wrap(repo: repo, currentUid: 'user1'));
    await tester.pumpAndSettle();

    expect(find.text('Chỉ creator có quyền chỉnh sửa Space'), findsOneWidget);
    expect(find.text('Đóng'), findsOneWidget);
    // Save button KHÔNG hiển thị
    expect(find.text('Lưu thay đổi'), findsNothing);
  });

  testWidgets('shows error view when space not found (null stream)',
      (tester) async {
    when(() => repo.watchSpace('s1')).thenAnswer(
      (_) => Stream.value(null),
    );

    await tester.pumpWidget(_wrap(repo: repo, currentUid: 'user1'));
    await tester.pumpAndSettle();

    expect(find.text('Space không tồn tại hoặc đã bị xoá'), findsOneWidget);
  });

  testWidgets('save button disabled when no changes (initial state)',
      (tester) async {
    setTallSurface(tester);
    when(() => repo.watchSpace('s1')).thenAnswer(
      (_) => Stream.value(_spaceFixture(creatorId: 'user1', name: 'Family')),
    );

    await tester.pumpWidget(_wrap(repo: repo, currentUid: 'user1'));
    await tester.pumpAndSettle();

    final saveButton = find.text('Lưu thay đổi');
    expect(saveButton, findsOneWidget);
    // Tap → KHÔNG call repo.updateSpace vì button disabled (canSave false)
    await tester.tap(saveButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    verifyNever(
      () => repo.updateSpace(
        spaceId: any(named: 'spaceId'),
        name: any(named: 'name'),
        iconEmoji: any(named: 'iconEmoji'),
        colorHex: any(named: 'colorHex'),
      ),
    );
  });

  testWidgets('save button enabled when name edited', (tester) async {
    setTallSurface(tester);
    when(() => repo.watchSpace('s1')).thenAnswer(
      (_) => Stream.value(_spaceFixture(creatorId: 'user1', name: 'Family')),
    );
    when(
      () => repo.updateSpace(
        spaceId: any(named: 'spaceId'),
        name: any(named: 'name'),
        iconEmoji: any(named: 'iconEmoji'),
        colorHex: any(named: 'colorHex'),
      ),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(_wrap(repo: repo, currentUid: 'user1'));
    await tester.pumpAndSettle();

    // Edit name
    await tester.enterText(find.byType(TextField), 'Family Renamed');
    await tester.pumpAndSettle();

    // Tap save
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();

    verify(
      () => repo.updateSpace(
        spaceId: 's1',
        name: 'Family Renamed',
        iconEmoji: null, // không đổi
        colorHex: null, // không đổi
      ),
    ).called(1);
  });

  testWidgets('tap preset updates icon + color, save sends both fields',
      (tester) async {
    setTallSurface(tester);
    when(() => repo.watchSpace('s1')).thenAnswer(
      (_) => Stream.value(
        _spaceFixture(
          creatorId: 'user1',
          iconEmoji: '👨‍👩‍👧‍👦',
          colorHex: '#BFD5FF',
        ),
      ),
    );
    when(
      () => repo.updateSpace(
        spaceId: any(named: 'spaceId'),
        name: any(named: 'name'),
        iconEmoji: any(named: 'iconEmoji'),
        colorHex: any(named: 'colorHex'),
      ),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(_wrap(repo: repo, currentUid: 'user1'));
    await tester.pumpAndSettle();

    // Tap preset ❤️ #FFCFBF (preset #2)
    await tester.tap(find.text('❤️'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();

    verify(
      () => repo.updateSpace(
        spaceId: 's1',
        name: null, // không đổi
        iconEmoji: '❤️',
        colorHex: '#FFCFBF',
      ),
    ).called(1);
  });
}
