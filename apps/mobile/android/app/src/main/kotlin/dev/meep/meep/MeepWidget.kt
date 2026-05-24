package dev.meep.meep

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context

// TODO(W/T1/TBD): implement MeepWidget — loads image from SharedPreferences
// and calls AppWidgetManager.updateAppWidget() with RemoteViews
class MeepWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        // Stub — WidgetSyncWorker handles actual updates
    }
}
