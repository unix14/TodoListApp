
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_example/models/todo_list_item.dart';

class User {
  final String email;
  final String imageURL;
  final String name;

  List<TodoListItem> todoListItems = [];
  //todo add date of registration
  DateTime? dateOfRegistration/* = DateTime.now()*/;

  //todo add date of login in
  DateTime? dateOfLoginIn;

  User({required this.email, required this.imageURL, required this.name});

  static Map<String, dynamic> toJson(User user) {
    return {
      'email': user.email,
      'imageURL': user.imageURL,
      'name': user.name,
      // 'todoListItems': user.todoListItems.map((e) => TodoListItem.toJson(e)).toList(),
      'dateOfRegistration': user.dateOfRegistration?.toIso8601String(),
      'dateOfLoginIn': user.dateOfLoginIn?.toIso8601String(),
    };
  }

  fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'] as String,
      imageURL: json['imageURL'] as String,
      name: json['name'] as String,
    )
      ..todoListItems = (json['todoListItems'] as List<dynamic>? ?? [])
          .map((e) => TodoListItem.fromJson(e as Map<String, dynamic>))
          .toList()
      ..dateOfRegistration = DateTime.parse(json['dateOfRegistration'] as String? ?? '')
      ..dateOfLoginIn = DateTime.parse(json['dateOfLoginIn'] as String? ?? '');
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