package com.alertsense

import android.app.ActivityOptions
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

class AlertSenseWidgetProvider : HomeWidgetProvider() {

    companion object {
        private const val TAG = "AlertSenseWidget"
        const val ACTION_SLIDE_NEXT = "com.alertsense.ACTION_SLIDE_NEXT"
        const val ACTION_SLIDE_PREV = "com.alertsense.ACTION_SLIDE_PREV"
        const val ACTION_SLIDE_TO   = "com.alertsense.ACTION_SLIDE_TO"
        const val PREF_CURRENT_SLIDE = "current_slide_index"

        // Unique request codes for Activity pending intents
        private const val REQ_HEADER_APP      = 201
        private const val REQ_BRAND_HOME      = 202
        private const val REQ_QUICK_SCAN      = 203
        private const val REQ_TOGGLE_LISTEN   = 204
        private const val REQ_VIEW_HISTORY    = 205
        private const val REQ_VIEW_STATS      = 206
        private const val REQ_ACTION_SOS      = 207
        private const val REQ_ACTION_SLEEP    = 208
        private const val REQ_ACTION_SETTINGS = 209
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        try {
            val action = intent.action ?: return
            Log.i(TAG, "onReceive action=$action")

            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, AlertSenseWidgetProvider::class.java)
            val allIds = appWidgetManager.getAppWidgetIds(componentName) ?: intArrayOf()
            val clickedId = intent.getIntExtra(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                AppWidgetManager.INVALID_APPWIDGET_ID
            )

            val widgetData = HomeWidgetPlugin.getData(context)

            var isSlideAction = false
            when (action) {
                ACTION_SLIDE_NEXT -> {
                    isSlideAction = true
                    val current = widgetData.getInt(PREF_CURRENT_SLIDE, 0)
                    val next = (current + 1) % 3
                    widgetData.edit().putInt(PREF_CURRENT_SLIDE, next).commit()
                    Log.i(TAG, "ACTION_SLIDE_NEXT: current=$current, next=$next")
                }
                ACTION_SLIDE_PREV -> {
                    isSlideAction = true
                    val current = widgetData.getInt(PREF_CURRENT_SLIDE, 0)
                    val prev = (current - 1 + 3) % 3
                    widgetData.edit().putInt(PREF_CURRENT_SLIDE, prev).commit()
                    Log.i(TAG, "ACTION_SLIDE_PREV: current=$current, prev=$prev")
                }
                ACTION_SLIDE_TO -> {
                    isSlideAction = true
                    val target = intent.getIntExtra("slide_index", 0).coerceIn(0, 2)
                    widgetData.edit().putInt(PREF_CURRENT_SLIDE, target).commit()
                    Log.i(TAG, "ACTION_SLIDE_TO: target=$target")
                }
                AppWidgetManager.ACTION_APPWIDGET_UPDATE -> {
                    // Update from Flutter or system
                }
                else -> return
            }

            val freshData = HomeWidgetPlugin.getData(context)

            val targetIds = when {
                allIds.isNotEmpty() -> allIds
                clickedId != AppWidgetManager.INVALID_APPWIDGET_ID -> intArrayOf(clickedId)
                else -> intArrayOf(0)
            }

            // Update specific widget instance IDs
            onUpdate(context, appWidgetManager, targetIds, freshData)

            // Also push to component directly so all launchers (Vivo, Samsung, etc.) refresh instantly
            val currentSlide = freshData.getInt(PREF_CURRENT_SLIDE, 0).coerceIn(0, 2)
            val fallbackViews = buildViewsForHost(context, 0, currentSlide, freshData)
            appWidgetManager.updateAppWidget(componentName, fallbackViews)

        } catch (t: Throwable) {
            Log.e(TAG, "Error in onReceive: ${t.message}", t)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val currentSlide = widgetData.getInt(PREF_CURRENT_SLIDE, 0).coerceIn(0, 2)
        val componentName = ComponentName(context, AlertSenseWidgetProvider::class.java)
        val targetIds = if (appWidgetIds.isNotEmpty()) {
            appWidgetIds
        } else {
            appWidgetManager.getAppWidgetIds(componentName) ?: intArrayOf()
        }

        for (appWidgetId in targetIds) {
            try {
                val views = buildViewsForHost(context, appWidgetId, currentSlide, widgetData)
                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (t: Throwable) {
                Log.e(TAG, "Error updating widget $appWidgetId: ${t.message}", t)
            }
        }
    }

    private fun buildViewsForHost(
        context: Context,
        appWidgetId: Int,
        currentSlide: Int,
        widgetData: SharedPreferences
    ): RemoteViews {
        val isListening = try {
            widgetData.getBoolean("is_listening", false)
        } catch (_: Exception) {
            widgetData.getString("is_listening", "false")?.toBooleanStrictOrNull() ?: false
        }

        val activeProfile   = widgetData.getString("active_profile",   "Home")        ?: "Home"
        val ambientDb       = widgetData.getString("ambient_db",        "38 dB")       ?: "38 dB"
        val soundStatus     = widgetData.getString("sound_status",      "Quiet Environment") ?: "Quiet Environment"
        val monitoredSounds = widgetData.getString("monitored_sounds",  "9 Sounds Monitored") ?: "9 Sounds Monitored"

        val lastAlertTitle    = widgetData.getString("last_alert_title",    "No Recent Alerts")    ?: "No Recent Alerts"
        val lastAlertEmoji    = widgetData.getString("last_alert_emoji",    "🛡️")               ?: "🛡️"
        val lastAlertPriority = widgetData.getString("last_alert_priority", "LOW")                 ?: "LOW"
        val lastAlertMeta     = widgetData.getString("last_alert_meta",     "All Quiet • Monitoring") ?: "All Quiet • Monitoring"
        val alertsToday       = widgetData.getString("alerts_today",        "0 Alerts Today")      ?: "0 Alerts Today"

        val indicatorText = when (currentSlide) {
            0    -> "● ○ ○"
            1    -> "○ ● ○"
            else -> "○ ○ ●"
        }

        val views = RemoteViews(context.packageName, R.layout.widget_layout)

        // ── 1. Top Header Status Pill ───────────────────────────────────────────────
        if (isListening) {
            views.setViewVisibility(R.id.widget_status_pill_live,   View.VISIBLE)
            views.setViewVisibility(R.id.widget_status_pill_paused, View.GONE)
        } else {
            views.setViewVisibility(R.id.widget_status_pill_live,   View.GONE)
            views.setViewVisibility(R.id.widget_status_pill_paused, View.VISIBLE)
        }

        // ── 2. Active Slide Visibility ──────────────────────────────────────────────
        views.setViewVisibility(R.id.layout_slide_1, if (currentSlide == 0) View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.layout_slide_2, if (currentSlide == 1) View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.layout_slide_3, if (currentSlide == 2) View.VISIBLE else View.GONE)

        // ── 3. Slide 1 Data: Live Monitor ──────────────────────────────────────────
        val profileEmoji = when (activeProfile.lowercase().trim()) {
            "sleep" -> "🌙"
            "outdoor" -> "🌳"
            else -> "🏠"
        }
        views.setTextViewText(R.id.widget_db_level,         ambientDb)
        views.setTextViewText(R.id.widget_sound_status,     soundStatus)
        views.setTextViewText(R.id.widget_profile_name,     "$profileEmoji $activeProfile Profile")
        views.setTextViewText(R.id.widget_monitored_sounds, monitoredSounds)

        // Dynamic Mic button label
        views.setTextViewText(
            R.id.btn_toggle_listen,
            if (isListening) "⏸️ Pause Mic" else "🎙️ Start Mic"
        )

        // ── 4. Slide 2 Data: Recent Alerts Feed ────────────────────────────────────
        views.setTextViewText(R.id.widget_alert_title, "$lastAlertEmoji $lastAlertTitle")
        views.setTextViewText(R.id.widget_alert_meta,  lastAlertMeta)
        views.setTextViewText(R.id.widget_alert_stats, alertsToday)

        when (lastAlertPriority.uppercase()) {
            "HIGH" -> {
                views.setViewVisibility(R.id.widget_alert_priority_badge_high, View.VISIBLE)
                views.setViewVisibility(R.id.widget_alert_priority_badge_med,  View.GONE)
                views.setViewVisibility(R.id.widget_alert_priority_badge_low,  View.GONE)
            }
            "MEDIUM", "MED" -> {
                views.setViewVisibility(R.id.widget_alert_priority_badge_high, View.GONE)
                views.setViewVisibility(R.id.widget_alert_priority_badge_med,  View.VISIBLE)
                views.setViewVisibility(R.id.widget_alert_priority_badge_low,  View.GONE)
            }
            else -> {
                views.setViewVisibility(R.id.widget_alert_priority_badge_high, View.GONE)
                views.setViewVisibility(R.id.widget_alert_priority_badge_med,  View.GONE)
                views.setViewVisibility(R.id.widget_alert_priority_badge_low,  View.VISIBLE)
            }
        }

        // ── 5. Bottom Navigation Row (Clean Dots + Touch Targets) ─────────────────
        views.setTextViewText(R.id.widget_slide_indicator, indicatorText)

        val prevIntent = createSlideBroadcast(
            context, ACTION_SLIDE_PREV, appWidgetId, 5001 + (appWidgetId * 10)
        )
        val nextIntent = createSlideBroadcast(
            context, ACTION_SLIDE_NEXT, appWidgetId, 5002 + (appWidgetId * 10)
        )

        views.setOnClickPendingIntent(R.id.btn_prev_slide,        prevIntent)
        views.setOnClickPendingIntent(R.id.btn_next_slide,        nextIntent)
        views.setOnClickPendingIntent(R.id.widget_slide_indicator, nextIntent)

        // ── 6. Activity Deep Links ─────────────────────────────────────────────────
        views.setOnClickPendingIntent(R.id.btn_header_app,
            deepLink(context, "alertsense://home",             REQ_HEADER_APP))
        views.setOnClickPendingIntent(R.id.widget_brand_container,
            deepLink(context, "alertsense://home",             REQ_BRAND_HOME))

        // Slide 1 Buttons
        views.setOnClickPendingIntent(R.id.btn_quick_scan,
            deepLink(context, "alertsense://quick-scan",       REQ_QUICK_SCAN))
        views.setOnClickPendingIntent(R.id.btn_toggle_listen,
            deepLink(context, "alertsense://toggle-listening",  REQ_TOGGLE_LISTEN))

        // Slide 2 Buttons
        views.setOnClickPendingIntent(R.id.btn_view_history,
            deepLink(context, "alertsense://history",           REQ_VIEW_HISTORY))
        views.setOnClickPendingIntent(R.id.btn_view_stats,
            deepLink(context, "alertsense://stats",             REQ_VIEW_STATS))

        // Slide 3 Buttons
        views.setOnClickPendingIntent(R.id.btn_action_sos,
            deepLink(context, "alertsense://emergency",         REQ_ACTION_SOS))
        views.setOnClickPendingIntent(R.id.btn_action_sleep,
            deepLink(context, "alertsense://sleep",             REQ_ACTION_SLEEP))
        views.setOnClickPendingIntent(R.id.btn_action_settings,
            deepLink(context, "alertsense://settings",          REQ_ACTION_SETTINGS))

        return views
    }

    private fun createSlideBroadcast(
        context: Context,
        action: String,
        appWidgetId: Int,
        requestCode: Int
    ): PendingIntent {
        val intent = Intent(context, AlertSenseWidgetProvider::class.java).apply {
            this.action = action
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            setPackage(context.packageName)
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        return PendingIntent.getBroadcast(context, requestCode, intent, flags)
    }

    private fun deepLink(
        context: Context,
        uriString: String,
        requestCode: Int
    ): PendingIntent {
        val uri    = Uri.parse(uriString)
        val intent = Intent(context, MainActivity::class.java).apply {
            action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
            data   = uri
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            setPackage(context.packageName)
        }

        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0

        return PendingIntent.getActivity(context, requestCode, intent, flags)
    }
}
