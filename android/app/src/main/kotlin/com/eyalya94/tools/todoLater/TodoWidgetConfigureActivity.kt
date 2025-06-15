package com.eyalya94.tools.todoLater // Ensure this matches your project's package name

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.ArrayAdapter
import android.widget.Spinner
import android.widget.Button
import org.json.JSONArray // For parsing categories

class TodoWidgetConfigureActivity : Activity() {
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private lateinit var categorySpinner: Spinner

    companion object {
        const val PREFS_NAME = "com.eyalya94.tools.todoLater.TodoWidgetConfigureActivity" // Keep it specific
        const val PREF_PREFIX_KEY = "widget_category_"
    }

    public override fun onCreate(icicle: Bundle?) {
        super.onCreate(icicle)
        setResult(RESULT_CANCELED)
        setContentView(R.layout.todo_widget_configure) // Create this layout file

        categorySpinner = findViewById(R.id.category_spinner)
        findViewById<Button>(R.id.save_button).setOnClickListener(onClickListener)

        val intent = intent
        val extras = intent.extras
        if (extras != null) {
            appWidgetId = extras.getInt(
                AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
        }

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        loadCategoriesAndSetupSpinner()
    }

    private fun loadCategoriesAndSetupSpinner() {
        val categories = mutableListOf<String>()
        categories.add("All") // Default "All" category

        // Load categories from SharedPreferences (similar to how Flutter app saves them)
        // The key for categories is "flutter.categories"
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val categoriesJson = prefs.getString("flutter.categories", null)

        if (categoriesJson != null) {
            try {
                val jsonArray = JSONArray(categoriesJson)
                for (i in 0 until jsonArray.length()) {
                    categories.add(jsonArray.getString(i))
                }
            } catch (e: Exception) {
                // Handle error or log
            }
        }

        val adapter = ArrayAdapter(this, android.R.layout.simple_spinner_item, categories)
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        categorySpinner.adapter = adapter
    }

    private val onClickListener = View.OnClickListener {
        val context: Context = this@TodoWidgetConfigureActivity
        val selectedCategory = categorySpinner.selectedItem as String
        saveCategoryPref(context, appWidgetId, selectedCategory)

        // It is the responsibility of the configuration activity to update the app widget
        val appWidgetManager = AppWidgetManager.getInstance(context)
        // Manually call onUpdate on the provider to refresh the widget
        val intent = Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE, null, context, TodoWidgetProvider::class.java)
        intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
        sendBroadcast(intent)

        // Also, explicitly update the widget views via the manager
        // This is important because onUpdate might not be sufficient alone after configuration
        val views = android.widget.RemoteViews(context.packageName, R.layout.todo_widget_layout)
        // Re-setup the service intent for the ListView
        val serviceIntent = Intent(context, TodoWidgetService::class.java)
        serviceIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        serviceIntent.data = android.net.Uri.parse(serviceIntent.toUri(Intent.URI_INTENT_SCHEME))
        views.setRemoteAdapter(R.id.widget_list_view, serviceIntent)
        appWidgetManager.updateAppWidget(appWidgetId, views)
        appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.widget_list_view)


        val resultValue = Intent()
        resultValue.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        setResult(RESULT_OK, resultValue)
        finish()
    }

    private fun saveCategoryPref(context: Context, appWidgetId: Int, category: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, 0).edit()
        prefs.putString(PREF_PREFIX_KEY + appWidgetId, category)
        prefs.apply()
    }
}
