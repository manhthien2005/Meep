package dev.meep.meep

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.graphics.Bitmap
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import com.bumptech.glide.Glide
import com.bumptech.glide.load.engine.DiskCacheStrategy
import com.bumptech.glide.load.resource.bitmap.CircleCrop
import com.bumptech.glide.request.RequestOptions
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.AggregateSource
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Query
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext
import java.util.concurrent.TimeUnit

/**
 * Background refresh for the home-screen widget.
 *
 * Flow per spec docs/specs/2026-05-23-widget-android.md §3:
 *   1. Refresh the Firebase ID token (skip render path when signed-out).
 *   2. Read the latest feed entry from /users/{uid}/feed and hydrate
 *      /posts/{postId} for image / avatar / caption.
 *   3. Compute unread count = posts in feed with createdAt > lastViewedAt.
 *      count() is server-only; treat any failure as 0 so the photo still
 *      renders.
 *   4. Glide-download photo + avatar; Glide handles disk + memory cache so
 *      offline runs return the previously cached bitmap.
 *   5. Push one RemoteViews update to every active widget instance.
 *
 * Failure handling (spec §Worst path):
 *   - Signed-out                  → placeholder + Result.success()
 *   - Token refresh fails          → placeholder + Result.success()
 *   - Photo download fails          → keep previous render + Result.retry()
 *                                     (Glide cache may already cover this case)
 *   - Unread count() fails          → treat as 0, continue
 *   - Avatar download fails         → default avatar drawable
 *
 * Doze / battery save can defer execution beyond the periodic cadence —
 * known limitation; foreground re-trigger lives in T5.
 */
