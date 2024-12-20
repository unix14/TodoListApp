
import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/services.dart' show rootBundle;

class EncryptionHelper {

  static Key? _key;
  static final _iv = IV.fromLength(16);

  static Future<void> initialize() async {
    final config = await rootBundle.loadString('config/encryption_config.json');
    final jsonConfig = json.decode(config);
    _key = Key.fromUtf8(jsonConfig['key']);
  }

  static String encryptText(String text) {
    if (_key == null) {
      throw Exception('EncryptionHelper not initialized');
    }
    final encrypter = Encrypter(AES(_key!));
    final encrypted = encrypter.encrypt(text, iv: _iv);
    return encrypted.base64;
  }

  static String decryptText(String encryptedText) {
    if (_key == null) {
      throw Exception('EncryptionHelper not initialized');
    }
    final encrypter = Encrypter(AES(_key!));
    final decrypted = encrypter.decrypt64(encryptedText, iv: _iv);
    return decrypted;
  }
}