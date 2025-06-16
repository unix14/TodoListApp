package com.eyalya94.tools.todoLater // Replaced with actual package name

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.content.Intent
import android.net.Uri
import es.antonborri.home_widget.HomeWidgetPlugin // Import for HomeWidgetPlugin
import android.app.PendingIntent
import android.content.ComponentName // If not already imported
// If MainActivity is not in the same package, import it:
// import com.eyalya94.tools.todoLater.MainActivity // Assuming MainActivity is in this package

class TodoWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.todo_widget_layout)

        // Set up the intent for the ListView service
        val intent = Intent(context, TodoWidgetService::class.java)
        intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        intent.data = Uri.parse(intent.toUri(Intent.URI_INTENT_SCHEME))
        views.setRemoteAdapter(R.id.widget_list_view, intent)

        // Intent to launch MainActivity
        val mainActivityIntent = Intent(context, MainActivity::class.java) // Ensure MainActivity is resolved
        mainActivityIntent.action = "ADD_TODO_ACTION" // Custom action to identify in MainActivity if needed
        mainActivityIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP

        val pendingIntentFlags = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val addButtonPendingIntent = PendingIntent.getActivity(context, 0, mainActivityIntent, pendingIntentFlags)
        views.setOnClickPendingIntent(R.id.widget_add_button, addButtonPendingIntent)

        // Intent template for ListView item clicks
        val itemClickIntent = Intent(context, MainActivity::class.java) // Or your specific broadcast receiver / activity for item clicks
        itemClickIntent.action = "VIEW_TODO_ACTION" // Custom action
        // Pass appWidgetId if needed by the activity handling the click
        itemClickIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        // No need to set data here, it will be set by fillInIntent in RemoteViewsFactory

        val itemClickPendingIntent = PendingIntent.getActivity(context, 1, itemClickIntent, pendingIntentFlags)
        views.setPendingIntentTemplate(R.id.widget_list_view, itemClickPendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
        appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.widget_list_view)
    }

    override fun onEnabled(context: Context) {
        // Enter relevant functionality for when the first widget is created
    }

    override fun onDisabled(context: Context) {
        // Enter relevant functionality for when the last widget is disabled
    }
}

// TODO: Create TodoWidgetService.kt for the ListView
// TODO: Create TodoWidgetConfigureActivity.kt for widget configuration (optional but good practice)
