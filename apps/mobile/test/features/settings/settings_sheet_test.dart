import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/data/user_profile.dart';
import 'package:meep/features/settings/presentation/settings_sheet.dart';
import 'package:meep/features/space/application/space_controller.dart';
import 'package:meep/features/space/data/space.dart';
import 'package:meep/features/space/data/space_repository.dart';

class MockSpaceRepository extends Mock implements SpaceRepository {}

UserProfile _profile({
  String uid = 'user1',
  String username = 'ngantran',
  String displayName = 'Ngan Tran',
  int friendCount = 15,
  String? avatarUrl,
}) {
  return UserProfile(
    uid: uid,
    email: '$uid@test.com',
    displayName: displayName,
    username: username,
    friendCount: friendCount,
    avatarUrl: avatarUrl,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late MockSpaceRepository spaceRepo;

  setUp(() {
    spaceRepo = MockSpaceRepository();
    when(() => spaceRepo.watchMySpaces(any())).thenAnswer(
      (_) => Stream.value(<Space>[]),
    );
  });

  Widget harness({
    String? currentUid = 'user1',
    List<Space>? spacesStream,
    UserProfile? profile,
    bool useNullProfile = false,
  }) {
    if (spacesStream != null) {
      when(() => spaceRepo.watchMySpaces('user1')).thenAnswer(
        (_) => Stream.value(spacesStream),
      );
    }
    return ProviderScope(
      overrides: [
        spaceRepositoryProvider.overrideWithValue(spaceRepo),
        currentUidProvider.overrideWith(
          (ref) => Stream.value(currentUid),
        ),
        currentUserProfileProvider.overrideWith(
          (ref) => Stream<UserProfile?>.value(
            useNullProfile ? null : (profile ?? _profile()),
          ),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: SettingsSheet())),
    );
  }

  group('SettingsSheet', () {
    testWidgets('render — header username + các mục menu chính',
        (tester) async {
      await tester.pumpWidget(harness());
      await tester.pump();

      // Header đọc currentUserProfileProvider — default _profile()
      // có username 'ngantran'.
      expect(find.text('ngantran'), findsOneWidget);
      expect(find.text('Tài khoản đã chặn'), findsOneWidget);
      expect(find.text('Đăng xuất'), findsOneWidget);
      expect(find.text('Xoá tài khoản'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('friendCount hiển thị từ profile thật (7 → "7 người bạn")',
        (tester) async {
      await tester.pumpWidget(harness(profile: _profile(friendCount: 7)));
      await tester.pump();

      expect(find.text('7 người bạn'), findsOneWidget);
    });

    testWidgets(
        'profile null → fallback "0 người bạn", username rỗng, không crash',
        (tester) async {
      await tester.pumpWidget(harness(useNullProfile: true));
      await tester.pump();

      expect(find.text('0 người bạn'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tap "Đăng xuất" → hiện confirm dialog đăng xuất',
        (tester) async {
      await tester.pumpWidget(harness());
      await tester.pump();

      await tester.ensureVisible(find.text('Đăng xuất'));
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();

      expect(find.text('Bạn có chắc bạn muốn đăng xuất?'), findsOneWidget);
    });

    testWidgets('tap "Xoá tài khoản" → hiện confirm dialog xoá (nút đỏ "Xoá")',
        (tester) async {
      await tester.pumpWidget(harness());
      await tester.pump();

      await tester.ensureVisible(find.text('Xoá tài khoản'));
      await tester.tap(find.text('Xoá tài khoản'));
      await tester.pumpAndSettle();

      expect(
        find.text('Bạn có chắc muốn xoá tài khoản này không?'),
        findsOneWidget,
      );
      expect(find.text('Xoá'), findsOneWidget);
    });

    testWidgets('SpaceQuickRow render real Space data (icon + colorHex)',
        (tester) async {
      final space = Space(
        spaceId: 's1',
        name: 'Gia đình',
        iconEmoji: '👨‍👩‍👧‍👦',
        colorHex: '#BFD5FF',
        creatorId: 'user1',
        memberCount: 3,
        memberIds: ['user1', 'user2', 'user3'],
        createdAt: DateTime(2026, 6, 1),
      );

      await tester.pumpWidget(harness(spacesStream: [space]));
      // Pump 2 lần: lần 1 currentUidProvider emit value, lần 2
      // spaceControllerProvider stream emit spaces. Sau đó build chạy lại.
      await tester.pumpAndSettle();

      // Tên Space real (không phải mock "Hội đồng quản trị")
      expect(find.text('Gia đình'), findsOneWidget);
      // Icon emoji thực — không phải avatar placeholder grey
      expect(find.text('👨‍👩‍👧‍👦'), findsOneWidget);
    });

    testWidgets('non-creator tap card → snackbar info (KHÔNG mở edit sheet)',
        (tester) async {
      final space = Space(
        spaceId: 's1',
        name: 'Friends',
        iconEmoji: '👥',
        colorHex: '#00DEEE',
        creatorId: 'other-creator',
        memberCount: 2,
        memberIds: ['other-creator', 'user1'],
        createdAt: DateTime(2026, 6, 1),
      );

      await tester.pumpWidget(harness(spacesStream: [space]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Friends'));
      await tester.pump();

      expect(
        find.text('Chỉ creator có quyền chỉnh sửa Space'),
        findsOneWidget,
      );
    });
  });
}
