package dev.meep.meep

import android.annotation.TargetApi
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var widgetChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        widgetChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "meep/widget",
        )
        widgetChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidget" -> {
                    // Flutter just wrote new data to SharedPreferences —
                    // kick an immediate one-time refresh so the widget
                    // picks up the latest post photo + badge count.
                    WidgetSyncWorker.enqueueOneTime(this@MainActivity)
                    result.success(null)
                }
                "requestPinAppWidget" -> {
                    val appWidgetManager = AppWidgetManager.getInstance(this@MainActivity)
                    if (appWidgetManager.isRequestPinAppWidgetSupported) {
                        pinWidgetViaLauncher(appWidgetManager)
                        result.success(true)
                    } else {
                        // Launcher không hỗ trợ (Android < 8.0, custom ROM
                        // như Xiaomi MIUI cũ) — Dart sẽ hiện toast manual.
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Cold start from widget tap — forward extras to Flutter.
        // MethodChannel buffers the call until Flutter registers its handler.
        forwardWidgetTap(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        forwardWidgetTap(intent)
    }

    private fun forwardWidgetTap(intent: Intent) {
        val action = intent.getStringExtra("action") ?: return
        widgetChannel?.invokeMethod("onWidgetTap", mapOf(
            "action" to action,
            "postId" to intent.getStringExtra("postId"),
        ))
    }

    @TargetApi(Build.VERSION_CODES.O)
    private fun pinWidgetViaLauncher(appWidgetManager: AppWidgetManager) {
        val componentName = ComponentName(this@MainActivity, MeepWidget::class.java)
        appWidgetManager.requestPinAppWidget(componentName, null, null)
    }
}
