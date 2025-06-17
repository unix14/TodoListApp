import 'package:flutter_example/common/encryption_helper.dart';

class TodoListItem {

  String text;

  bool isChecked = false; //todo extract into the widget and out of the model!!!

  DateTime dateTime = DateTime.now();
  bool isArchived = false;
  String? category;

  TodoListItem(this.text, {this.category});

  bool isEligibleForArchiving() {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    return isChecked && difference.inHours > 24;
    // return isChecked && difference.inMinutes < 2; // todo change this, for debug only
  }


  Map<String, dynamic> toJson() {
    return {
      'text': text.startsWith('ENC:') ? text : 'ENC:' + EncryptionHelper.encryptText(text),
      'isChecked': isChecked,
      'dateTime': dateTime.toIso8601String(),
      'isArchived': isArchived,
      'category': category,
    };
  }

  factory TodoListItem.fromJson(Map<String, dynamic> json) {
    String decryptedText;
    String text = json['text'] as String;
    if (text.startsWith('ENC:')) {
      try {
        decryptedText = EncryptionHelper.decryptText(text.substring(4));
      } catch (e) {
        // If decryption fails, assume the text is not encrypted
        decryptedText = text;
        print("Failed to decrypt text: ${text.substring(4)}");
      }
    } else {
      decryptedText = text;
    }
    return TodoListItem(decryptedText)
      ..isChecked = json['isChecked'] as bool? ?? false
      ..dateTime = DateTime.parse(json['dateTime'] as String? ?? '')
      ..isArchived = json['isArchived'] as bool? ?? false
      ..category = json['category'] as String?;
  }

}