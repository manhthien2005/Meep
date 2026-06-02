/// View model cho BlockedAccountsPage: join `Block` (uid only) với
/// `UserProfile` (username, avatar) để hiển thị list.
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
