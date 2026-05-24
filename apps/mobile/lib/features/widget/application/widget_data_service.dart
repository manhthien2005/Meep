// TODO(W/T4/TBD): implement WidgetDataService — writes latest post data
// to SharedPreferences so WidgetSyncWorker (Kotlin) can read it.
// Fields to write: postId, imageUrl, authorName
abstract class WidgetDataService {
  Future<void> saveLatestPost({
    required String postId,
    required String imageUrl,
    required String authorName,
  });

  Future<void> clearData();
}
