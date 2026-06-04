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

  group('routeForNotification — T4 deep link mapping', () {
    test('friend_request → /home?openFriendSheet=1', () {
      expect(
        routeForNotification(const {
          'type': 'friend_request',
          'requestId': 'req-1',
        }),
        '/home?openFriendSheet=1',
      );
    });

    test('friend_accepted → /home?openFriendSheet=1', () {
      expect(
        routeForNotification(const {
          'type': 'friend_accepted',
          'requestId': 'req-1',
        }),
        '/home?openFriendSheet=1',
      );
    });

    test('reaction with postId → /home?highlight=<postId>', () {
      expect(
        routeForNotification(const {
          'type': 'reaction',
          'postId': 'post-abc',
        }),
        '/home?highlight=post-abc',
      );
    });

    test('reaction with missing postId → /home (no broken highlight)', () {
      // Defensive: a malformed payload should still land somewhere usable
      // rather than throw or push an empty highlight query.
      expect(routeForNotification(const {'type': 'reaction'}), '/home');
      expect(
        routeForNotification(const {'type': 'reaction', 'postId': ''}),
        '/home',
      );
    });

    test('reaction encodes a postId that contains special characters', () {
      // Firestore doc IDs are safe in URLs by default, but `Uri.encode`
      // guarantees nothing slips through even if a future id contains
      // a reserved char.
      expect(
        routeForNotification(const {
          'type': 'reaction',
          'postId': 'a/b?c',
        }),
        '/home?highlight=a%2Fb%3Fc',
      );
    });

    test('new_post → /home (no extra query)', () {
      expect(
        routeForNotification(const {'type': 'new_post'}),
        '/home',
      );
    });

    test('chat_message with conversationId → /chat/<conversationId>', () {
      expect(
        routeForNotification(const {
          'type': 'chat_message',
          'conversationId': 'conv-abc',
          'senderId': 'uid-sender',
          'messageId': 'msg-1',
        }),
        '/chat/conv-abc',
      );
    });

    test('chat_message with missing conversationId → /home', () {
      // Defensive — payload từ onMessageCreated luôn set conversationId; rỗng
      // hoặc thiếu nghĩa là malformed, đừng đẩy user vào chat screen lỗi.
      expect(routeForNotification(const {'type': 'chat_message'}), '/home');
      expect(
        routeForNotification(
          const {'type': 'chat_message', 'conversationId': ''},
        ),
        '/home',
      );
    });

    test('chat_message percent-encodes conversationId', () {
      expect(
        routeForNotification(const {
          'type': 'chat_message',
          'conversationId': 'a/b c',
        }),
        '/chat/a%2Fb%20c',
      );
    });

    test('unknown type → /home (fallback, no crash)', () {
      expect(
        routeForNotification(const {'type': 'made_up_type'}),
        '/home',
      );
    });

    test('missing type → /home (fallback, no crash)', () {
      expect(routeForNotification(const {}), '/home');
    });
  });
}
