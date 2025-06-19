import 'package:encrypt_shared_preferences/provider.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:encrypt/encrypt.dart';
import 'package:flutter_example/models/todo_category.dart'; // Corrected import

class EncryptedSharedPreferencesHelper {
  static late EncryptedSharedPreferences _prefs;
  static const String kCategoriesListPrefs = 'categories_list_prefs';

  /// Initialize the EncryptedSharedPreferences with the given key
  static Future<void> initialize() async {
    final config = await rootBundle.loadString('config/encryption_config.json');
    final jsonConfig = json.decode(config);
    String key = Key.fromUtf8(jsonConfig['key']).base16.substring(0,16);
    await EncryptedSharedPreferences.initialize(key);
    _prefs = EncryptedSharedPreferences.getInstance();
  }

  /// Save a string value to the encrypted shared preferences
  static Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  /// Retrieve a string value from the encrypted shared preferences
  static Future<String?> getString(String key) async {
    return _prefs.getString(key);
  }

  /// Save an integer value to the encrypted shared preferences
  static Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  /// Retrieve an integer value from the encrypted shared preferences
  static Future<int?> getInt(String key) async {
    return _prefs.getInt(key);
  }

  /// Save a boolean value to the encrypted shared preferences
  static Future<void> setBool(String key, bool value) async {
    await _prefs.setBoolean(key, value);
  }

  /// Retrieve a boolean value from the encrypted shared preferences
  static Future<bool?> getBool(String key) async {
    return _prefs.getBoolean(key);
  }

  /// Remove a value from the encrypted shared preferences
  static Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  /// Save a list of categories to the encrypted shared preferences
  static Future<void> saveCategories(List<TodoCategory> categories) async { // Updated type
    final List<Map<String, dynamic>> categoriesJson =
        categories.map((TodoCategory category) => category.toJson()).toList(); // Explicitly typed 'category'
    final String jsonString = json.encode(categoriesJson);
    await setString(kCategoriesListPrefs, jsonString);
  }

  /// Load a list of categories from the encrypted shared preferences
  static Future<List<TodoCategory>> loadCategories() async { // Updated return type
    final String? jsonString = await getString(kCategoriesListPrefs);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> decodedList = json.decode(jsonString);
        return decodedList
            .map((categoryJson) =>
                TodoCategory.fromJson(categoryJson as Map<String, dynamic>)) // Used TodoCategory.fromJson
            .toList();
      } catch (e) {
        print('Error decoding categories from JSON: $e');
        return [];
      }
    }
    return [];
  }
}