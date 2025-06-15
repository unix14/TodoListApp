
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_example/models/todo_list_item.dart';
import 'package:flutter_example/models/shared_list_config.dart';
import 'package:uuid/uuid.dart'; // Added import

class User {
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

  User({required this.email, required this.imageURL, required this.name, this.profilePictureUrl, List<SharedListConfig>? sharedListsConfigs}) : this.sharedListsConfigs = sharedListsConfigs ?? []; // Updated constructor

  static Map<String, dynamic> toJson(User user) {
    return {
      'email': user.email,
      'imageURL': user.imageURL,
      'name': user.name,
      'profilePictureUrl': user.profilePictureUrl,
      'todoListItems': user.todoListItems?.map((e) => e.toJson()).toList() ?? [],
      'sharedListsConfigs': user.sharedListsConfigs?.map((e) => e.toJson()).toList(), // Added to toJson
      'dateOfRegistration': user.dateOfRegistration?.toIso8601String(),
      'dateOfLoginIn': user.dateOfLoginIn?.toIso8601String(),
    };
  }

  static fromJson(Map<String, dynamic> json) {
    final userInstance = User(
      email: json['email'] as String? ?? '',
      imageURL: json['imageURL'] as String? ?? '',
      name: json['name'] as String? ?? '',
      profilePictureUrl: json['profilePictureUrl'] as String? ?? '',
      // sharedListsConfigs are typically populated at runtime after fetching user,
      // or if they were part of user's own document (which is not the current design for shared lists).
      // Initialize as empty, actual population usually happens in FirebaseRepoInteractor.getUserData()
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
      email: user!.email!,
      imageURL: user!.photoURL!,
      name: user!.displayName!,
    );
  }
}