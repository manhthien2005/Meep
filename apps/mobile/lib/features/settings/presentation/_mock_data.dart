// Mock data for Settings UI development.
// TODO(T3/NganTNK): Replace với real data sau khi Space module wire xong
// (currently chỉ còn mockSpaces dùng cho SpaceQuickRow pre-M3).

class SettingsMockData {
  static const username = 'ngantran';
  static const displayName = 'Ngan Tran';
  static const friendCount = 15;
  static const avatarUrl = null; // null = show placeholder icon

  static const mockSpaces = <String>['Gia đình', 'Hội đồng quản trị'];
}
