// Mock data for Settings UI development.
// TODO(T3/NganTNK): Replace with real data from SettingsController after backend ready.

class SettingsMockData {
  static const username = 'ngantran';
  static const displayName = 'Ngan Tran';
  static const friendCount = 15;
  static const avatarUrl = null; // null = show placeholder icon

  static const mockSpaces = [
    {'name': 'Gia đình', 'memberCount': 5},
    {'name': 'Hội đồng quản trị', 'memberCount': 8},
  ];

  static const mockBlockedUsers = [
    {'uid': 'mock-uid-1', 'username': 'Lauren'},
  ];
}
