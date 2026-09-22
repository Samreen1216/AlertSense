package com.alertsense

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
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
        const val ACTION_SLIDE_TO = "com.alertsense.ACTION_SLIDE_TO"
        const val PREF_CURRENT_SLIDE = "current_slide_index"
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        try {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, AlertSenseWidgetProvider::class.java)
            val ids = appWidgetManager.getAppWidgetIds(componentName)

            when (intent.action) {
                ACTION_SLIDE_NEXT -> {
                    val widgetData = HomeWidgetPlugin.getData(context)
                    val current = widgetData.getInt(PREF_CURRENT_SLIDE, 0)
                    val next = (current + 1) % 3
                    widgetData.edit().putInt(PREF_CURRENT_SLIDE, next).apply()
                    onUpdate(context, appWidgetManager, ids, widgetData)
                }
                ACTION_SLIDE_PREV -> {
                    val widgetData = HomeWidgetPlugin.getData(context)
                    val current = widgetData.getInt(PREF_CURRENT_SLIDE, 0)
                    val prev = (current - 1 + 3) % 3
                    widgetData.edit().putInt(PREF_CURRENT_SLIDE, prev).apply()
                    onUpdate(context, appWidgetManager, ids, widgetData)
                }
                ACTION_SLIDE_TO -> {
                    val target = intent.getIntExtra("slide_index", 0).coerceIn(0, 2)
                    val widgetData = HomeWidgetPlugin.getData(context)
                    widgetData.edit().putInt(PREF_CURRENT_SLIDE, target).apply()
                    onUpdate(context, appWidgetManager, ids, widgetData)
                }
                AppWidgetManager.ACTION_APPWIDGET_UPDATE -> {
                    val widgetData = HomeWidgetPlugin.getData(context)
                    onUpdate(context, appWidgetManager, ids, widgetData)
                }
            }
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
        for (appWidgetId in appWidgetIds) {
            try {
                val views = RemoteViews(context.packageName, R.layout.widget_layout)

                val currentSlide = widgetData.getInt(PREF_CURRENT_SLIDE, 0).coerceIn(0, 2)
                val isListening = widgetData.getBoolean("is_listening", false)
                val activeProfile = widgetData.getString("active_profile", "Home") ?: "Home"
                val ambientDb = widgetData.getString("ambient_db", "38 dB") ?: "38 dB"
                val soundStatus = widgetData.getString("sound_status", "Quiet Environment") ?: "Quiet Environment"
                val monitoredSounds = widgetData.getString("monitored_sounds", "9 Sounds Monitored") ?: "9 Sounds Monitored"

                val lastAlertTitle = widgetData.getString("last_alert_title", "No Recent Alerts") ?: "No Recent Alerts"
                val lastAlertEmoji = widgetData.getString("last_alert_emoji", "🛡️") ?: "🛡️"
                val lastAlertPriority = widgetData.getString("last_alert_priority", "LOW") ?: "LOW"
                val lastAlertMeta = widgetData.getString("last_alert_meta", "All Quiet • Monitoring") ?: "All Quiet • Monitoring"
                val alertsToday = widgetData.getString("alerts_today", "0 Alerts Today") ?: "0 Alerts Today"

                // 1. Header Status Pill (Safe visibility toggles without setBackgroundResource)
                if (isListening) {
                    views.setViewVisibility(R.id.widget_status_pill_live, View.VISIBLE)
                    views.setViewVisibility(R.id.widget_status_pill_paused, View.GONE)
                } else {
                    views.setViewVisibility(R.id.widget_status_pill_live, View.GONE)
                    views.setViewVisibility(R.id.widget_status_pill_paused, View.VISIBLE)
                }

                // 2. Slider Controls & Indicators
                val indicatorText = when (currentSlide) {
                    0 -> "● ○ ○ (1/3)"
                    1 -> "○ ● ○ (2/3)"
                    else -> "○ ○ ● (3/3)"
                }
                views.setTextViewText(R.id.widget_slide_indicator, indicatorText)

                // Next / Prev slide PendingIntents
                val prevIntent = Intent(context, AlertSenseWidgetProvider::class.java).apply {
                    action = ACTION_SLIDE_PREV
                }
                val prevPendingIntent = PendingIntent.getBroadcast(
                    context, 201, prevIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.btn_prev_slide, prevPendingIntent)

                val nextIntent = Intent(context, AlertSenseWidgetProvider::class.java).apply {
                    action = ACTION_SLIDE_NEXT
                }
                val nextPendingIntent = PendingIntent.getBroadcast(
                    context, 202, nextIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.btn_next_slide, nextPendingIntent)
                views.setOnClickPendingIntent(R.id.widget_slide_indicator, nextPendingIntent)

                // 3. Slide Visibility (100% standard RemoteViews API)
                views.setViewVisibility(R.id.layout_slide_1, if (currentSlide == 0) View.VISIBLE else View.GONE)
                views.setViewVisibility(R.id.layout_slide_2, if (currentSlide == 1) View.VISIBLE else View.GONE)
                views.setViewVisibility(R.id.layout_slide_3, if (currentSlide == 2) View.VISIBLE else View.GONE)

                // 4. Slide 1 Data: Live Monitor
                views.setTextViewText(R.id.widget_db_level, ambientDb)
                views.setTextViewText(R.id.widget_sound_status, soundStatus)
                views.setTextViewText(R.id.widget_profile_name, "🏠 $activeProfile Profile")
                views.setTextViewText(R.id.widget_monitored_sounds, monitoredSounds)

                // 5. Slide 2 Data: Recent Alerts Feed
                views.setTextViewText(R.id.widget_alert_title, "$lastAlertEmoji $lastAlertTitle")
                views.setTextViewText(R.id.widget_alert_meta, lastAlertMeta)
                views.setTextViewText(R.id.widget_alert_stats, alertsToday)

                when (lastAlertPriority.uppercase()) {
                    "HIGH" -> {
                        views.setViewVisibility(R.id.widget_alert_priority_badge_high, View.VISIBLE)
                        views.setViewVisibility(R.id.widget_alert_priority_badge_med, View.GONE)
                        views.setViewVisibility(R.id.widget_alert_priority_badge_low, View.GONE)
                    }
                    "MEDIUM", "MED" -> {
                        views.setViewVisibility(R.id.widget_alert_priority_badge_high, View.GONE)
                        views.setViewVisibility(R.id.widget_alert_priority_badge_med, View.VISIBLE)
                        views.setViewVisibility(R.id.widget_alert_priority_badge_low, View.GONE)
                    }
                    else -> {
                        views.setViewVisibility(R.id.widget_alert_priority_badge_high, View.GONE)
                        views.setViewVisibility(R.id.widget_alert_priority_badge_med, View.GONE)
                        views.setViewVisibility(R.id.widget_alert_priority_badge_low, View.VISIBLE)
                    }
                }

                // 6. Deep Link Intents for Quick Functionality
                val homePendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("alertsense://home")
                )
                views.setOnClickPendingIntent(R.id.widget_brand_container, homePendingIntent)

                // Slide 1 Buttons
                val quickScanIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("alertsense://quick-scan")
                )
                views.setOnClickPendingIntent(R.id.btn_quick_scan, quickScanIntent)

                val toggleListenIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("alertsense://toggle-listening")
                )
                views.setOnClickPendingIntent(R.id.btn_toggle_listen, toggleListenIntent)

                // Slide 2 Buttons
                val historyIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("alertsense://history")
                )
                views.setOnClickPendingIntent(R.id.btn_view_history, historyIntent)

                val statsIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("alertsense://stats")
                )
                views.setOnClickPendingIntent(R.id.btn_view_stats, statsIntent)

                // Slide 3 Buttons
                val sosIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("alertsense://emergency")
                )
                views.setOnClickPendingIntent(R.id.btn_action_sos, sosIntent)

                val sleepIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("alertsense://sleep")
                )
                views.setOnClickPendingIntent(R.id.btn_action_sleep, sleepIntent)

                val settingsIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("alertsense://settings")
                )
                views.setOnClickPendingIntent(R.id.btn_action_settings, settingsIntent)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (t: Throwable) {
                Log.e(TAG, "Error updating appWidgetId $appWidgetId: ${t.message}", t)
            }
        }
    }
}
