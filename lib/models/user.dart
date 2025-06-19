
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_example/models/todo_list_item.dart';
import 'package:flutter_example/models/todo_category.dart'; // Corrected import

class User {
  String? email;
  String? imageURL;
  String? name;
  List<TodoCategory>? categories; // Updated type

  List<TodoListItem>? todoListItems;

  DateTime? dateOfRegistration/* = DateTime.now()*/;

  //todo add date of login in
  DateTime? dateOfLoginIn;

  User({required this.email, required this.imageURL, required this.name, this.categories});

  static Map<String, dynamic> toJson(User user) {
    return {
      'email': user.email,
      'imageURL': user.imageURL,
      'name': user.name,
      'categories': user.categories?.map((TodoCategory e) => e.toJson()).toList() ?? [], // Explicitly typed 'e'
      'todoListItems': user.todoListItems?.map((e) => e.toJson()).toList() ?? [],
      'dateOfRegistration': user.dateOfRegistration?.toIso8601String(),
      'dateOfLoginIn': user.dateOfLoginIn?.toIso8601String(),
    };
  }

  static fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'] as String? ?? '',
      imageURL: json['imageURL'] as String? ?? '',
      name: json['name'] as String? ?? '',
    )
      ..categories = (json['categories'] as List<dynamic>?)
          ?.map((e) => TodoCategory.fromJson(Map<String, dynamic>.from(e))) // Used TodoCategory.fromJson
          .toList() ?? []
      ..todoListItems = (json['todoListItems'] as List<dynamic>?)
          ?.map((e) => TodoListItem.fromJson(Map<String, dynamic>.from(e)))
          .toList() ?? []

      ..dateOfRegistration =  (json['dateOfRegistration'] != null && json['dateOfRegistration'] != '')
          ? DateTime.parse(json['dateOfRegistration'] as String)
          : null
      ..dateOfLoginIn = (json['dateOfLoginIn'] != null && json['dateOfLoginIn'] != '')
          ? DateTime.parse(json['dateOfLoginIn'] as String)
          : null;
  }





}


extension UserCredentialExtension on UserCredential {
  User toUser() {
    return User(
      email: user!.email!,
      imageURL: user!.photoURL!,
      name: user!.displayName!,
      categories: <TodoCategory>[], // Initialize with empty List<TodoCategory>
    );
  }
}