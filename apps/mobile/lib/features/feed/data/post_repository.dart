import 'package:meep/features/feed/data/post.dart';

abstract class PostRepository {
  /// Upload photo + create Firestore post doc. Returns created post.
  Future<Post> createPost(Post post);

  /// Stream of paginated feed for [uid], newest first.
  ///
  /// Khi [spaceId] null (default): feed chung — posts của user + friends,
  /// loại bỏ posts đăng vào Space (post.spaceIds không rỗng).
  ///
  /// Khi [spaceId] != null: chỉ posts đăng vào Space đó (post.spaceIds
  /// chứa [spaceId]). Implementation query `memberIds arrayContains uid`
  /// + client filter theo `spaceIds` — disjunct rule `/posts` (3) cần
  /// query constraint khớp `memberIds.hasAny([uid])` để engine prove.
  Stream<List<Post>> watchFeed(String uid, {String? spaceId});

  /// Delete a post and its Storage assets.
  Future<void> deletePost(String postId);

  /// All posts authored by [authorId], newest first.
  Future<List<Post>> getPostsByAuthor(String authorId);

  /// Fetch a single post by id. Returns null when doc không tồn tại (đã xóa
  /// hoặc id sai). Caller responsibility lấy permission đúng — rule `/posts`
  /// read enforce friend/owner/feed-entry.
  ///
  /// Dùng bởi chat module (`chatQuotedPostProvider`) để render quoted photo
  /// block ở đầu thread khi user reply post từ feed.
  Future<Post?> getPost(String postId);
}
