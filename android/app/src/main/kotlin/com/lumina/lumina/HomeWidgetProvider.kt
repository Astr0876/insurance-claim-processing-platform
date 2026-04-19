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
                // home_widget saves everything as strings
                val nextClass = widgetData.getString("next_class_label", "No class") ?: "No class"
                val nextTime = widgetData.getString("next_class_time", "--") ?: "--"
                val attendancePctStr = widgetData.getString("attendance_percentage", "100") ?: "100"
                val attendancePct = attendancePctStr.toDoubleOrNull() ?: 100.0
                val risk = widgetData.getString("risk_label", "LOW") ?: "LOW"
                val deadlinesStr = widgetData.getString("upcoming_deadlines_count", "0") ?: "0"
                val upcomingDeadlinesCount = deadlinesStr.toIntOrNull() ?: 0

                // Set text views
                setTextViewText(R.id.tv_next_class, nextClass)
                setTextViewText(R.id.tv_next_time, nextTime)
                setTextViewText(R.id.tv_attendance, "${attendancePct.toInt()}% ($risk)")
                setTextViewText(R.id.tv_deadlines, "$upcomingDeadlinesCount Due")

                // Dynamic color based on risk
                val color = when (risk) {
                    "HIGH" -> 0xFFFF6B6B.toInt()
                    "MEDIUM" -> 0xFFFFAB76.toInt()
                    else -> 0xFF77DD77.toInt()
                }
                setInt(R.id.ll_attendance_container, "setBackgroundColor", color)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
