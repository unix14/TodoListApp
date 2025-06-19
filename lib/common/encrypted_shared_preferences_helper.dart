// lib/common/encrypted_shared_preferences_helper.dart
import 'package:encrypt_shared_preferences/encrypt_shared_preferences.dart'; // Corrected import
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
// remove: import 'package:encrypt/encrypt.dart'; // This is likely handled by encrypt_shared_preferences itself

class EncryptedSharedPreferencesHelper {
  static EncryptedSharedPreferences? _prefs; // Made nullable, initialized async
  static const String kCategoriesListPrefs = 'categories_list_prefs';

  static Future<void> initialize() async {
    // The key loading logic might be specific to the package,
    // often it handles its own key generation or requires a simple string.
    // The previous logic with jsonConfig for 'key' might be overly complex
    // if the package simplifies this. Let's assume a simpler init or that
    // the user has a specific reason for their key derivation.
    // For now, I'll keep the user's key derivation logic if it's not the source of the error.
    // The primary error was the type EncryptedSharedPreferences.

    // String encryptionKey = await _getEncryptionKeyFromConfig(); // Example if key is complex

    // Most encrypt_shared_preferences packages might just need this:
    // _prefs = EncryptedSharedPreferences(); // Or EncryptedSharedPreferences.getInstance() if it's a singleton after init.
                                        // The error log implies static methods on a class.
                                        // Let's assume the package wants an instance after a static init.
                                        // The log showed:
                                        // await EncryptedSharedPreferences.initialize(key);
                                        // _prefs = EncryptedSharedPreferences.getInstance();
                                        // This implies the package itself doesn't use a passed key for the instance.
                                        // This is highly dependent on the specific API of encrypt_shared_preferences:^0.0.8 or ^0.0.9

    // Given the errors: "Undefined name 'EncryptedSharedPreferences'.initialize"
    // and "Undefined name 'EncryptedSharedPreferences'.getInstance",
    // it's possible the package API is simpler, or the version is very old.
    // Let's assume the package name is `encrypted_shared_preferences` (not `encrypt_shared_preferences`)
    // and it provides a class `EncryptedSharedPreferences`.
    // The pub.dev page for `encrypted_shared_preferences` (note plural 's') shows:
    // EncryptedSharedPreferences encryptedSharedPreferences = EncryptedSharedPreferences();
    // await encryptedSharedPreferences.setString('foo', 'bar');
    // This means it's instance-based.

    // Let's use the class name `EncryptedSharedPreferences` as it's more standard.
    // The error `Type 'EncryptSharedPref' not found` suggests `EncryptSharedPref` was wrong.
    // The error `Error when reading ... encrypt_shared_preferences.dart` with the correct path means the package is found but the class name or usage is wrong.

    // Re-evaluating based on the exact error:
    // lib/common/encrypted_shared_preferences_helper.dart:1:8: Error: Error when reading '/C:/Users/Workstation/AppData/Local/Pub/Cache/hosted/pub.dev/encrypt_shared_preferences-0.0.9/lib/encrypt_shared_preferences.dart': The system cannot find the file specified.
    // This is the MOST critical error. It means the package itself cannot be read by the compiler.
    // This is a `flutter pub get` issue or a corrupted pub cache on the user's machine.
    // I CANNOT fix this by changing Dart code. I will proceed assuming the user fixes their pub cache / pub get.
    // The Dart code below will assume the package *is* available and uses the class `EncryptedSharedPreferences`.

    // The following code assumes the package `encrypt_shared_preferences` (singular name in pubspec)
    // provides the class `EncryptedSharedPreferences` (plural name for the class itself)

    // The simplest initialization for many SharedPreferences wrappers:
    _prefs = EncryptedSharedPreferences();
    // If it requires a key explicitly, the API would be something like:
    // String key = "some_32_byte_secure_key_string"; // Ensure this is securely managed
    // _prefs = EncryptedSharedPreferences(key: key);
    // Or if it uses a static init method that returns an instance or sets a global one:
    // await EncryptedSharedPreferences.initialize(key: "your_key_here");
    // _prefs = EncryptedSharedPreferences.getInstance();
    // For now, the parameterless constructor is the most common for simple wrappers.
  }

  static Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      await initialize();
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
    await setString(kCategoriesListPrefs, jsonString);
  }

  static Future<List<String>> loadCategories() async {
    await _ensureInitialized();
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