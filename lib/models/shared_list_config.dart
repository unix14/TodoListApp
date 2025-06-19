import 'package:cloud_firestore/cloud_firestore.dart';

class SharedListConfig {
  String id; // Firestore document ID for this shared list config
  String originalCategoryName; // The original name of the category as the admin knows it
  String shortLinkPath; // The user-facing shareable link path (e.g., "work-todos")
  String adminUserId;
  Map<String, bool> authorizedUserIds; // UID -> true (for easy querying in Firebase rules)
  Timestamp sharedTimestamp; // When the list was initially shared or settings last significantly changed
  String listNameInSharedCollection; // Name of the list as it appears in the shared collection (could be customized by admin)

  SharedListConfig({
    required this.id,
    required this.originalCategoryName,
    required this.shortLinkPath,
    required this.adminUserId,
    required this.authorizedUserIds,
    required this.sharedTimestamp,
    required this.listNameInSharedCollection,
  });

  factory SharedListConfig.fromJson(Map<String, dynamic> json, String documentId) {
    var authorizedUsersMap = <String, bool>{};
    if (json['authorizedUserIds'] is Map) {
      (json['authorizedUserIds'] as Map).forEach((key, value) {
        if (value is bool) {
          authorizedUsersMap[key as String] = value;
        } else if (value is String && (value == 'true' || value == 'false')) { // Handle stringified bools if necessary
          authorizedUsersMap[key as String] = value == 'true';
        }
      });
    } else if (json['authorizedUserIds'] is List) { // Handle older list format if necessary
        for (var userId in (json['authorizedUserIds'] as List)) {
            if (userId is String) {
                authorizedUsersMap[userId] = true;
            }
        }
    }


    Timestamp timestamp;
    if (json['sharedTimestamp'] is Timestamp) {
      timestamp = json['sharedTimestamp'] as Timestamp;
    } else if (json['sharedTimestamp'] is String) {
      timestamp = Timestamp.fromDate(DateTime.parse(json['sharedTimestamp'] as String));
    } else if (json['sharedTimestamp'] is Map &&
               json['sharedTimestamp']['_seconds'] is int &&
               json['sharedTimestamp']['_nanoseconds'] is int) {
      timestamp = Timestamp(
        json['sharedTimestamp']['_seconds'] as int,
        json['sharedTimestamp']['_nanoseconds'] as int,
      );
    }

    else {
      timestamp = Timestamp.now(); // Fallback or throw error
    }

    return SharedListConfig(
      id: documentId,
      originalCategoryName: json['originalCategoryName'] as String? ?? 'Unknown Category',
      shortLinkPath: json['shortLinkPath'] as String? ?? '',
      adminUserId: json['adminUserId'] as String? ?? '',
      authorizedUserIds: authorizedUsersMap,
      sharedTimestamp: timestamp,
      listNameInSharedCollection: json['listNameInSharedCollection'] as String? ?? json['originalCategoryName'] as String? ?? 'Shared List',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // id is not part of the document data itself, it's the document name/ID
      'originalCategoryName': originalCategoryName,
      'shortLinkPath': shortLinkPath,
      'adminUserId': adminUserId,
      'authorizedUserIds': authorizedUserIds, // Store as a map
      'sharedTimestamp': sharedTimestamp, // Store as Timestamp
      'listNameInSharedCollection': listNameInSharedCollection,
    };
  }
}
