// lib/models/todo_list_item.dart
import 'package:flutter_example/common/encryption_helper.dart';
import 'package:uuid/uuid.dart'; // For default ID if needed during construction

class TodoListItem {
  String? id; // Should be populated from Firebase key or generated via UUID
  String text;
  bool isChecked;
  DateTime dateTime; // Represents creation date and last update time for checked status
  bool isArchived;
  String? category;

  TodoListItem(this.text, {String? id, this.category, DateTime? dateTime, bool? isChecked, bool? isArchived})
      : this.id = id ?? Uuid().v4(), // Ensure ID if not provided
        this.dateTime = dateTime ?? DateTime.now(),
        this.isChecked = isChecked ?? false,
        this.isArchived = isArchived ?? false;

  bool isEligibleForArchiving() {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    // Example: Archive if checked and older than 1 day (or 24 hours)
    return isChecked && difference.inDays > 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, // Persist ID
      'text': text.startsWith('ENC:') ? text : 'ENC:' + EncryptionHelper.encryptText(text),
      'isChecked': isChecked,
      'dateTime': dateTime.toIso8601String(),
      'isArchived': isArchived,
      'category': category,
    };
  }

  factory TodoListItem.fromJson(Map<String, dynamic> json, {String? idFromKey}) {
    String decryptedText;
    String jsonText = json['text'] as String? ?? ''; // Handle null text from DB
    if (jsonText.startsWith('ENC:')) {
      try {
        decryptedText = EncryptionHelper.decryptText(jsonText.substring(4));
      } catch (e) {
        decryptedText = jsonText; // Fallback if decryption fails
        print("Failed to decrypt text: ${jsonText.substring(4)}");
      }
    } else {
      decryptedText = jsonText;
    }

    return TodoListItem(
      decryptedText,
      id: idFromKey ?? json['id'] as String?, // Prioritize idFromKey (Firebase key)
      isChecked: json['isChecked'] as bool? ?? false,
      dateTime: json['dateTime'] != null ? DateTime.parse(json['dateTime'] as String) : DateTime.now(),
      isArchived: json['isArchived'] as bool? ?? false,
      category: json['category'] as String?,
    );
  }
}