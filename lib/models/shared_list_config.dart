import 'package:cloud_firestore/cloud_firestore.dart'; // Correct import for Timestamp

class SharedListConfig {
  String id; // Firestore document ID
  String originalCategoryName;
  String shortLinkPath;
  String adminUserId;
  Map<String, bool> authorizedUserIds; // UID -> true
  Timestamp sharedTimestamp;
  String listNameInSharedCollection;

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
        }
      });
    }

    Timestamp timestamp;
    if (json['sharedTimestamp'] is Timestamp) {
      timestamp = json['sharedTimestamp'] as Timestamp;
    } else if (json['sharedTimestamp'] is String) {
      timestamp = Timestamp.fromDate(DateTime.parse(json['sharedTimestamp'] as String));
    } else if (json['sharedTimestamp'] is Map &&
               json['sharedTimestamp']['_seconds'] is int &&
               json['sharedTimestamp']['_nanoseconds'] is int) {
      // Handling Firestore Timestamp serialized as a map (e.g., from older SDKs or manual JSON)
      timestamp = Timestamp(
        json['sharedTimestamp']['_seconds'] as int,
        json['sharedTimestamp']['_nanoseconds'] as int,
      );
    } else {
      // Fallback or throw error if type is unexpected
      print("Warning: sharedTimestamp is of unexpected type or null. Defaulting to Timestamp.now(). Type was: ${json['sharedTimestamp'].runtimeType}");
      timestamp = Timestamp.now();
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
      // id is not part of the document data itself when saving to Firestore with documentId as name
      'originalCategoryName': originalCategoryName,
      'shortLinkPath': shortLinkPath,
      'adminUserId': adminUserId,
      'authorizedUserIds': authorizedUserIds,
      'sharedTimestamp': sharedTimestamp, // Firestore handles Timestamp serialization
      'listNameInSharedCollection': listNameInSharedCollection,
    };
  }
}