class WidgetSyncWorker(
    context: Context,
    params: WorkerParameters,
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        val auth = FirebaseAuth.getInstance()
        val user = auth.currentUser
        if (user == null) {
            renderPlaceholder()
            return@withContext Result.success()
        }

        try {
            user.getIdToken(false).await()
        } catch (e: Exception) {
            Log.w(TAG, "Token refresh failed — rendering placeholder", e)
            renderPlaceholder()
            return@withContext Result.success()
        }

        val firestore = FirebaseFirestore.getInstance()
        val latestPost = try {
            fetchLatestPost(firestore, user.uid)
        } catch (e: Exception) {
            Log.w(TAG, "Latest-post fetch failed", e)
            null
        }

        if (latestPost == null) {
            renderPlaceholder()
            return@withContext Result.success()
        }

        val unreadCount = try {
            fetchUnreadCount(
                firestore,
                user.uid,
                WidgetDataStore.readLastViewedAt(applicationContext),
            )
        } catch (e: Exception) {
            Log.w(TAG, "Unread count() failed — defaulting to 0", e)
            0
        }

        val photoBitmap = try {
            loadBitmap(latestPost.imageUrl, circular = false)
        } catch (e: Exception) {
            // Cache miss + network fail. Leave any prior render in place and
            // ask WorkManager to retry on the next backoff tick.
            Log.w(TAG, "Photo load failed (cache miss + offline)", e)
            return@withContext Result.retry()
        }

        val avatarBitmap = latestPost.authorAvatarUrl?.let { url ->
            try {
                loadBitmap(url, circular = true)
            } catch (e: Exception) {
                Log.w(TAG, "Avatar load failed — using default drawable", e)
                null
            }
        }

        renderPost(latestPost, photoBitmap, avatarBitmap, unreadCount)
        Result.success()
    }

    private suspend fun fetchLatestPost(
        firestore: FirebaseFirestore,
        uid: String,
    ): PostPayload? {
        val feedSnap = firestore.collection("users")
            .document(uid)
            .collection("feed")
            .orderBy("createdAt", Query.Direction.DESCENDING)
            .limit(1)
            .get()
            .await()
        val feedDoc = feedSnap.documents.firstOrNull() ?: return null
        val postId = feedDoc.getString("postId") ?: feedDoc.id

        val postSnap = firestore.collection("posts")
            .document(postId)
            .get()
            .await()
        if (!postSnap.exists()) return null

        // Single-camera posts use imageUrl; dual-camera fall back to backImageUrl.
        val imageUrl = postSnap.getString("imageUrl")
            ?: postSnap.getString("backImageUrl")
            ?: return null

        return PostPayload(
            postId = postSnap.id,
            imageUrl = imageUrl,
            authorAvatarUrl = postSnap.getString("authorAvatarUrl"),
            caption = postSnap.getString("caption"),
        )
    }

    private suspend fun fetchUnreadCount(
        firestore: FirebaseFirestore,
        uid: String,
        lastViewedAtMillis: Long,
    ): Int {
        val cutoff = com.google.firebase.Timestamp(
            lastViewedAtMillis / 1000,
            ((lastViewedAtMillis % 1000) * 1_000_000).toInt(),
        )
        val aggregate = firestore.collection("users")
            .document(uid)
            .collection("feed")
            .whereGreaterThan("createdAt", cutoff)
            .count()
            .get(AggregateSource.SERVER)
            .await()
        return aggregate.count.toInt()
    }

    /**
     * Synchronous Glide bitmap fetch — safe on [Dispatchers.IO].
     * Glide consults memory + disk cache before going to the network, so an
     * offline run with a populated cache returns the previously cached bitmap.
     *
     * `.override(width, height)` caps the decoded bitmap to widget render size.
     * Without it, Glide decodes at the source resolution (full-resolution
     * captures from camera = several MB per bitmap) → RemoteViews bundle hits
     * the 1MB IPC limit and OOM risk grows with each periodic refresh.
     *
     * `.get(timeout)` guards the WorkManager IO dispatcher from an indefinite
     * hang if the network stalls past the connectivity constraint check.
     */
    private fun loadBitmap(url: String, circular: Boolean): Bitmap {
        val targetSize = if (circular) AVATAR_TARGET_PX else PHOTO_TARGET_PX
        return Glide.with(applicationContext)
            .asBitmap()
            .load(url)
            .apply(
                RequestOptions()
                    .diskCacheStrategy(DiskCacheStrategy.ALL)
                    .override(targetSize, targetSize)
                    .let {
                        if (circular) it.transform(CircleCrop()) else it
                    },
            )
            .submit(targetSize, targetSize)
            .get(BITMAP_LOAD_TIMEOUT_SECONDS, TimeUnit.SECONDS)
    }

    private fun renderPlaceholder() {
        pushRemoteViews(null) { views ->
            views.setViewVisibility(R.id.widget_placeholder, View.VISIBLE)
            views.setViewVisibility(R.id.widget_photo, View.GONE)
            views.setViewVisibility(R.id.widget_avatar, View.GONE)
            views.setViewVisibility(R.id.widget_caption, View.GONE)
            views.setViewVisibility(R.id.widget_count, View.GONE)
        }
    }

    private fun renderPost(
        post: PostPayload,
        photo: Bitmap,
        avatar: Bitmap?,
        unreadCount: Int,
    ) {
        pushRemoteViews(post.postId) { views ->
            views.setViewVisibility(R.id.widget_placeholder, View.GONE)

            views.setImageViewBitmap(R.id.widget_photo, photo)
            views.setViewVisibility(R.id.widget_photo, View.VISIBLE)

            if (avatar != null) {
                views.setImageViewBitmap(R.id.widget_avatar, avatar)
            } else {
                views.setImageViewResource(
                    R.id.widget_avatar,
                    R.drawable.widget_default_avatar,
                )
            }
            views.setViewVisibility(R.id.widget_avatar, View.VISIBLE)

            if (post.caption != null) {
                views.setTextViewText(R.id.widget_caption, post.caption)
                views.setViewVisibility(R.id.widget_caption, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_caption, View.GONE)
            }

            if (unreadCount > 0) {
                views.setTextViewText(R.id.widget_count, formatCount(unreadCount))
                views.setViewVisibility(R.id.widget_count, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_count, View.GONE)
            }
        }
    }

    private fun pushRemoteViews(postId: String?, build: (RemoteViews) -> Unit) {
        val manager = AppWidgetManager.getInstance(applicationContext)
        val component = ComponentName(applicationContext, MeepWidget::class.java)
        val ids = manager.getAppWidgetIds(component)
        if (ids.isEmpty()) return
        val views = RemoteViews(applicationContext.packageName, R.layout.meep_widget)
        build(views)
        MeepWidget.applyTapIntent(applicationContext, views, postId)
        ids.forEach { id -> manager.updateAppWidget(id, views) }
    }

    private data class PostPayload(
        val postId: String,
        val imageUrl: String,
        val authorAvatarUrl: String?,
        val caption: String?,
    )

    companion object {
        private const val TAG = "WidgetSyncWorker"
        private const val PERIODIC_WORK_NAME = "meep.widget.sync.periodic"
        private const val ONE_TIME_WORK_NAME = "meep.widget.sync.oneshot"
        private const val PERIODIC_INTERVAL_MINUTES = 60L

        // Bitmap targets — match max widget render size. Photo cap chosen so a
        // 4×2 widget at xxxhdpi (~640px wide) renders sharp; avatar at 24dp
        // ≈ 96px (xxhdpi). Glide downsamples source bitmaps to these bounds
        // before decoding → memory + bundle stay under RemoteViews 1MB limit.
        private const val PHOTO_TARGET_PX = 720
        private const val AVATAR_TARGET_PX = 128

        // Cap on Glide's blocking `.get()` — WorkManager IO dispatcher must not
        // sit on a hung future when the network constraint passed but the
        // connection stalled mid-fetch.
        private const val BITMAP_LOAD_TIMEOUT_SECONDS = 20L

        /** Format unread count badge: 1–9 verbatim, ≥10 collapses to "9+". */
        internal fun formatCount(count: Int): String =
            if (count >= 10) "9+" else count.toString()

        /**
         * Schedule the periodic refresh. Safe to call repeatedly —
         * [ExistingPeriodicWorkPolicy.KEEP] preserves the existing schedule.
         * Periodic work is intentionally conservative; immediate refreshes
         * still happen through [enqueueOneTime] when the widget is added.
         */
        fun schedulePeriodic(context: Context) {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.UNMETERED)
                .setRequiresBatteryNotLow(true)
                .build()
            val request = PeriodicWorkRequestBuilder<WidgetSyncWorker>(
                PERIODIC_INTERVAL_MINUTES,
                TimeUnit.MINUTES,
            )
                .setConstraints(constraints)
                .build()
            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                PERIODIC_WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,
                request,
            )
        }

        /**
         * Kick off an immediate refresh — used from [MeepWidget.onUpdate] so a
         * freshly added widget pulls data without waiting for the periodic
         * tick. [ExistingWorkPolicy.REPLACE] coalesces rapid system triggers.
         */
        fun enqueueOneTime(context: Context) {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()
            val request = OneTimeWorkRequestBuilder<WidgetSyncWorker>()
                .setConstraints(constraints)
                .build()
            WorkManager.getInstance(context).enqueueUniqueWork(
                ONE_TIME_WORK_NAME,
                ExistingWorkPolicy.REPLACE,
                request,
            )
        }

        /** Cancel the periodic refresh — call from [MeepWidget.onDisabled]. */
        fun cancelPeriodic(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(PERIODIC_WORK_NAME)
        }
    }
}
