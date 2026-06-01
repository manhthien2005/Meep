// Mock data for Settings UI development.
// TODO(T3/NganTNK): Replace with real data from SettingsController after backend ready.

class SettingsMockData {
  static const username = 'ngantran';
  static const displayName = 'Ngan Tran';
  static const friendCount = 15;
  static const avatarUrl = null; // null = show placeholder icon

  static const mockSpaces = <String>['Gia đình', 'Hội đồng quản trị'];

  static const mockBlockedUsers = <BlockedUserView>[
    BlockedUserView(uid: 'mock-uid-1', username: 'Lauren'),
  ];
}

/// View model cho BlockedAccountsPage. T3 sẽ join `Block` (uid) với
/// `/users/{uid}` (username, avatar) thành list `BlockedUserView` qua
/// SettingsController.watchBlockedUsers().
class BlockedUserView {
  const BlockedUserView({
    required this.uid,
    required this.username,
    this.avatarUrl,
  });

  final String uid;
  final String username;
  final String? avatarUrl;
}
