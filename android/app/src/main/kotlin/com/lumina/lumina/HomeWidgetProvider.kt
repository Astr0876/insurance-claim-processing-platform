package com.lumina.lumina

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class HomeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                // Get data from Flutter
                val nextClass = widgetData.getString("next_class_label", "No class")
                val nextTime = widgetData.getString("next_class_time", "--")
                val attendancePct = widgetData.getFloat("attendance_percentage", 100f)
                val risk = widgetData.getString("risk_label", "LOW")
                val upcomingDeadlinesCount = widgetData.getInt("upcoming_deadlines_count", 0)

                // Set text views
                setTextViewText(R.id.tv_next_class, nextClass)
                setTextViewText(R.id.tv_next_time, nextTime)
                setTextViewText(R.id.tv_attendance, "${attendancePct.toInt()}% ($risk)")
                setTextViewText(R.id.tv_deadlines, "$upcomingDeadlinesCount Due")

                // Dynamic color based on risk
                val color = when (risk) {
                    "HIGH" -> 0xFFFF6B6B.toInt()   // NBColors.danger
                    "MEDIUM" -> 0xFFFFAB76.toInt() // NBColors.orange
                    else -> 0xFF77DD77.toInt()     // NBColors.green
                }
                setInt(R.id.ll_attendance_container, "setBackgroundColor", color)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
