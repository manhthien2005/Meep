import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/application/email_verification_gate.dart';
import 'package:meep/features/auth/data/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;

  setUp(() {
    repo = MockAuthRepository();
    // currentUidProvider watch repo.watchUid(); keep it simple/stable.
    when(() => repo.watchUid()).thenAnswer((_) => const Stream.empty());
    when(() => repo.reloadUser()).thenAnswer((_) async {});
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('EmailVerificationGate', () {
    test('signed out → false', () {
      when(() => repo.currentUid).thenReturn(null);
      when(() => repo.currentProviderId).thenReturn(null);
      when(() => repo.isEmailVerified).thenReturn(false);

      final c = makeContainer();
      expect(c.read(emailVerificationGateProvider), isFalse);
    });

    test('password user + chưa verify → true (gate)', () {
      when(() => repo.currentUid).thenReturn('u1');
      when(() => repo.currentProviderId).thenReturn('password');
      when(() => repo.isEmailVerified).thenReturn(false);

      final c = makeContainer();
      expect(c.read(emailVerificationGateProvider), isTrue);
    });

    test('password user + đã verify → false', () {
      when(() => repo.currentUid).thenReturn('u1');
      when(() => repo.currentProviderId).thenReturn('password');
      when(() => repo.isEmailVerified).thenReturn(true);

      final c = makeContainer();
      expect(c.read(emailVerificationGateProvider), isFalse);
    });

    test('Google user chưa verify → false (provider exempt)', () {
      // Contrived: Google email luôn verified, nhưng vẫn assert short-circuit.
      when(() => repo.currentUid).thenReturn('u1');
      when(() => repo.currentProviderId).thenReturn('google.com');
      when(() => repo.isEmailVerified).thenReturn(false);

      final c = makeContainer();
      expect(c.read(emailVerificationGateProvider), isFalse);
    });

    test('refresh() reload rồi flip true→false khi đã verify', () async {
      when(() => repo.currentUid).thenReturn('u1');
      when(() => repo.currentProviderId).thenReturn('password');
      // Trước reload: chưa verify.
      var verified = false;
      when(() => repo.isEmailVerified).thenAnswer((_) => verified);
      // reload mô phỏng user click link → verified.
      when(() => repo.reloadUser()).thenAnswer((_) async {
        verified = true;
      });

      final c = makeContainer();
      expect(c.read(emailVerificationGateProvider), isTrue);

      await c.read(emailVerificationGateProvider.notifier).refresh();

      expect(c.read(emailVerificationGateProvider), isFalse);
      verify(() => repo.reloadUser()).called(1);
    });
  });
}
