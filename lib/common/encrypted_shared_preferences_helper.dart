// lib/common/encrypted_shared_preferences_helper.dart
import 'package:encrypt_shared_preferences/encrypt_shared_preferences.dart';
import 'dart:convert';
// Removed: import 'package:flutter/services.dart' show rootBundle;
// Removed: import 'package:encrypt/encrypt.dart';

class EncryptedSharedPreferencesHelper {
  static EncryptedSharedPreferences? _prefs;
  static const String kCategoriesListPrefs = 'categories_list_prefs'; // Keep this if used for categories

  static Future<void> initialize() async {
    // Ensure this matches the actual package's initialization.
    // If the package is `encrypt_shared_preferences` (singular) and provides `EncryptedSharedPreferences` (plural)
    // a simple constructor call is common.
    _prefs = EncryptedSharedPreferences();
  }

  static Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      // This indicates an issue if initialize() from main.dart wasn't called or completed.
      // For robustness in direct calls (though not ideal), re-initialize.
      print("Warning: EncryptedSharedPreferencesHelper used before explicit initialize() from main.dart completed or _prefs is null. Attempting recovery.");
      await initialize();
      if (_prefs == null) {
        // If still null, something is seriously wrong with package init.
        throw Exception("Failed to initialize EncryptedSharedPreferences.");
      }
    }
  }

  static Future<void> setString(String key, String value) async {
    await _ensureInitialized();
    await _prefs!.setString(key, value);
  }

  static Future<String?> getString(String key) async {
    await _ensureInitialized();
    return _prefs!.getString(key);
  }

  static Future<void> setInt(String key, int value) async {
    await _ensureInitialized();
    await _prefs!.setInt(key, value);
  }

  static Future<int?> getInt(String key) async {
    await _ensureInitialized();
    return _prefs!.getInt(key);
  }

  static Future<void> setBool(String key, bool value) async {
    await _ensureInitialized();
    await _prefs!.setBool(key, value);
  }

  static Future<bool?> getBool(String key) async {
    await _ensureInitialized();
    return _prefs!.getBool(key);
  }

  static Future<void> remove(String key) async {
    await _ensureInitialized();
    await _prefs!.remove(key);
  }

  static Future<void> saveCategories(List<String> categories) async {
    await _ensureInitialized();
    final String jsonString = json.encode(categories);
    // Use the class's own setString to ensure _ensureInitialized is called.
    await EncryptedSharedPreferencesHelper.setString(kCategoriesListPrefs, jsonString);
  }

  static Future<List<String>> loadCategories() async {
    await _ensureInitialized();
    // Use the class's own getString.
    final String? jsonString = await EncryptedSharedPreferencesHelper.getString(kCategoriesListPrefs);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> decodedList = json.decode(jsonString);
        return decodedList.map((category) => category.toString()).toList();
      } catch (e) {
        print('Error decoding categories from JSON: $e');
        return [];
      }
    }
    return [];
  }
}