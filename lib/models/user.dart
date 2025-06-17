
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_example/models/todo_list_item.dart';
import 'package:flutter_example/models/shared_list_config.dart';
import 'package:uuid/uuid.dart';

class User {
  String? id; // Added field for Firebase UID
  String? email;
  String? imageURL;
  String? name;
  String? profilePictureUrl;

  List<TodoListItem>? todoListItems;
  List<SharedListConfig> sharedListsConfigs = [];

  // Transient field, not part of JSON
  bool newIdsWereAssignedDuringDeserialization = false;

  DateTime? dateOfRegistration/* = DateTime.now()*/;

  //todo add date of login in
  DateTime? dateOfLoginIn;

  User({this.id, required this.email, required this.imageURL, required this.name, this.profilePictureUrl, List<SharedListConfig>? sharedListsConfigs}) : this.sharedListsConfigs = sharedListsConfigs ?? [];

  static Map<String, dynamic> toJson(User user) {
    return {
      'id': user.id, // Added to toJson
      'email': user.email,
      'imageURL': user.imageURL,
      'name': user.name,
      'profilePictureUrl': user.profilePictureUrl,
      'todoListItems': user.todoListItems?.map((e) => e.toJson()).toList() ?? [],
      'sharedListsConfigs': user.sharedListsConfigs.map((e) => e.toJson()).toList(), // Ensure not null before map
      'dateOfRegistration': user.dateOfRegistration?.toIso8601String(),
      'dateOfLoginIn': user.dateOfLoginIn?.toIso8601String(),
    };
  }

  static fromJson(Map<String, dynamic> json, {String? idFromKey}) { // Allow passing ID from key if not in map
    final userInstance = User(
      id: idFromKey ?? json['id'] as String?, // Populate id
      email: json['email'] as String? ?? '',
      imageURL: json['imageURL'] as String? ?? '',
      name: json['name'] as String? ?? '',
      profilePictureUrl: json['profilePictureUrl'] as String? ?? '',
      sharedListsConfigs: (json['sharedListsConfigs'] as List<dynamic>?)
          ?.map((e) => SharedListConfig.fromJson(Map<String, dynamic>.from(e)))
          .toList() ?? [],
    );

    userInstance.newIdsWereAssignedDuringDeserialization = false; // Initialize transient field

    final todoItemsData = json['todoListItems'] as List<dynamic>?;
    if (todoItemsData != null) {
      userInstance.todoListItems = todoItemsData.map((e) {
        final itemJson = Map<String, dynamic>.from(e);
        // Assuming TodoListItem.fromJson can take an optional idFromKey,
        // but for embedded items, there's no external key.
        // ID should come from itemJson['id'] or be null.
        TodoListItem item = TodoListItem.fromJson(itemJson);
        if (item.id == null) {
          item.id = Uuid().v4();
          userInstance.newIdsWereAssignedDuringDeserialization = true;
        }
        return item;
      }).toList();
    } else {
      userInstance.todoListItems = [];
    }

    userInstance.dateOfRegistration =  (json['dateOfRegistration'] != null && json['dateOfRegistration'] != '')
          ? DateTime.parse(json['dateOfRegistration'] as String)
          : null;
    userInstance.dateOfLoginIn = (json['dateOfLoginIn'] != null && json['dateOfLoginIn'] != '')
          ? DateTime.parse(json['dateOfLoginIn'] as String)
          : null;

    return userInstance;
  }





}


extension UserCredentialExtension on UserCredential {
  User toUser() {
    return User(
      id: this.user!.uid, // Pass UID to the new id field
      email: this.user!.email!,
      imageURL: this.user!.photoURL ?? '', // Handle null photoURL
      name: this.user!.displayName ?? '', // Handle null displayName
      profilePictureUrl: this.user!.photoURL, // Can also be used for profilePictureUrl initially
    );
  }
}