import 'package:flutter_example/models/shared_list_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Only for Timestamp type if used

void main() {
  group('SharedListConfig Tests', () {
    final DateTime testTimestamp = DateTime.now();
    final String testTimestampIso = testTimestamp.toIso8601String();

    final Map<String, dynamic> sampleJsonFull = {
      'id': 'list123',
      'originalCategoryName': 'Groceries',
      'shortLinkPath': 'groceries-link',
      'adminUserId': 'adminUid1',
      'authorizedUserIds': {'userUid1': true, 'userUid2': true},
      'sharedTimestamp': testTimestampIso,
      'listNameInSharedCollection': 'Shared Groceries',
    };

    final Map<String, dynamic> sampleJsonMinimal = {
      'id': 'list456',
      'originalCategoryName': 'Work Tasks',
      'shortLinkPath': 'work-link',
      'adminUserId': 'adminUid2',
      'authorizedUserIds': {'adminUid2': true},
      'sharedTimestamp': testTimestampIso,
      // listNameInSharedCollection is missing
    };

    // Test with Firebase Timestamp if your fromJson handles it
    final Map<String, dynamic> sampleJsonWithFirebaseTimestamp = {
      'id': 'list789',
      'originalCategoryName': 'Home Projects',
      'shortLinkPath': 'home-projects-link',
      'adminUserId': 'adminUid3',
      'authorizedUserIds': {'adminUid3': true, 'userUid3': true},
      'sharedTimestamp': Timestamp.fromDate(testTimestamp), // Firebase Timestamp
      'listNameInSharedCollection': 'Our Home Projects',
    };


    group('fromJson', () {
      test('should correctly deserialize from full JSON (ISO timestamp)', () {
        final config = SharedListConfig.fromJson(sampleJsonFull);

        expect(config.id, 'list123');
        expect(config.originalCategoryName, 'Groceries');
        expect(config.shortLinkPath, 'groceries-link');
        expect(config.adminUserId, 'adminUid1');
        expect(config.authorizedUserIds, {'userUid1': true, 'userUid2': true});
        // Comparing ISO strings for DateTime is safer for tests if exact object isn't guaranteed
        expect(config.sharedTimestamp.toIso8601String(), testTimestampIso);
        expect(config.listNameInSharedCollection, 'Shared Groceries');
      });

      test('should correctly deserialize from minimal JSON (ISO timestamp)', () {
        final config = SharedListConfig.fromJson(sampleJsonMinimal);

        expect(config.id, 'list456');
        expect(config.originalCategoryName, 'Work Tasks');
        expect(config.shortLinkPath, 'work-link');
        expect(config.adminUserId, 'adminUid2');
        expect(config.authorizedUserIds, {'adminUid2': true});
        expect(config.sharedTimestamp.toIso8601String(), testTimestampIso);
        expect(config.listNameInSharedCollection, isNull);
      });

      test('should correctly deserialize from JSON with Firebase Timestamp', () {
        final config = SharedListConfig.fromJson(sampleJsonWithFirebaseTimestamp);

        expect(config.id, 'list789');
        expect(config.originalCategoryName, 'Home Projects');
        expect(config.shortLinkPath, 'home-projects-link');
        expect(config.adminUserId, 'adminUid3');
        expect(config.authorizedUserIds, {'adminUid3': true, 'userUid3': true});
        // Firestore Timestamp precision might differ slightly from DateTime.now() direct toIso8601String
        // So, compare by re-converting to a common format or by time difference.
        // For simplicity, we check if it's reasonably close or use the same ISO string if input was ISO
        expect(config.sharedTimestamp.millisecondsSinceEpoch, testTimestamp.millisecondsSinceEpoch);
        expect(config.listNameInSharedCollection, 'Our Home Projects');
      });

       test('should handle null authorizedUserIds gracefully', () {
        final jsonWithNullAuth = Map<String, dynamic>.from(sampleJsonMinimal);
        jsonWithNullAuth['authorizedUserIds'] = null;
        final config = SharedListConfig.fromJson(jsonWithNullAuth);
        expect(config.authorizedUserIds, isEmpty);
      });
    });

    group('toJson', () {
      test('should correctly serialize to JSON', () {
        final config = SharedListConfig(
          id: 'list123',
          originalCategoryName: 'Groceries',
          shortLinkPath: 'groceries-link',
          adminUserId: 'adminUid1',
          authorizedUserIds: {'userUid1': true, 'userUid2': true},
          sharedTimestamp: testTimestamp,
          listNameInSharedCollection: 'Shared Groceries',
        );

        final json = config.toJson();

        expect(json['id'], 'list123');
        expect(json['originalCategoryName'], 'Groceries');
        expect(json['shortLinkPath'], 'groceries-link');
        expect(json['adminUserId'], 'adminUid1');
        expect(json['authorizedUserIds'], {'userUid1': true, 'userUid2': true});
        expect(json['sharedTimestamp'], testTimestampIso);
        expect(json['listNameInSharedCollection'], 'Shared Groceries');
      });

      test('should correctly serialize with optional fields null', () {
         final config = SharedListConfig(
          id: 'list456',
          originalCategoryName: 'Work Tasks',
          shortLinkPath: 'work-link',
          adminUserId: 'adminUid2',
          authorizedUserIds: {'adminUid2': true},
          sharedTimestamp: testTimestamp,
          // listNameInSharedCollection is null
        );
        final json = config.toJson();
        expect(json['listNameInSharedCollection'], isNull);
      });
    });
  });
}
