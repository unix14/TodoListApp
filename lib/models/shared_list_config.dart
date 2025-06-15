import 'package:cloud_firestore/cloud_firestore.dart';

class SharedListConfig {
  String id;
  String originalCategoryName;
  String shortLinkPath;
  String adminUserId;
  Map<String, bool> authorizedUserIds;
  DateTime sharedTimestamp;
  String? listNameInSharedCollection;

  SharedListConfig({
    required this.id,
    required this.originalCategoryName,
    required this.shortLinkPath,
    required this.adminUserId,
    required this.authorizedUserIds,
    required this.sharedTimestamp,
    this.listNameInSharedCollection,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalCategoryName': originalCategoryName,
      'shortLinkPath': shortLinkPath,
      'adminUserId': adminUserId,
      'authorizedUserIds': authorizedUserIds,
      'sharedTimestamp': sharedTimestamp.toIso8601String(),
      'listNameInSharedCollection': listNameInSharedCollection,
    };
  }

  factory SharedListConfig.fromJson(Map<String, dynamic> json) {
    return SharedListConfig(
      id: json['id'] as String,
      originalCategoryName: json['originalCategoryName'] as String,
      shortLinkPath: json['shortLinkPath'] as String,
      adminUserId: json['adminUserId'] as String,
      authorizedUserIds: Map<String, bool>.from(json['authorizedUserIds'] ?? {}),
      sharedTimestamp: (json['sharedTimestamp'] is Timestamp)
          ? (json['sharedTimestamp'] as Timestamp).toDate()
          : DateTime.parse(json['sharedTimestamp'] as String),
      listNameInSharedCollection: json['listNameInSharedCollection'] as String?,
    );
  }
}
