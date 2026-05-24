import 'package:flutter_test/flutter_test.dart';
import 'package:meep/core/router/app_router.dart';

void main() {
  group('authRedirect — 3-state guard', () {
    // ── loading ──────────────────────────────────────────────
    test('isLoading → null (any location)', () {
      expect(
        authRedirect(
          isLoading: true,
          uid: null,
          profileExists: null,
          location: '/home',
        ),
        isNull,
      );
      expect(
        authRedirect(
          isLoading: true,
          uid: 'u1',
          profileExists: true,
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
          location: '/home',
        ),
        isNull,
      );
      expect(
        authRedirect(
          isLoading: false,
          uid: 'u1',
          profileExists: null,
          location: '/intro',
        ),
        isNull,
      );
    });

    // ── uid != null, no profile (Google Sign-In incomplete) ──
    test('uid + no profile + /signup/name → null (stay)', () {
      expect(
        authRedirect(
          isLoading: false,
          uid: 'u1',
          profileExists: false,
          location: '/signup/name',
        ),
        isNull,
      );
    });

    test('uid + no profile + /signup/username → null (stay)', () {
      expect(
        authRedirect(
          isLoading: false,
          uid: 'u1',
          profileExists: false,
          location: '/signup/username',
        ),
        isNull,
      );
    });

    test('uid + no profile + /home → /signup/name', () {
      expect(
        authRedirect(
          isLoading: false,
          uid: 'u1',
          profileExists: false,
          location: '/home',
        ),
        '/signup/name',
      );
    });

    test('uid + no profile + /intro → /signup/name', () {
      expect(
        authRedirect(
          isLoading: false,
          uid: 'u1',
          profileExists: false,
          location: '/intro',
        ),
        '/signup/name',
      );
    });

    // ── uid != null, profile exists ──────────────────────────
    test('uid + profile + /home → null (stay)', () {
      expect(
        authRedirect(
          isLoading: false,
          uid: 'u1',
          profileExists: true,
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
          location: '/dev/widgets',
        ),
        '/home',
      );
    });
  });
}
