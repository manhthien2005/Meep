package dev.meep.meep

import android.content.Context

/**
 * Reads widget display data written by the Flutter side via the
 * `shared_preferences` plugin.
 *
 * The plugin stores values in the `FlutterSharedPreferences` file with every
 * key prefixed by `flutter.` — that prefix is owned by the plugin, not by us,
 * and must be kept in sync if the plugin ever changes it.
 *
 * Contract (spec docs/specs/2026-05-23-widget-android.md §3):
 *   widget_post_id            String   required — deep-link target
 *   widget_image_url          String   required — fullscreen photo URL
 *   widget_author_avatar_url  String?  optional — null falls back to default avatar
 *   widget_caption            String?  optional — null hides the caption pill
 *   widget_caption_type       String?  optional — passed through; widget renders text only
 *   widget_last_viewed_at     Long     defaults to 0 if absent
 *
 * Returns null when either required key is missing, signalling "no data → show
 * placeholder" to [MeepWidget.onUpdate].
 */
data class WidgetData(
    val postId: String,
    val imageUrl: String,
    val authorAvatarUrl: String?,
    val caption: String?,
    val captionType: String?,
    val lastViewedAtMillis: Long,
)

object WidgetDataStore {
    private const val PREFS_NAME = "FlutterSharedPreferences"
    private const val KEY_PREFIX = "flutter."

    const val KEY_POST_ID = "${KEY_PREFIX}widget_post_id"
    const val KEY_IMAGE_URL = "${KEY_PREFIX}widget_image_url"
    const val KEY_AUTHOR_AVATAR_URL = "${KEY_PREFIX}widget_author_avatar_url"
    const val KEY_CAPTION = "${KEY_PREFIX}widget_caption"
    const val KEY_CAPTION_TYPE = "${KEY_PREFIX}widget_caption_type"
    const val KEY_LAST_VIEWED_AT = "${KEY_PREFIX}widget_last_viewed_at"

    fun read(context: Context): WidgetData? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val postId = prefs.getString(KEY_POST_ID, null)?.takeIf { it.isNotBlank() }
            ?: return null
        val imageUrl = prefs.getString(KEY_IMAGE_URL, null)?.takeIf { it.isNotBlank() }
            ?: return null
        return WidgetData(
            postId = postId,
            imageUrl = imageUrl,
            authorAvatarUrl = prefs.getString(KEY_AUTHOR_AVATAR_URL, null)
                ?.takeIf { it.isNotBlank() },
            caption = prefs.getString(KEY_CAPTION, null)?.takeIf { it.isNotBlank() },
            captionType = prefs.getString(KEY_CAPTION_TYPE, null)
                ?.takeIf { it.isNotBlank() },
            lastViewedAtMillis = prefs.getLong(KEY_LAST_VIEWED_AT, 0L),
        )
    }

    /**
     * Standalone reader for [KEY_LAST_VIEWED_AT].
     *
     * [WidgetSyncWorker] needs this value even when no widget data exists yet
     * (first launch). Defaults to 0L → every feed post counts as unread.
     */
    fun readLastViewedAt(context: Context): Long {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getLong(KEY_LAST_VIEWED_AT, 0L)
    }
}
