// lib/models/todo_list_item.dart
import 'package:flutter_example/common/encryption_helper.dart';
import 'package:uuid/uuid.dart';

class TodoListItem {
  String? id;
  String text;
  bool isChecked;
  DateTime dateTime;
  bool isArchived;
  String? category;

  TodoListItem(this.text, {String? id, this.category, DateTime? dateTime, bool? isChecked, bool? isArchived})
      : this.id = id ?? Uuid().v4(),
        this.dateTime = dateTime ?? DateTime.now(),
        this.isChecked = isChecked ?? false,
        this.isArchived = isArchived ?? false;

  bool isEligibleForArchiving() {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    return isChecked && difference.inDays > 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text.startsWith('ENC:') ? text : 'ENC:' + EncryptionHelper.encryptText(text),
      'isChecked': isChecked,
      'dateTime': dateTime.toIso8601String(),
      'isArchived': isArchived,
      'category': category,
    };
  }

  factory TodoListItem.fromJson(Map<String, dynamic> json, {String? idFromKey}) {
    String decryptedText;
    String jsonText = json['text'] as String? ?? '';
    if (jsonText.startsWith('ENC:')) {
      try {
        decryptedText = EncryptionHelper.decryptText(jsonText.substring(4));
      } catch (e) {
        decryptedText = jsonText;
        print("Failed to decrypt text: ${jsonText.substring(4)}");
      }
    } else {
      decryptedText = jsonText;
    }

    return TodoListItem(
      decryptedText,
      id: idFromKey ?? json['id'] as String?,
      isChecked: json['isChecked'] as bool? ?? false,
      dateTime: json['dateTime'] != null ? DateTime.parse(json['dateTime'] as String) : DateTime.now(),
      isArchived: json['isArchived'] as bool? ?? false,
      category: json['category'] as String?,
    );
  }
}