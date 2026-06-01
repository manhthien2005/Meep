package dev.meep.meep

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
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
        // TODO(W/T3/KhoaLND): enqueue WidgetSyncWorker here so images and
        // unread count are refreshed right after the system update tick.
    }

    internal fun buildRemoteViews(context: Context, data: WidgetData?): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.meep_widget)
        if (data == null) {
            applyPlaceholder(views)
        } else {
            applyData(views, data)
        }
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
}
