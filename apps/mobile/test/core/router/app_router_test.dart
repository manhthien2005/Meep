import 'package:flutter_test/flutter_test.dart';
import 'package:meep/core/router/app_router.dart';

void main() {
  group('authRedirect', () {
    test('signed-in + /intro → redirect /home', () {
      expect(
        authRedirect(isLoading: false, isSignedIn: true, location: '/intro'),
        '/home',
      );
    });

    test('signed-in + /signup/email → redirect /home', () {
      expect(
        authRedirect(
          isLoading: false,
          isSignedIn: true,
          location: '/signup/email',
        ),
        '/home',
      );
    });

    test('signed-in + /login/email → redirect /home', () {
      expect(
        authRedirect(
          isLoading: false,
          isSignedIn: true,
          location: '/login/email',
        ),
        '/home',
      );
    });

    test('signed-in + /home → không redirect', () {
      expect(
        authRedirect(isLoading: false, isSignedIn: true, location: '/home'),
        isNull,
      );
    });

    test('signed-out + /home → redirect /intro', () {
      expect(
        authRedirect(isLoading: false, isSignedIn: false, location: '/home'),
        '/intro',
      );
    });

    test('signed-out + /intro → không redirect', () {
      expect(
        authRedirect(isLoading: false, isSignedIn: false, location: '/intro'),
        isNull,
      );
    });

    test('loading state → không redirect dù ở /home', () {
      expect(
        authRedirect(isLoading: true, isSignedIn: false, location: '/home'),
        isNull,
      );
    });

    test('loading state → không redirect dù ở /intro', () {
      expect(
        authRedirect(isLoading: true, isSignedIn: true, location: '/intro'),
        isNull,
      );
    });
  });
}
