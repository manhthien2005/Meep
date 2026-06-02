import 'package:meep/features/auth/data/user_profile.dart';
import 'package:meep/features/chat/data/conversation.dart';
import 'package:meep/features/chat/data/message.dart';
import 'package:meep/features/feed/data/post.dart';
import 'package:meep/features/space/data/space.dart';
import 'package:meep/features/space/data/space_member.dart';

/// Seed data for [FakeConversationRepository] — FE-first round (#142).
///
/// Hardcoded demo content so the Chat UI can be built and reviewed before the
/// Firebase backend (Friend #88 / Settings #115 / Space) is wired. Replaced by
/// real Firestore reads via `FirebaseConversationRepository` later.
///
/// `DateTime.now()` is intentional here — seed timestamps are relative to app
/// launch so the inbox ordering and "x phút trước" labels look natural in demo.
abstract final class ChatSeed {
  /// Current logged-in user (mock). Matches `'current-uid-mock'` used by
  /// `friend_select_step` so cross-screen demo data lines up.
  static const currentUid = 'current-uid-mock';

  static final _now = DateTime.now();

  // --- Users -------------------------------------------------------------

  static final me = UserProfile(
    uid: currentUid,
    email: 'me@meep.app',
    displayName: 'Bạn',
    username: 'me',
    createdAt: _now,
    updatedAt: _now,
  );

  static final talaki = UserProfile(
    uid: 'uid-talaki',
    email: 'talaki@meep.app',
    displayName: 'Talaki',
    username: 'talaki',
    avatarUrl: null, // Null for tests - TestWidgetsFlutterBinding blocks HTTP
    createdAt: _now,
    updatedAt: _now,
  );

  static final minh = UserProfile(
    uid: 'uid-minh',
    email: 'minh@meep.app',
    displayName: 'Minh Anh',
    username: 'minhanh',
    avatarUrl: null, // Null for tests - TestWidgetsFlutterBinding blocks HTTP
    createdAt: _now,
    updatedAt: _now,
  );

  static final linh = UserProfile(
    uid: 'uid-linh',
    email: 'linh@meep.app',
    displayName: 'Linh',
    username: 'linh',
    avatarUrl: null, // Null for tests - TestWidgetsFlutterBinding blocks HTTP
    createdAt: _now,
    updatedAt: _now,
  );

  /// Lookup by uid for tiles / bubbles / member lists.
  static Map<String, UserProfile> get usersByUid => {
        for (final u in [me, talaki, minh, linh]) u.uid: u,
      };

  // --- Conversation IDs --------------------------------------------------

  static const convTalaki = 'conv-talaki'; // 1-1 with messages + unread
  static const convMinh = 'conv-minh'; // 1-1 empty (empty-thread state)
  static const convGroup = 'conv-group'; // space group chat

  static const groupSpaceId = 'space-fun';

  // --- Messages ----------------------------------------------------------

  /// Initial messages per conversation. `convMinh` intentionally absent →
  /// empty thread (`769:3019`).
  static Map<String, List<Message>> seedMessages() => {
        convTalaki: [
          Message(
            messageId: 'm1',
            senderId: talaki.uid,
            text: 'Ảnh đẹp quá, chụp ở đâu vậy?',
            createdAt: _now.subtract(const Duration(minutes: 30)),
          ),
          Message(
            messageId: 'm2',
            senderId: me.uid,
            text: 'Đà Lạt đó, cuối tuần đi không?',
            createdAt: _now.subtract(const Duration(minutes: 25)),
          ),
          Message(
            messageId: 'm3',
            senderId: talaki.uid,
            text: 'Đi chứ!',
            createdAt: _now.subtract(const Duration(minutes: 2)),
          ),
        ],
        convGroup: [
          Message(
            messageId: 'g1',
            senderId: minh.uid,
            text: 'Mọi người rảnh tối nay không?',
            createdAt: _now.subtract(const Duration(hours: 1)),
          ),
          Message(
            messageId: 'g2',
            senderId: linh.uid,
            text: 'Có nha',
            createdAt: _now.subtract(const Duration(minutes: 50)),
          ),
        ],
      };

  // --- Conversations -----------------------------------------------------

  static List<Conversation> seedConversations() => [
        Conversation(
          conversationId: convTalaki,
          type: ConversationType.direct,
          participantIds: [me.uid, talaki.uid],
          quotedPostId: 'post-dalat',
          lastMessage: 'Đi chứ!',
          lastMessageAt: _now.subtract(const Duration(minutes: 2)),
          lastSenderId: talaki.uid,
          createdAt: _now.subtract(const Duration(days: 1)),
        ),
        Conversation(
          conversationId: convMinh,
          type: ConversationType.direct,
          participantIds: [me.uid, minh.uid],
          lastMessageAt: _now.subtract(const Duration(minutes: 10)),
          createdAt: _now.subtract(const Duration(minutes: 10)),
        ),
        Conversation(
          conversationId: convGroup,
          type: ConversationType.space,
          participantIds: [me.uid, minh.uid, linh.uid],
          spaceId: groupSpaceId,
          lastMessage: 'Có nha',
          lastMessageAt: _now.subtract(const Duration(minutes: 50)),
          lastSenderId: linh.uid,
          createdAt: _now.subtract(const Duration(days: 3)),
        ),
      ];

  /// Unread counts per conversation — NOT in [Conversation] model yet
  /// (contract-pending, see plan). FE renders badge from this map.
  static Map<String, int> seedUnreadCounts() => {convTalaki: 1};

  // --- Quoted post (1-1 reply origin) ------------------------------------

  /// The post that started [convTalaki] — shown as the quoted photo at the top
  /// of the thread (`564:6942` + caption `564:6961`).
  static Post quotedPost() => Post(
        postId: 'post-dalat',
        authorId: me.uid,
        authorName: me.displayName,
        imageUrl: 'https://picsum.photos/seed/dalat/600',
        caption: 'Feeling toasty!',
        audienceType: AudienceType.all,
        createdAt: _now.subtract(const Duration(days: 1)),
      );

  // --- Space (group chat) ------------------------------------------------

  static Space seedSpace() => Space(
        spaceId: groupSpaceId,
        name: 'Hội bạn thân',
        iconEmoji: '🎉',
        colorHex: '#00DEEE',
        creatorId: me.uid,
        memberCount: 3,
        memberIds: [me.uid, minh.uid, linh.uid],
        createdAt: _now.subtract(const Duration(days: 3)),
      );

  static List<SpaceMember> seedMembers() => [
        SpaceMember(role: SpaceRole.creator, uid: me.uid, joinedAt: _now),
        SpaceMember(role: SpaceRole.member, uid: minh.uid, joinedAt: _now),
        SpaceMember(role: SpaceRole.member, uid: linh.uid, joinedAt: _now),
      ];
}
