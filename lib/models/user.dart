import 'package:firebase_auth/firebase_auth.dart' hide User; // Hide Firebase's User to avoid conflict
import 'package:flutter_example/models/todo_list_item.dart';
import 'package:flutter_example/models/shared_list_config.dart'; // For sharedListsConfigs
import 'package:uuid/uuid.dart'; // For generating IDs for TodoListItems if needed

class User {
  String? id; // Firebase UID
  String? name;
  String? email;
  String? profilePictureUrl;
  Map<String, List<TodoListItem>> todosByCategories;
  List<SharedListConfig> sharedListsConfigs; // Configurations for lists shared with this user
  bool newIdsWereAssignedDuringDeserialization; // Transient field

  User({
    this.id,
    this.name,
    this.email,
    this.profilePictureUrl,
    Map<String, List<TodoListItem>>? todosByCategories,
    List<SharedListConfig>? sharedListsConfigs,
    this.newIdsWereAssignedDuringDeserialization = false, // Initialize transient field
  })  : todosByCategories = todosByCategories ?? {'All': []},
        sharedListsConfigs = sharedListsConfigs ?? [];

  factory User.fromJson(Map<String, dynamic> json, {String? idFromKey}) {
    bool idsAssigned = false;
    var categories = <String, List<TodoListItem>>{};
    if (json['todosByCategories'] != null) {
      (json['todosByCategories'] as Map<String, dynamic>).forEach((key, value) {
        if (value is List) {
          categories[key] = value.map((itemJson) {
            var item = TodoListItem.fromJson(itemJson as Map<String, dynamic>);
            if (item.id == null) {
              item.id = Uuid().v4(); // Assign UUID if ID is missing
              idsAssigned = true;
            }
            return item;
          }).toList();
        }
      });
    } else {
      categories['All'] = [];
    }

    var configs = <SharedListConfig>[];
    if (json['sharedListsConfigs'] != null && json['sharedListsConfigs'] is List) {
      configs = (json['sharedListsConfigs'] as List)
          .map((configJson) => SharedListConfig.fromJson(configJson as Map<String, dynamic>, configJson['id'] as String? ?? Uuid().v4()))
          // Ensure ID is passed to SharedListConfig.fromJson if it expects one for documentId
          .toList();
    }

    return User(
      id: idFromKey ?? json['id'] as String?, // Prioritize idFromKey (e.g. Firebase UID)
      name: json['name'] as String?,
      email: json['email'] as String?,
      profilePictureUrl: json['profilePictureUrl'] as String?,
      todosByCategories: categories,
      sharedListsConfigs: configs,
      newIdsWereAssignedDuringDeserialization: idsAssigned,
    );
  }

  Map<String, dynamic> toJson() {
    var categoriesJson = <String, dynamic>{};
    todosByCategories.forEach((key, value) {
      categoriesJson[key] = value.map((item) => item.toJson()).toList();
    });

    return {
      'id': id, // Include ID in JSON if it's managed this way (e.g. for non-Firebase storage)
      'name': name,
      'email': email,
      'profilePictureUrl': profilePictureUrl,
      'todosByCategories': categoriesJson,
      'sharedListsConfigs': sharedListsConfigs.map((config) => config.toJson()).toList(),
      // newIdsWereAssignedDuringDeserialization is transient and typically not serialized
    };
  }
}

extension UserCredentialExtension on UserCredential {
  AppUser.User toUser({String? name, String? email}) { // Ensure AppUser.User is used here if User is ambiguous
    return AppUser.User(
      id: this.user?.uid, // Get UID from Firebase UserCredential
      name: name ?? this.user?.displayName,
      email: email ?? this.user?.email,
      profilePictureUrl: this.user?.photoURL,
      todosByCategories: {'All': []}, // Default initial todos
      sharedListsConfigs: [], // Default initial shared lists
    );
  }
}