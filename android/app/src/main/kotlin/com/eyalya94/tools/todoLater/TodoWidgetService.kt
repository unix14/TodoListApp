package com.eyalya94.tools.todoLater // Ensure this matches your project's package name

import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import android.os.Bundle // For SharedPreferences
import org.json.JSONArray // For parsing JSON
import org.json.JSONObject
import android.util.Log // For logging
import javax.crypto.Cipher
import javax.crypto.spec.IvParameterSpec
import javax.crypto.spec.SecretKeySpec
import java.util.Base64 // For Base64 decoding
import java.io.InputStreamReader // For reading asset file

class TodoWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return TodoWidgetItemFactory(applicationContext, intent)
    }
}

class TodoWidgetItemFactory(private val context: Context, private val intent: Intent) : RemoteViewsService.RemoteViewsFactory {
    private var todoItems: List<Pair<String, Boolean>> = emptyList()
    private val appWidgetId: Int = intent.getIntExtra(android.appwidget.AppWidgetManager.EXTRA_APPWIDGET_ID, android.appwidget.AppWidgetManager.INVALID_APPWIDGET_ID)

    private var key: SecretKeySpec? = null
    private var iv: IvParameterSpec? = null
    private val AES_MODE = "AES/CBC/PKCS5Padding" // Common mode for AES with IV

    override fun onCreate() {
        initializeEncryption(context)
        loadTodoData()
    }

    private fun initializeEncryption(context: Context) {
        try {
            val assetManager = context.assets
            // Try to load from "config/encryption_config.json" as per Flutter's rootBundle access
            val inputStream = assetManager.open("config/encryption_config.json")
            val jsonConfig = InputStreamReader(inputStream).readText()
            val config = JSONObject(jsonConfig)

            val keyString = config.getString("key")
            val ivString = config.getString("iv")

            // IMPORTANT: Ensure key and IV are correct length for AES.
            // Flutter's Key.fromUtf8 and IV.fromUtf8 might truncate or pad.
            // Here, we assume they are valid UTF-8 strings that result in correct byte lengths (e.g., 16, 24, or 32 bytes for key, 16 for IV).
            key = SecretKeySpec(keyString.toByteArray(Charsets.UTF_8), "AES")
            iv = IvParameterSpec(ivString.toByteArray(Charsets.UTF_8))
            Log.d("TodoWidgetItemFactory", "Encryption initialized successfully.")

        } catch (e: Exception) {
            Log.e("TodoWidgetItemFactory", "Failed to initialize encryption: " + e.message, e)
            // Handle error: key/iv will remain null, decryption will fail gracefully.
        }
    }

    private fun decryptText(encryptedBase64: String): String {
        if (key == null || iv == null) {
            Log.w("TodoWidgetItemFactory", "Decryption skipped: key or iv not initialized.")
            return "[Encryption not initialized]"
        }
        if (!encryptedBase64.startsWith("ENC:")) {
             return encryptedBase64 // Not encrypted
        }
        val actualEncryptedBase64 = encryptedBase64.substring(4)

        return try {
            val cipher = Cipher.getInstance(AES_MODE)
            cipher.init(Cipher.DECRYPT_MODE, key, iv)
            val encryptedBytes = Base64.getDecoder().decode(actualEncryptedBase64)
            val decryptedBytes = cipher.doFinal(encryptedBytes)
            String(decryptedBytes, Charsets.UTF_8)
        } catch (e: Exception) {
            Log.e("TodoWidgetItemFactory", "Decryption failed for string: $actualEncryptedBase64", e)
            "[Decryption Error]"
        }
    }

    override fun onDataSetChanged() {
        // This is called when notifyAppWidgetViewDataChanged is called
        loadTodoData()
    }

    override fun onDestroy() {
        todoItems = emptyList()
    }

