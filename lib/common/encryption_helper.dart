
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
    _key = Key.fromUtf8(jsonConfig['key']);
    _iv = IV.fromUtf8(jsonConfig['iv']);
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