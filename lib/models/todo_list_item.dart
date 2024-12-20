import 'package:flutter_example/common/encryption_helper.dart';

class TodoListItem {

  String text;

  bool isChecked = false; //todo extract into the widget and out of the model!!!

  DateTime dateTime = DateTime.now();
  bool isArchived = false;

  TodoListItem(this.text);

  bool isEligibleForArchiving() {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    return isChecked && difference.inHours > 24;
    // return isChecked && difference.inMinutes < 2; // todo change this, for debug only
  }


  Map<String, dynamic> toJson() {
    return {
      'text': EncryptionHelper.encryptText(text),
      'isChecked': isChecked,
      'dateTime': dateTime.toIso8601String(),
      'isArchived': isArchived,
    };
  }

  factory TodoListItem.fromJson(Map<String, dynamic> json) {
    String decryptedText;
    try {
      decryptedText = EncryptionHelper.decryptText(json['text'] as String);
    } catch (e) {
      // If decryption fails, assume the text is not encrypted
      decryptedText = json['text'] as String;
    }
    return TodoListItem(decryptedText)
      ..isChecked = json['isChecked'] as bool? ?? false
      ..dateTime = DateTime.parse(json['dateTime'] as String? ?? '')
      ..isArchived = json['isArchived'] as bool? ?? false;
  }

}