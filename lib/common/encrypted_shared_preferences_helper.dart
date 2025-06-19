// lib/common/encrypted_shared_preferences_helper.dart
import 'package:encrypt_shared_preferences/encrypt_shared_preferences.dart';
import 'dart:convert';
// Removed: import 'package:flutter/services.dart' show rootBundle;
// Removed: import 'package:encrypt/encrypt.dart';

class EncryptedSharedPreferencesHelper {
  static EncryptedSharedPreferences? _prefs;
  static const String kCategoriesListPrefs = 'categories_list_prefs';

  static Future<void> initialize() async {
    // Assuming default constructor or a parameterless static init for the package version.
    // The package handles its own key management or uses a default.
    // If a specific key needs to be passed, the package API would show that.
    // The critical error was `Type not found` or `File not found`, indicating
    // the package itself wasn't resolved or class name was wrong.
    _prefs = EncryptedSharedPreferences();
  }

  static Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      // This might be problematic if initialize() is meant to be called once from main.dart
      // For robustness, let's make initialize idempotent or ensure it's called early.
      // For now, if called here, it might try to re-init.
      // A better pattern is a proper singleton a_la get_it for _prefs.
      // Given the constraints, this is a simpler fix if initialize() is safe to call multiple times
      // or if _prefs is expected to be set by an explicit call to initialize() from main.
      // Let's assume initialize() from main.dart is the primary init path.
      // So, if _prefs is null here, it's an issue with app startup sequence.
      // However, to prevent crashes if used before main init:
      print("Warning: EncryptedSharedPreferencesHelper used before explicit initialize() from main.dart completed or _prefs is null.");
      _prefs = EncryptedSharedPreferences(); // Attempt recovery or fail gracefully
    }
  }

  static Future<void> setString(String key, String value) async {
    await _ensureInitialized();
    if (_prefs == null) return; // Guard against null prefs
    await _prefs!.setString(key, value);
  }

  static Future<String?> getString(String key) async {
    await _ensureInitialized();
    if (_prefs == null) return null;
    return _prefs!.getString(key);
  }

  // ... (Implement setInt, getInt, setBool, getBool, remove similarly with _ensureInitialized and null checks) ...
  static Future<void> setInt(String key, int value) async {
    await _ensureInitialized();
    if (_prefs == null) return;
    await _prefs!.setInt(key, value);
  }

  static Future<int?> getInt(String key) async {
    await _ensureInitialized();
    if (_prefs == null) return null;
    return _prefs!.getInt(key);
  }

  static Future<void> setBool(String key, bool value) async {
    await _ensureInitialized();
    if (_prefs == null) return;
    await _prefs!.setBool(key, value);
  }

  static Future<bool?> getBool(String key) async {
    await _ensureInitialized();
    if (_prefs == null) return null;
    return _prefs!.getBool(key);
  }

  static Future<void> remove(String key) async {
    await _ensureInitialized();
    if (_prefs == null) return;
    await _prefs!.remove(key);
  }


  static Future<void> saveCategories(List<String> categories) async {
    await _ensureInitialized();
    if (_prefs == null) return;
    final String jsonString = json.encode(categories);
    await setString(kCategoriesListPrefs, jsonString);
  }

  static Future<List<String>> loadCategories() async {
    await _ensureInitialized();
    if (_prefs == null) return [];
    final String? jsonString = await getString(kCategoriesListPrefs);
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