    override fun getCount(): Int {
        return todoItems.size
    }

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.todo_widget_list_item) // Create this layout file
        if (position < todoItems.size) {
            val item = todoItems[position]
            views.setTextViewText(R.id.widget_item_text, item.first)
            // Add logic to show a checkmark or different style for completed items if item.second is true
             if (item.second) { // isChecked
                views.setInt(R.id.widget_item_text, "setPaintFlags", android.graphics.Paint.STRIKE_THRU_TEXT_FLAG or android.graphics.Paint.ANTI_ALIAS_FLAG)
            } else {
                views.setInt(R.id.widget_item_text, "setPaintFlags", android.graphics.Paint.ANTI_ALIAS_FLAG)
            }

            // Set fill-in intent for item click
            val fillInIntent = Intent()
            // Pass data specific to the clicked item.
            // For example, the todo text or an ID if you have one.
            // This data will be added to the base PendingIntent defined in TodoWidgetProvider.
            val todoText = item.first // Assuming item is Pair<String, Boolean>
            fillInIntent.putExtra("todo_text", todoText)
            // You might want to add a unique ID if available to better identify the todo in the app
            // fillInIntent.putExtra("todo_id", /* some unique id for the item */)
            views.setOnClickFillInIntent(R.id.widget_item_text, fillInIntent) // Ensure R.id.widget_item_text is the ID of the clickable element in your list item layout
        }
        return views
    }

    override fun getLoadingView(): RemoteViews? {
        return null // You can return a custom loading view if needed
    }

    override fun getViewTypeCount(): Int {
        return 1
    }

    override fun getItemId(position: Int): Long {
        return position.toLong()
    }

    override fun hasStableIds(): Boolean {
        return true
    }

    private fun loadTodoData() {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        // The key for todo list is "flutter.kAllListSavedPrefs" based on Flutter code.
        // However, EncryptedSharedPreferencesHelper prepends "flutter." to keys.
        // So, the actual key in SharedPreferences might be "flutter.flutter.kAllListSavedPrefs"
        // Let's try the most likely key based on common SharedPreferences usage from Flutter.
        // If EncryptedSharedPreferencesHelper does something unusual, this key might need adjustment.
        var allListJson = prefs.getString("flutter.kAllListSavedPrefs", null)
        Log.d("TodoWidgetService", "Loaded raw JSON: $allListJson")


        if (allListJson == null) {
            // Fallback: try without "flutter." prefix if not found. This depends on how EncryptedSharedPreferencesHelper actually stores it.
            allListJson = prefs.getString("kAllListSavedPrefs", null)
            Log.d("TodoWidgetService", "Fallback Loaded raw JSON: $allListJson")
        }

        val category = loadCategoryForWidget(context, appWidgetId)
        Log.d("TodoWidgetService", "Widget ID: $appWidgetId, Category: $category")


        val items = mutableListOf<Pair<String, Boolean>>()
        if (allListJson != null) {
            try {
                val jsonArray = JSONArray(allListJson)
                for (i in 0 until jsonArray.length()) {
                    val jsonObject = jsonArray.getJSONObject(i)
                    val text = jsonObject.optString("text", "No text")
                    val isChecked = jsonObject.optBoolean("isChecked", false)
                    val isArchived = jsonObject.optBoolean("isArchived", false)
                    val itemCategory = jsonObject.optString("category", null)

                    val decryptedText = decryptText(text) // Use new decryption method

                    if (!isArchived) {
                         if (category == "All" || category == null || category == itemCategory) {
                            items.add(Pair(decryptedText, isChecked))
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e("TodoWidgetService", "Error parsing todo JSON", e)
                items.add(Pair("Error loading todos: " + e.message, false))
            }
        } else {
            items.add(Pair("No todos found or error loading.", false))
        }
         Log.d("TodoWidgetService", "Parsed items for widget $appWidgetId ($category): ${items.size}")
        todoItems = items
    }

    private fun loadCategoryForWidget(context: Context, appWidgetId: Int): String? {
        val prefs = context.getSharedPreferences(TodoWidgetConfigureActivity.PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getString("${TodoWidgetConfigureActivity.PREF_PREFIX_KEY}$appWidgetId", "All") // Default to "All"
    }
}
