import 'package:flutter_test/flutter_test.dart';
import 'package:meep/core/router/app_router.dart';

void main() {
  group('authRedirect — 5-state guard', () {
    // ── loading ──────────────────────────────────────────────
    test('isLoading → null (any location)', () {
      expect(
        authRedirect(
          isLoading: true,
          uid: null,
          profileExists: null,
          needsProfile: false,
          location: '/home',
        ),
        isNull,
      );
      expect(
        authRedirect(
          isLoading: true,
          uid: 'u1',
          profileExists: true,
          needsProfile: false,
          location: '/intro',
        ),
        isNull,
      );
    });

    // ── uid = null ───────────────────────────────────────────
    test('uid null + /intro → null (stay)', () {
      expect(
        authRedirect(
          isLoading: false,
          uid: null,
          profileExists: null,
          needsProfile: false,
          location: '/intro',
        ),
        isNull,
      );
    });

    test('uid null + /login/email → null (stay)', () {
      expect(
        authRedirect(
          isLoading: false,
          uid: null,
          profileExists: null,
          needsProfile: false,
          location: '/login/email',
        ),
        isNull,
      );
    });

    test('uid null + /signup/email → null (stay)', () {
      expect(
        authRedirect(
          isLoading: false,
          uid: null,
          profileExists: null,
          needsProfile: false,
          location: '/signup/email',
        ),
        isNull,
      );
    });

    test('uid null + /home → /intro', () {
      expect(
        authRedirect(
          isLoading: false,
          uid: null,
          profileExists: null,
          needsProfile: false,
          location: '/home',
        ),
        '/intro',
      );
    });

    test('uid null + /profile → /intro', () {
      expect(
        authRedirect(
          isLoading: false,
          uid: null,
          profileExists: null,
          needsProfile: false,
          location: '/profile',
        ),
        '/intro',
      );
    });

    // ── uid != null, profileExists unknown ───────────────────
    test('uid exists + profileExists null → null (wait)', () {
      expect(
        authRedirect(
          isLoading: false,
          uid: 'u1',
          profileExists: null,
          needsProfile: false,
          location: '/home',
        ),
        isNull,
      );
      expect(
        authRedirect(
          isLoading: false,
          uid: 'u1',
          profileExists: null,
          needsProfile: false,
          location: '/intro',
        ),
        isNull,
      );
    });

    // ── uid != null, no profile, needsProfile=true (Google signup active) ──
    test('uid + no profile + needsProfile + /signup/name → null (stay)', () {
      expect(
        authRedirect(
          isLoading: false,
          uid: 'u1',
          profileExists: false,
          needsProfile: true,
          location: '/signup/name',
        ),
        isNull,
      );
    });

    test('uid + no profile + needsProfile + /signup/username → null (stay)',
        () {
      expect(
        authRedirect(
          isLoading: false,
          uid: 'u1',
          profileExists: false,
          needsProfile: true,
          location: '/signup/username',
        ),
        isNull,
      );
    });

    test('uid + no profile + needsProfile + /home → /signup/name', () {
      expect(
        authRedirect(
          isLoading: false,
          uid: 'u1',
          profileExists: false,
          needsProfile: true,
          location: '/home',
        ),
        '/signup/name',
      );
    });

    test('uid + no profile + needsProfile + /intro → /signup/name', () {
      expect(
        authRedirect(
          isLoading: false,
          uid: 'u1',
          profileExists: false,
          needsProfile: true,
          location: '/signup/email',
        ),
        '/signup/name',
      );
    });

    // ── uid != null, no profile, needsProfile=false (orphaned auth) ──
    test('uid + no profile + !needsProfile + /intro → /intro (orphaned)', () {
      expect(
        authRedirect(
          isLoading: false,
          uid: 'u1',
          profileExists: false,
          needsProfile: false,
          location: '/intro',
        ),
        '/intro',
      );
    });

    test('uid + no profile + !needsProfile + /home → /intro (orphaned)', () {
      expect(
        authRedirect(
          isLoading: false,
          uid: 'u1',
          profileExists: false,
          needsProfile: false,
          location: '/home',
        ),
        '/intro',
      );
    });

    test(
        'uid + no profile + !needsProfile + /signup/email → null (email signup active)',
        () {
      expect(
        authRedirect(
          isLoading: false,
          uid: 'u1',
          profileExists: false,
          needsProfile: false,
          location: '/signup/email',
        ),
        isNull,
      );
    });

    // ── uid != null, profile exists ──────────────────────────
    test('uid + profile + /home → null (stay)', () {
      expect(
        authRedirect(
          isLoading: false,
          uid: 'u1',
          profileExists: true,
          needsProfile: false,
          location: '/home',
        ),
        isNull,
      );
    });

    test('uid + profile + /profile → null (stay)', () {
      expect(
        authRedirect(
          isLoading: false,
          uid: 'u1',
          profileExists: true,
          needsProfile: false,
          location: '/profile',
        ),
        isNull,
      );
    });

    test('uid + profile + /intro → /home', () {
      expect(
        authRedirect(
          isLoading: false,
          uid: 'u1',
          profileExists: true,
          needsProfile: false,
          location: '/intro',
        ),
        '/home',
      );
    });

    test('uid + profile + /signup/email → /home', () {
      expect(
        authRedirect(
          isLoading: false,
          uid: 'u1',
          profileExists: true,
          needsProfile: false,
          location: '/signup/email',
        ),
        '/home',
      );
    });

    test('uid + profile + /login/email → /home', () {
      expect(
        authRedirect(
          isLoading: false,
          uid: 'u1',
          profileExists: true,
          needsProfile: false,
          location: '/login/email',
        ),
        '/home',
      );
    });

    test('uid + profile + /dev/widgets → /home', () {
      expect(
        authRedirect(
          isLoading: false,
          uid: 'u1',
          profileExists: true,
          needsProfile: false,
          location: '/dev/widgets',
        ),
        '/home',
      );
    });

    // ── DEV(C/#142): chat routes bypass auth both ways ───────
    test('uid null + /inbox → null (stay, dev bypass)', () {
      expect(
        authRedirect(
          isLoading: false,
          uid: null,
          profileExists: null,
          needsProfile: false,
          location: '/inbox',
        ),
        isNull,
      );
    });

    test('uid + profile + /chat/:id → null (stay, not /home)', () {
      expect(
        authRedirect(
          isLoading: false,
          uid: 'u1',
          profileExists: true,
          needsProfile: false,
          location: '/chat/conv-1',
        ),
        isNull,
      );
    });

    test('uid null + /group-chat/:id → null (stay, dev bypass)', () {
      expect(
        authRedirect(
          isLoading: false,
          uid: null,
          profileExists: null,
          needsProfile: false,
          location: '/group-chat/conv-1',
        ),
        isNull,
      );
    });
  });
}
