import 'package:flutter_example/models/user.dart' as AppUser;
import 'package:flutter_example/models/todo_list_item.dart';
import 'package:flutter_example/models/shared_list_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppUser.User Tests', () {
    final DateTime testRegDate = DateTime.now().subtract(Duration(days: 5));
    final String testRegDateIso = testRegDate.toIso8601String();
    final DateTime testLoginDate = DateTime.now();
    final String testLoginDateIso = testLoginDate.toIso8601String();

    final Map<String, dynamic> sampleJsonFull = {
      'email': 'test@example.com',
      'imageURL': 'https://example.com/image.png',
      'name': 'Test User',
      'profilePictureUrl': 'https://example.com/profile.png',
      'todoListItems': [
        {'text': 'ENC:todo1_encrypted', 'isChecked': false, 'dateTime': testRegDateIso, 'isArchived': false, 'category': 'Work', 'id': 't1'},
      ],
      'sharedListsConfigs': [
        {
          'id': 'sharedList1',
          'originalCategoryName': 'Shared Groceries',
          'shortLinkPath': 'shared-groceries',
          'adminUserId': 'admin1',
          'authorizedUserIds': {'admin1': true, 'user1': true},
          'sharedTimestamp': testLoginDateIso,
          'listNameInSharedCollection': 'Our Groceries'
        }
      ],
      'dateOfRegistration': testRegDateIso,
      'dateOfLoginIn': testLoginDateIso,
    };

    final Map<String, dynamic> sampleJsonMinimal = {
      'email': 'minimal@example.com',
      'imageURL': '',
      'name': 'Minimal User',
      // profilePictureUrl is null
      // todoListItems is null
      // sharedListsConfigs is null
      // dateOfRegistration is null
      // dateOfLoginIn is null
    };

    group('fromJson', () {
      test('should correctly deserialize from full JSON', () {
        final user = AppUser.User.fromJson(sampleJsonFull);

        expect(user.email, 'test@example.com');
        expect(user.imageURL, 'https://example.com/image.png');
        expect(user.name, 'Test User');
        expect(user.profilePictureUrl, 'https://example.com/profile.png');

        expect(user.todoListItems, isNotNull);
        expect(user.todoListItems!.length, 1);
        // Assuming TodoListItem.fromJson handles decryption and ENC: prefix is not stored in model's text field
        expect(user.todoListItems![0].text, 'todo1_encrypted'); // Or decrypted text if test helper handles it
        expect(user.todoListItems![0].id, 't1');


        expect(user.sharedListsConfigs, isNotNull);
        expect(user.sharedListsConfigs.length, 1);
        expect(user.sharedListsConfigs[0].id, 'sharedList1');
        expect(user.sharedListsConfigs[0].originalCategoryName, 'Shared Groceries');

        expect(user.dateOfRegistration?.toIso8601String(), testRegDateIso);
        expect(user.dateOfLoginIn?.toIso8601String(), testLoginDateIso);
      });

      test('should correctly deserialize from minimal JSON (handling nulls)', () {
        final user = AppUser.User.fromJson(sampleJsonMinimal);

        expect(user.email, 'minimal@example.com');
        expect(user.imageURL, '');
        expect(user.name, 'Minimal User');
        expect(user.profilePictureUrl, ''); // Defaults to empty string if null in JSON

        expect(user.todoListItems, isEmpty); // Defaults to empty list
        expect(user.sharedListsConfigs, isEmpty); // Defaults to empty list

        expect(user.dateOfRegistration, isNull);
        expect(user.dateOfLoginIn, isNull);
      });
    });

    group('toJson', () {
      test('should correctly serialize to JSON with all fields', () {
        final user = AppUser.User(
          email: 'test@example.com',
          imageURL: 'https://example.com/image.png',
          name: 'Test User',
          profilePictureUrl: 'https://example.com/profile.png',
          sharedListsConfigs: [
            SharedListConfig(
                id: 'sharedList1',
                originalCategoryName: 'Shared Groceries',
                shortLinkPath: 'shared-groceries',
                adminUserId: 'admin1',
                authorizedUserIds: {'admin1': true, 'user1': true},
                sharedTimestamp: testLoginDate,
                listNameInSharedCollection: 'Our Groceries'
            )
          ]
        )
          ..todoListItems = [
            TodoListItem('todo1_encrypted', id: 't1', category: 'Work')..dateTime = testRegDate, // Assuming text is already encrypted for toJson
          ]
          ..dateOfRegistration = testRegDate
          ..dateOfLoginIn = testLoginDate;

        final json = AppUser.User.toJson(user);

        expect(json['email'], 'test@example.com');
        expect(json['imageURL'], 'https://example.com/image.png');
        expect(json['name'], 'Test User');
        expect(json['profilePictureUrl'], 'https://example.com/profile.png');

        expect(json['todoListItems'], isNotNull);
        expect(json['todoListItems'].length, 1);
        expect(json['todoListItems'][0]['text'], 'ENC:todo1_encrypted'); // Assuming toJson handles encryption
        expect(json['todoListItems'][0]['id'], 't1');

        expect(json['sharedListsConfigs'], isNotNull);
        expect(json['sharedListsConfigs'].length, 1);
        expect(json['sharedListsConfigs'][0]['id'], 'sharedList1');

        expect(json['dateOfRegistration'], testRegDateIso);
        expect(json['dateOfLoginIn'], testLoginDateIso);
      });

      test('should correctly serialize minimal user (nulls for optional fields)', () {
        final user = AppUser.User(
          email: 'minimal@example.com',
          imageURL: '', // Assuming empty string if not present
          name: 'Minimal User',
          // profilePictureUrl is null by default if not provided
          // sharedListsConfigs is empty list by default
        );
        // todoListItems, dateOfRegistration, dateOfLoginIn are also null initially

        final json = AppUser.User.toJson(user);

        expect(json['email'], 'minimal@example.com');
        expect(json['imageURL'], '');
        expect(json['name'], 'Minimal User');
        expect(json['profilePictureUrl'], isNull); // Or empty string if model defaults it

        expect(json['todoListItems'], isEmpty);
        expect(json['sharedListsConfigs'], isEmpty); // toJson should handle empty list

        expect(json['dateOfRegistration'], isNull);
        expect(json['dateOfLoginIn'], isNull);
      });
    });
  });
}
