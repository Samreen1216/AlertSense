package com.alertsense

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

class AlertSenseWidgetProvider : HomeWidgetProvider() {

    companion object {
        const val ACTION_SLIDE_NEXT = "com.alertsense.ACTION_SLIDE_NEXT"
        const val ACTION_SLIDE_PREV = "com.alertsense.ACTION_SLIDE_PREV"
        const val ACTION_SLIDE_TO = "com.alertsense.ACTION_SLIDE_TO"
        const val PREF_CURRENT_SLIDE = "current_slide_index"
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_SLIDE_NEXT -> {
                val widgetData = HomeWidgetPlugin.getData(context)
                val current = widgetData.getInt(PREF_CURRENT_SLIDE, 0)
                val next = (current + 1) % 3
                widgetData.edit().putInt(PREF_CURRENT_SLIDE, next).apply()

                val appWidgetManager = AppWidgetManager.getInstance(context)
                val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, AlertSenseWidgetProvider::class.java))
                onUpdate(context, appWidgetManager, ids, widgetData)
            }
            ACTION_SLIDE_PREV -> {
                val widgetData = HomeWidgetPlugin.getData(context)
                val current = widgetData.getInt(PREF_CURRENT_SLIDE, 0)
                val prev = (current - 1 + 3) % 3
                widgetData.edit().putInt(PREF_CURRENT_SLIDE, prev).apply()

                val appWidgetManager = AppWidgetManager.getInstance(context)
                val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, AlertSenseWidgetProvider::class.java))
                onUpdate(context, appWidgetManager, ids, widgetData)
            }
            ACTION_SLIDE_TO -> {
                val target = intent.getIntExtra("slide_index", 0).coerceIn(0, 2)
                val widgetData = HomeWidgetPlugin.getData(context)
                widgetData.edit().putInt(PREF_CURRENT_SLIDE, target).apply()

                val appWidgetManager = AppWidgetManager.getInstance(context)
                val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, AlertSenseWidgetProvider::class.java))
                onUpdate(context, appWidgetManager, ids, widgetData)
            }
            else -> super.onReceive(context, intent)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
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

            // 1. Header Status Pill
            if (isListening) {
                views.setInt(R.id.widget_status_pill, "setBackgroundResource", R.drawable.widget_pill_live)
                views.setTextViewText(R.id.widget_status_pill, "● LIVE")
                views.setTextColor(R.id.widget_status_pill, Color.parseColor("#10B981"))
            } else {
                views.setInt(R.id.widget_status_pill, "setBackgroundResource", R.drawable.widget_pill_paused)
                views.setTextViewText(R.id.widget_status_pill, "○ PAUSED")
                views.setTextColor(R.id.widget_status_pill, Color.parseColor("#94A3B8"))
            }

            // 2. Slider Controls & Indicators
            val indicatorText = when (currentSlide) {
                0 -> "● ○ ○ (1/3)"
                1 -> "○ ● ○ (2/3)"
                else -> "○ ○ ● (3/3)"
            }
            views.setTextViewText(R.id.widget_slide_indicator, indicatorText)

            // Setup Next / Prev intents
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

            // 3. Slide Visibility
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
                    views.setInt(R.id.widget_alert_priority_badge, "setBackgroundResource", R.drawable.widget_badge_high)
                    views.setTextViewText(R.id.widget_alert_priority_badge, "HIGH")
                    views.setTextColor(R.id.widget_alert_priority_badge, Color.parseColor("#EF4444"))
                }
                "MEDIUM" -> {
                    views.setInt(R.id.widget_alert_priority_badge, "setBackgroundResource", R.drawable.widget_badge_medium)
                    views.setTextViewText(R.id.widget_alert_priority_badge, "MED")
                    views.setTextColor(R.id.widget_alert_priority_badge, Color.parseColor("#F59E0B"))
                }
                else -> {
                    views.setInt(R.id.widget_alert_priority_badge, "setBackgroundResource", R.drawable.widget_badge_low)
                    views.setTextViewText(R.id.widget_alert_priority_badge, "LOW")
                    views.setTextColor(R.id.widget_alert_priority_badge, Color.parseColor("#10B981"))
                }
            }

            // 6. Deep Link Intents for Quick Functionality
            // Tap Header / Brand -> Open Home
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
        }
    }
}
