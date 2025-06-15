import 'package:flutter_example/models/todo_list_item.dart';
import 'package:flutter_example/common/encryption_helper.dart'; // For verifying encryption calls if needed
import 'package:flutter_test/flutter_test.dart';

// Mock or use a predictable version of EncryptionHelper if its internal logic is complex or has external deps.
// For this test, we'll assume direct usage is okay and its methods are deterministic.
// If EncryptionHelper were complex, we might need to refactor it to be injectable or use a test double.

void main() {
  group('TodoListItem Tests', () {
    final DateTime fixedTime = DateTime(2023, 1, 1, 10, 0, 0);
    final String fixedTimeIso = fixedTime.toIso8601String();
    final String rawText = "My Test Todo";
    final String encryptedText = "ENC:${EncryptionHelper.encryptText(rawText)}";

    group('fromJson', () {
      test('should correctly deserialize with id from JSON and encrypted text', () {
        final json = {
          'id': 'todo123',
          'text': encryptedText,
          'isChecked': true,
          'dateTime': fixedTimeIso,
          'isArchived': false,
          'category': 'Work',
        };
        final item = TodoListItem.fromJson(json);

        expect(item.id, 'todo123');
        expect(item.text, rawText); // Expect decrypted text
        expect(item.isChecked, true);
        expect(item.dateTime.toIso8601String(), fixedTimeIso);
        expect(item.isArchived, false);
        expect(item.category, 'Work');
      });

      test('should correctly deserialize with idFromKey and non-encrypted text', () {
        final json = {
          // no 'id' field in json itself
          'text': rawText, // Non-encrypted
          'isChecked': false,
          'dateTime': fixedTimeIso,
          'isArchived': true,
          'category': 'Home',
        };
        final item = TodoListItem.fromJson(json, idFromKey: 'key456');

        expect(item.id, 'key456');
        expect(item.text, rawText);
        expect(item.isChecked, false);
        expect(item.isArchived, true);
        expect(item.category, 'Home');
      });

      test('should handle missing optional fields and default dateTime if missing/null', () {
        final json = {
          'text': rawText,
          // isChecked, dateTime, isArchived, category, id are missing
        };
        final item = TodoListItem.fromJson(json);
        expect(item.id, isNull);
        expect(item.text, rawText);
        expect(item.isChecked, false); // Default
        expect(item.isArchived, false); // Default
        expect(item.category, isNull); // Default
        expect(item.dateTime, isA<DateTime>()); // Should default to DateTime.now() or similar
      });
       test('should handle text that looks encrypted but fails decryption', () {
        final json = {'text': 'ENC:actuallynotencrypted', 'dateTime': fixedTimeIso};
        final item = TodoListItem.fromJson(json);
        // As per current fromJson logic, if decryption fails, it uses the raw "ENC:..." string.
        expect(item.text, 'ENC:actuallynotencrypted');
      });
    });

    group('toJson', () {
      test('should correctly serialize with id and encrypt text', () {
        final item = TodoListItem(rawText, id: 'todo789', category: 'Life')
          ..isChecked = true
          ..dateTime = fixedTime
          ..isArchived = false;

        final json = item.toJson();

        expect(json['id'], 'todo789');
        expect(json['text'], encryptedText); // Expect text to be encrypted
        expect(json['isChecked'], true);
        expect(json['dateTime'], fixedTimeIso);
        expect(json['isArchived'], false);
        expect(json['category'], 'Life');
      });

      test('should correctly serialize with null id and already encrypted text', () {
        // If text is already encrypted (e.g. from DB), toJson shouldn't re-encrypt
        final item = TodoListItem(encryptedText.substring(4)) // Pass raw encrypted part if it's already "encrypted"
          ..id = null // Test null id
          ..isChecked = false
          ..dateTime = fixedTime;

        // Manually set the text to be as if it was already encrypted to test toJson's behavior
        item.text = encryptedText; // Simulate text already being in "ENC:..." format

        final json = item.toJson();

        expect(json['id'], isNull);
        expect(json['text'], encryptedText); // Should not double-encrypt
        expect(json['isChecked'], false);
      });
    });

    group('isEligibleForArchiving', () {
      test('should be true if checked and older than 24 hours', () {
        final item = TodoListItem("Test")
          ..isChecked = true
          ..dateTime = DateTime.now().subtract(Duration(hours: 25));
        expect(item.isEligibleForArchiving(), isTrue);
      });

      test('should be false if not checked', () {
        final item = TodoListItem("Test")
          ..isChecked = false
          ..dateTime = DateTime.now().subtract(Duration(hours: 25));
        expect(item.isEligibleForArchiving(), isFalse);
      });

      test('should be false if checked but not older than 24 hours', () {
        final item = TodoListItem("Test")
          ..isChecked = true
          ..dateTime = DateTime.now().subtract(Duration(hours: 23));
        expect(item.isEligibleForArchiving(), isFalse);
      });
    });
  });
}
