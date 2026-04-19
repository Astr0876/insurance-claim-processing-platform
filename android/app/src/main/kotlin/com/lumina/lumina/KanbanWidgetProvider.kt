package com.lumina.lumina

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class KanbanWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.kanban_widget_layout).apply {
                val todoCount = parseInt(widgetData, "kanban_todo_count", 0)
                val doingCount = parseInt(widgetData, "kanban_doing_count", 0)
                val doneCount = parseInt(widgetData, "kanban_done_count", 0)

                val todoTasks = widgetData.getString("kanban_todo_tasks", "")?.split("|")?.filter { it.isNotBlank() } ?: emptyList()
                val doingTasks = widgetData.getString("kanban_doing_tasks", "")?.split("|")?.filter { it.isNotBlank() } ?: emptyList()
                val doneTasks = widgetData.getString("kanban_done_tasks", "")?.split("|")?.filter { it.isNotBlank() } ?: emptyList()

                // Set counts
                setTextViewText(R.id.kanban_todo_count, todoCount.toString())
                setTextViewText(R.id.kanban_doing_count, doingCount.toString())
                setTextViewText(R.id.kanban_done_count, doneCount.toString())

                // Set task lists
                setTextViewText(R.id.kanban_todo_list, todoTasks.take(3).joinToString("\n") { "• $it" }.ifEmpty { "No tasks" })
                setTextViewText(R.id.kanban_doing_list, doingTasks.take(3).joinToString("\n") { "• $it" }.ifEmpty { "No tasks" })
                setTextViewText(R.id.kanban_done_list, doneTasks.take(3).joinToString("\n") { "• $it" }.ifEmpty { "No tasks" })

                // Open app on tap
                val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                if (launchIntent != null) {
                    val pendingIntent = android.app.PendingIntent.getActivity(
                        context, 0, launchIntent,
                        android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                    )
                    setOnClickPendingIntent(R.id.kanban_widget_root, pendingIntent)
                }
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
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
