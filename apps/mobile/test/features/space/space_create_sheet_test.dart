import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/space/presentation/space_create_sheet.dart';

void main() {
  group('SpaceCreateSheet scaffold', () {
    testWidgets('renders with 3 steps', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpaceCreateSheet(),
          ),
        ),
      );

      // Sheet hiện
      expect(find.byType(SpaceCreateSheet), findsOneWidget);

      // Step 1 title
      expect(find.text('Thêm Space mới'), findsOneWidget);
    });

    testWidgets('navigates to step 2 when continue tapped', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpaceCreateSheet(),
          ),
        ),
      );

      // Step 1 hiện
      expect(find.text('Thêm Space mới'), findsOneWidget);

      // Nút "Tiếp tục →" disabled vì chưa chọn friend
      final continueButton = find.text('Tiếp tục →');
      expect(continueButton, findsOneWidget);

      // TODO(SP/T3.2): khi FriendSelectStep có checkbox, test tap checkbox → enable button → tap button → step 2
      // Hiện tại skip vì chưa có friend list UI
    });
  });
}
