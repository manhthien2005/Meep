package dev.meep.meep

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews

/**
 * Renders the Meep home-screen widget from cached display data.
 *
 * Two render paths exist for one widget:
 *   - This provider: synchronous, runs on the main thread on system
 *     [onUpdate] triggers (widget added, system periodic). It can only set
 *     text and visibility — no network, no image decode.
 *   - [WidgetSyncWorker]: background work that downloads images, queries
 *     unread count, and re-issues `updateAppWidget` with full RemoteViews.
 *
 * Worst-path coverage (spec §Worst path):
 *   - prefs empty → placeholder shown, photo/avatar/caption/count hidden
 *   - prefs populated but Worker hasn't run yet → caption pill renders,
 *     avatar shows default drawable, photo and count remain hidden until
 *     Worker fills the bitmaps
 *   - multiple widget instances → every id in [appWidgetIds] receives the
 *     same RemoteViews
 */
class MeepWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val data = WidgetDataStore.read(context)
        val views = buildRemoteViews(context, data)
        appWidgetIds.forEach { id ->
            appWidgetManager.updateAppWidget(id, views)
        }
        // Kick a one-time background refresh — pulls Firestore + images so
        // the widget can replace this fast text path with real photo/count.
        WidgetSyncWorker.enqueueOneTime(context)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        // First widget added to the home screen → start the 15-minute cadence.
        WidgetSyncWorker.schedulePeriodic(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        // Last widget removed → stop the background work.
        WidgetSyncWorker.cancelPeriodic(context)
    }

    internal fun buildRemoteViews(context: Context, data: WidgetData?): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.meep_widget)
        if (data == null) {
            applyPlaceholder(views)
        } else {
            applyData(views, data)
        }
        applyTapIntent(context, views, data?.postId)
        return views
    }

    private fun applyPlaceholder(views: RemoteViews) {
        views.setViewVisibility(R.id.widget_placeholder, View.VISIBLE)
        views.setViewVisibility(R.id.widget_photo, View.GONE)
        views.setViewVisibility(R.id.widget_avatar, View.GONE)
        views.setViewVisibility(R.id.widget_caption, View.GONE)
        views.setViewVisibility(R.id.widget_count, View.GONE)
    }

    private fun applyData(views: RemoteViews, data: WidgetData) {
        views.setViewVisibility(R.id.widget_placeholder, View.GONE)
        // Photo and unread count are bitmap/network-dependent — left hidden
        // until WidgetSyncWorker pushes its own RemoteViews update.
        views.setViewVisibility(R.id.widget_photo, View.GONE)
        views.setViewVisibility(R.id.widget_count, View.GONE)

        // Avatar uses the default circular drawable from the layout; Worker
        // will replace it with a downloaded circular bitmap when available.
        views.setViewVisibility(R.id.widget_avatar, View.VISIBLE)

        if (data.caption != null) {
            views.setTextViewText(R.id.widget_caption, data.caption)
            views.setViewVisibility(R.id.widget_caption, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.widget_caption, View.GONE)
        }
    }

    companion object {
        /**
         * Apply the tap-to-open PendingIntent on the widget root.
         *
         * When [postId] is non-null the intent carries extras so
         * [MainActivity] deep-links to the corresponding post. When null
         * (placeholder) the app opens at Home.
         *
         * Also called by [WidgetSyncWorker] so the PendingIntent is present
         * on every RemoteViews update (not just the initial [onUpdate]).
         */
        fun applyTapIntent(context: Context, views: RemoteViews, postId: String?) {
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                if (postId != null) {
                    putExtra("action", "OPEN_POST")
                    putExtra("postId", postId)
                }
            }
            val requestCode = postId?.hashCode() ?: 0
            val pendingIntent = PendingIntent.getActivity(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            views.setOnClickPendingIntent(R.id.meep_widget_root, pendingIntent)
        }
    }
}
