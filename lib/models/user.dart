// lib/models/user.dart
import 'package:firebase_auth/firebase_auth.dart' hide User; // Hide Firebase User to avoid conflict
import 'package:flutter_example/models/todo_list_item.dart';
import 'package:flutter_example/models/shared_list_config.dart'; // For SharedListConfig
import 'package:uuid/uuid.dart';

// Alias FirebaseAuth.User to avoid conflicts if any local 'User' class is in scope
typedef FirebaseAuthUser = firebase_auth.User;

class User {
  String? id; // Firebase UID
  String? email;
  String? profilePictureUrl;
  String? name;
  // This model uses a flat list of todos.
  // The FirebaseRepoInteractor's getTodosForCategory will need to handle filtering by category for personal lists
  // or fetching from a shared list.
  List<TodoListItem> todoListItems;
  DateTime? dateOfRegistration;
  DateTime? dateOfLoginIn;
  List<SharedListConfig> sharedListsConfigs;

  bool newIdsWereAssignedDuringDeserialization = false;

  User({
    this.id,
    this.email,
    this.profilePictureUrl,
    this.name,
    List<TodoListItem>? todoListItems,
    this.dateOfRegistration,
    this.dateOfLoginIn,
    List<SharedListConfig>? sharedListsConfigs,
  }) : this.todoListItems = todoListItems ?? [],
       this.sharedListsConfigs = sharedListsConfigs ?? [];

  static Map<String, dynamic> toJson(User user) {
    return {
      'id': user.id,
      'email': user.email,
      'profilePictureUrl': user.profilePictureUrl,
      'name': user.name,
      'todoListItems': user.todoListItems.map((e) => e.toJson()).toList(),
      'dateOfRegistration': user.dateOfRegistration?.toIso8601String(),
      'dateOfLoginIn': user.dateOfLoginIn?.toIso8601String(),
      // sharedListsConfigs is not typically part of the user's own document
      // They are usually stored in a separate collection and fetched.
      // So, we might not include it in toJson() for the primary user document.
      // However, if it's used for local caching that needs serialization, it could be included.
      // For Firebase Realtime DB, it's fine to include if this is the desired structure.
      'sharedListsConfigs': user.sharedListsConfigs.map((config) => config.toJson()).toList(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json, {String? idFromKey, FirebaseAuthUser? firebaseUser}) {
    final userInstance = User(
      id: idFromKey ?? json['id'] as String? ?? firebaseUser?.uid,
      email: json['email'] as String? ?? firebaseUser?.email,
      profilePictureUrl: json['profilePictureUrl'] as String? ?? firebaseUser?.photoURL,
      name: json['name'] as String? ?? firebaseUser?.displayName,
    );

    userInstance.newIdsWereAssignedDuringDeserialization = false;
    final todoItemsData = json['todoListItems'] as List<dynamic>?;
    if (todoItemsData != null) {
      userInstance.todoListItems = todoItemsData.map((e) {
        final itemJson = Map<String, dynamic>.from(e);
        TodoListItem item = TodoListItem.fromJson(itemJson, idFromKey: itemJson['id'] as String?);
        if (item.id == null) { // Should not happen if TodoListItem constructor assigns ID or if 'id' is in itemJson
          item.id = Uuid().v4();
          userInstance.newIdsWereAssignedDuringDeserialization = true;
        }
        return item;
      }).toList();
    } else {
      userInstance.todoListItems = [];
    }

    userInstance.dateOfRegistration = (json['dateOfRegistration'] != null && json['dateOfRegistration'] != '')
        ? DateTime.parse(json['dateOfRegistration'] as String)
        : firebaseUser?.metadata.creationTime; // Fallback to firebase user metadata
    userInstance.dateOfLoginIn = (json['dateOfLoginIn'] != null && json['dateOfLoginIn'] != '')
        ? DateTime.parse(json['dateOfLoginIn'] as String)
        : firebaseUser?.metadata.lastSignInTime; // Fallback to firebase user metadata

    // sharedListsConfigs are loaded by FirebaseRepoInteractor by querying the shared_lists collection,
    // not directly from the user's document in this fromJson method.
    // Initialize as empty here; interactor will populate it.
    userInstance.sharedListsConfigs = [];
    if (json['sharedListsConfigs'] != null && json['sharedListsConfigs'] is List) {
        userInstance.sharedListsConfigs = (json['sharedListsConfigs'] as List)
            .map((configJson) {
                if (configJson is Map<String, dynamic>) {
                    return SharedListConfig.fromJson(configJson, configJson['id'] as String? ?? Uuid().v4());
                }
                return null;
            })
            .where((config) => config != null)
            .cast<SharedListConfig>()
            .toList();
    }


    return userInstance;
  }
}

extension UserCredentialExtension on UserCredential {
  User toUser({String? name, String? email}) {
    final firebaseUser = this.user;
    if (firebaseUser == null) {
      throw Exception("UserCredential does not contain a user.");
    }
    return User(
      id: firebaseUser.uid,
      email: email ?? firebaseUser.email,
      name: name ?? firebaseUser.displayName,
      profilePictureUrl: firebaseUser.photoURL,
      dateOfRegistration: firebaseUser.metadata.creationTime,
      dateOfLoginIn: firebaseUser.metadata.lastSignInTime,
      todoListItems: [], // Initialize with empty list
      sharedListsConfigs: [], // Initialize with empty list
    );
  }
}