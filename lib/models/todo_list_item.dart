import 'package:flutter_example/common/encryption_helper.dart';

class TodoListItem {
  String? id; // Added ID field
  String text;

  bool isChecked = false; //todo extract into the widget and out of the model!!!

  DateTime dateTime = DateTime.now();
  bool isArchived = false;
  String? category;

  TodoListItem(this.text, {this.id, this.category}); // Added id to constructor

  bool isEligibleForArchiving() {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    return isChecked && difference.inHours > 24;
    // return isChecked && difference.inMinutes < 2; // todo change this, for debug only
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id, // Added id to toJson
      'text': text.startsWith('ENC:') ? text : 'ENC:' + EncryptionHelper.encryptText(text),
      'isChecked': isChecked,
      'dateTime': dateTime.toIso8601String(),
      'isArchived': isArchived,
      'category': category,
    };
  }

  // Factory constructor updated to optionally accept an ID,
  // useful if the ID is the key in a map rather than part of the value.
  factory TodoListItem.fromJson(Map<String, dynamic> json, {String? idFromKey}) {
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
    return TodoListItem(
      decryptedText,
      id: idFromKey ?? json['id'] as String?, // Use idFromKey if provided, else from json
      category: json['category'] as String?,
    )
      ..isChecked = json['isChecked'] as bool? ?? false
      ..dateTime = DateTime.parse(json['dateTime'] as String? ?? DateTime.now().toIso8601String()) // Provide default for dateTime if missing
      ..isArchived = json['isArchived'] as bool? ?? false;
  }

}