// lib/models/shared_list_config.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SharedListConfig {
  String id; // Was not nullable, ensure it's always provided or generated
  String originalCategoryName;
  String shortLinkPath;
  String adminUserId;
  Map<String, bool> authorizedUserIds;
  Timestamp sharedTimestamp; // Use Timestamp directly
  String? listNameInSharedCollection;

  SharedListConfig({
    required this.id,
    required this.originalCategoryName,
    required this.shortLinkPath,
    required this.adminUserId,
    Map<String, bool>? authorizedUserIds,
    required this.sharedTimestamp,
    this.listNameInSharedCollection,
  }) : this.authorizedUserIds = authorizedUserIds ?? {};

  factory SharedListConfig.fromJson(Map<String, dynamic> json, String idFromKey) {
    Timestamp timestamp;
    if (json['sharedTimestamp'] is Timestamp) {
      timestamp = json['sharedTimestamp'] as Timestamp;
    } else if (json['sharedTimestamp'] is String) {
      timestamp = Timestamp.fromDate(DateTime.parse(json['sharedTimestamp'] as String));
    } else if (json['sharedTimestamp'] is Map &&
               json['sharedTimestamp']['_seconds'] != null &&
               json['sharedTimestamp']['_nanoseconds'] != null) {
      timestamp = Timestamp(
          json['sharedTimestamp']['_seconds'] as int,
          json['sharedTimestamp']['_nanoseconds'] as int);
    } else {
      timestamp = Timestamp.now(); // Fallback
    }

    return SharedListConfig(
      id: idFromKey, // Use the key from Firebase as the ID
      originalCategoryName: json['originalCategoryName'] as String? ?? '',
      shortLinkPath: json['shortLinkPath'] as String? ?? '',
      adminUserId: json['adminUserId'] as String? ?? '',
      authorizedUserIds: Map<String, bool>.from(json['authorizedUserIds'] as Map? ?? {}),
      sharedTimestamp: timestamp,
      listNameInSharedCollection: json['listNameInSharedCollection'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // 'id': id, // ID is the Firebase key, not usually stored in the document itself
      'originalCategoryName': originalCategoryName,
      'shortLinkPath': shortLinkPath,
      'adminUserId': adminUserId,
      'authorizedUserIds': authorizedUserIds,
      'sharedTimestamp': sharedTimestamp, // Store as Timestamp
      'listNameInSharedCollection': listNameInSharedCollection,
    };
  }
}
