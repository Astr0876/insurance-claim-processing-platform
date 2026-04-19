package com.lumina.lumina

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetBackgroundIntent

class KanbanWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.kanban_widget_layout).apply {
                // Get kanban data from Flutter
                val todoCount = widgetData.getInt("kanban_todo_count", 0)
                val doingCount = widgetData.getInt("kanban_doing_count", 0)
                val doneCount = widgetData.getInt("kanban_done_count", 0)
                
                // Task titles (up to 3 per column, JSON-encoded as comma-separated)
                val todoTasks = widgetData.getString("kanban_todo_tasks", "")?.split("|") ?: emptyList()
                val doingTasks = widgetData.getString("kanban_doing_tasks", "")?.split("|") ?: emptyList()
                val doneTasks = widgetData.getString("kanban_done_tasks", "")?.split("|") ?: emptyList()

                // Set counts
                setTextViewText(R.id.kanban_todo_count, todoCount.toString())
                setTextViewText(R.id.kanban_doing_count, doingCount.toString())
                setTextViewText(R.id.kanban_done_count, doneCount.toString())

                // Set task lists (show up to 3 tasks per column)
                setTextViewText(R.id.kanban_todo_list, todoTasks.take(3).joinToString("\n") { "• $it" }.ifEmpty { "No tasks" })
                setTextViewText(R.id.kanban_doing_list, doingTasks.take(3).joinToString("\n") { "• $it" }.ifEmpty { "No tasks" })
                setTextViewText(R.id.kanban_done_list, doneTasks.take(3).joinToString("\n") { "• $it" }.ifEmpty { "No tasks" })

                // Open app intent
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
}
