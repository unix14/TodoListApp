import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt_shared_preferences/encrypt_shared_preferences.dart'; // Corrected import

class EncryptedSharedPreferencesHelper {
  static late EncryptSharedPref _preferences; // Changed to EncryptSharedPref
  static const String _encryptionKey = "MAKV2SPbnx9Pk4x2ftT9qr8rYxZ8nQ4A"; // Example key, use a secure, persistent key

  static Future<void> initialize() async {
    // Initialize with a specific key. This key should be securely stored and managed.
    // For simplicity, it's hardcoded here, but in a real app, consider fetching it from a secure location.
    _preferences = EncryptSharedPref(password: _encryptionKey); // Use the constructor
    // No need to await _preferences.init() as per package docs for encrypt_shared_preferences
  }

  // Example method to save a string
  static Future<bool> saveString(String key, String value) async {
    return await _preferences.setString(key, value);
  }

  // Example method to get a string
  static Future<String?> getString(String key) async {
    // The package handles decryption automatically upon read.
    return await _preferences.getString(key);
  }

  // Example method to save a boolean
  static Future<bool> saveBool(String key, bool value) async {
    return await _preferences.setBool(key, value);
  }

  // Example method to get a boolean
  static Future<bool?> getBool(String key) async {
    return await _preferences.getBool(key);
  }

  // Example method to save an integer
  static Future<bool> saveInt(String key, int value) async {
    return await _preferences.setInt(key, value);
  }

  // Example method to get an integer
  static Future<int?> getInt(String key) async {
    return await _preferences.getInt(key);
  }

  // Example method to remove a value
  static Future<bool> remove(String key) async {
    return await _preferences.remove(key);
  }

  // Example method to clear all values (use with caution)
  static Future<bool> clearAll() async {
    return await _preferences.clear();
  }

  // Add more methods as needed for other data types (double, stringList, etc.)
  // Example for StringList:
  static Future<bool> saveStringList(String key, List<String> value) async {
    return await _preferences.setStringList(key, value);
  }

  static Future<List<String>?> getStringList(String key) async {
    return await _preferences.getStringList(key);
  }
}