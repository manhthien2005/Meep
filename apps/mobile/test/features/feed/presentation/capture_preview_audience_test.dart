import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/data/public_profile.dart';
import 'package:meep/features/feed/presentation/capture_preview_args.dart';
import 'package:meep/features/feed/presentation/capture_preview_screen.dart';
import 'package:meep/features/friend/application/friend_controller.dart';
import 'package:meep/features/friend/application/friend_state.dart';
import 'package:meep/features/space/application/space_controller.dart';

class _FakeFriendController extends FriendController {
  _FakeFriendController(this._state);

  final FriendState _state;

  @override
  FriendState build(String uid) => _state;
}

class _FakeSpaceController extends SpaceController {
  _FakeSpaceController(this._state);

  final SpaceState _state;

  @override
  SpaceState build(String uid) => _state;
}

PublicProfile _friend() => PublicProfile(
      uid: 'friend-1',
      displayName: 'Han',
      username: 'han',
      updatedAt: DateTime(2026, 6, 1),
    );

File _onePixelPng() {
  final dir = Directory.systemTemp.createTempSync('meep_preview_test_');
  final file = File('${dir.path}/photo.png');
  addTearDown(() => dir.deleteSync(recursive: true));
  file.writeAsBytesSync(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=',
    ),
  );
  return file;
}

void main() {
  testWidgets('audience row không render lựa chọn "Bạn"', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final image = _onePixelPng();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUidProvider.overrideWith((ref) => Stream.value('me')),
          friendControllerProvider('me').overrideWith(
            () => _FakeFriendController(
              FriendState(friends: [_friend()]),
            ),
          ),
          spaceControllerProvider('me').overrideWith(
            () => _FakeSpaceController(const SpaceState()),
          ),
        ],
        child: MaterialApp(
          home: CapturePreviewScreen(
            args: CapturePreviewArgs.single(imagePath: image.path),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tất cả'), findsOneWidget);
    expect(find.text('Han'), findsOneWidget);
    expect(find.text('Bạn'), findsNothing);
  });
}
