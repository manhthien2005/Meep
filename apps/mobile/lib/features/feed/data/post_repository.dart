import 'package:meep/features/feed/data/post.dart';

abstract class PostRepository {
  /// Upload photo + create Firestore post doc. Returns created post.
  Future<Post> createPost(Post post);

  /// Stream of paginated feed for [uid], newest first.
  Stream<List<Post>> watchFeed(String uid);

  /// Delete a post and its Storage assets.
  Future<void> deletePost(String postId);

  /// All posts authored by [authorId], newest first.
  Future<List<Post>> getPostsByAuthor(String authorId);
}
