
import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/services.dart' show rootBundle;

class EncryptionHelper {

  static Key? _key;
  static IV? _iv;

  static Future<void> initialize() async {
    print('[EncryptionHelper] Initializing...');
    final config = await rootBundle.loadString('config/encryption_config.json');
    print('[EncryptionHelper] Loaded config: $config');
    final jsonConfig = json.decode(config);
    _key = Key.fromUtf8(jsonConfig['key']); // Key should be 16, 24, or 32 bytes
    print('[EncryptionHelper] Key initialized: ${_key?.base64}');

    String ivString = jsonConfig['iv'] as String? ?? "default_iv_12345"; // Provide a default if null or not string
    if (ivString.length < 16) {
      ivString = ivString.padRight(16, '0'); // Pad if too short to ensure 16 bytes
    }
    _iv = IV.fromUtf8(ivString.substring(0, 16)); // Use first 16 bytes of the (padded) string
    print('[EncryptionHelper] IV initialized: ${_iv?.base64}');
    print('[EncryptionHelper] Initialization complete.');
  }

  static String encryptText(String text) {
    print('[EncryptionHelper] encryptText called for: "$text"');
    if (_key == null || _iv == null) {
      print('[EncryptionHelper] ERROR: Not initialized before encryptText call!');
      throw Exception('EncryptionHelper not initialized');
    }
    final encrypter = Encrypter(AES(_key!));
    print('[EncryptionHelper] Encrypter created. Key: ${_key?.base64}, IV: ${_iv?.base64}');
    final encrypted = encrypter.encrypt(text, iv: _iv);
    return encrypted.base64;
  }

  static String decryptText(String encryptedText) {
    if (_key == null || _iv == null) {
      throw Exception('EncryptionHelper not initialized');
    }
    final encrypter = Encrypter(AES(_key!));
    final decrypted = encrypter.decrypt64(encryptedText, iv: _iv);
    return decrypted;
  }
}