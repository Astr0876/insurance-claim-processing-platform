package com.lumina.lumina

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetBackgroundIntent

class AttendanceWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.attendance_widget_layout).apply {
                // SharedPreferences stores doubles as long bits; home_widget saves them as strings
                val nextClass = widgetData.getString("att_next_class", "No class") ?: "No class"
                val nextTime = widgetData.getString("att_next_time", "--:--") ?: "--:--"
                val currentPct = parseDouble(widgetData, "att_current_pct", 75.0)
                val ifAttendPct = parseDouble(widgetData, "att_if_attend_pct", 76.0)
                val ifSkipPct = parseDouble(widgetData, "att_if_skip_pct", 74.0)
                val risk = widgetData.getString("att_risk", "LOW") ?: "LOW"
                val safeBunks = parseInt(widgetData, "att_safe_bunks", 0)

                // Set text views
                setTextViewText(R.id.att_next_class, nextClass)
                setTextViewText(R.id.att_next_time, nextTime)
                setTextViewText(R.id.att_current_pct, "${currentPct.toInt()}%")
                setTextViewText(R.id.att_if_attend, "▲ ${ifAttendPct.toInt()}%")
                setTextViewText(R.id.att_if_skip, "▼ ${ifSkipPct.toInt()}%")
                setTextViewText(R.id.att_risk_label, risk)
                setTextViewText(R.id.att_safe_bunks, if (safeBunks > 0) "Can skip $safeBunks more" else "Attend all classes!")

                // Risk color
                val riskColor = when (risk) {
                    "HIGH" -> 0xFFFF6B6B.toInt()
                    "MEDIUM" -> 0xFFFFAB76.toInt()
                    else -> 0xFF77DD77.toInt()
                }
                setInt(R.id.att_risk_badge, "setBackgroundColor", riskColor)

                // Attend button intent
                val attendIntent = HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("homewidget://attendance_attend")
                )
                setOnClickPendingIntent(R.id.btn_attend, attendIntent)

                // Skip button intent
                val skipIntent = HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("homewidget://attendance_skip")
                )
                setOnClickPendingIntent(R.id.btn_skip, skipIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    // home_widget saves doubles/ints as strings in SharedPreferences
    private fun parseDouble(prefs: SharedPreferences, key: String, default: Double): Double {
        return try {
            val value = prefs.getString(key, null)
            value?.toDoubleOrNull() ?: try {
                prefs.getFloat(key, default.toFloat()).toDouble()
            } catch (e: Exception) {
                default
            }
        } catch (e: Exception) {
            default
        }
    }

    private fun parseInt(prefs: SharedPreferences, key: String, default: Int): Int {
        return try {
            val value = prefs.getString(key, null)
            value?.toIntOrNull() ?: try {
                prefs.getInt(key, default)
            } catch (e: Exception) {
                default
            }
        } catch (e: Exception) {
            default
        }
    }
}
