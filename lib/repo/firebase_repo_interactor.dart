
import 'package:flutter_example/common/globals.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_example/models/todo_list_item.dart';
import 'package:flutter_example/repo/firebase_realtime_database_repository.dart';
import 'package:flutter_example/models/user.dart' as MyUser;

class FirebaseRepoInteractor {

  FirebaseRepoInteractor._();
  static final FirebaseRepoInteractor instance = FirebaseRepoInteractor._();

  final FirebaseRealtimeDatabaseRepository _firebaseRepo = FirebaseRealtimeDatabaseRepository.instance;

  Future<bool> updateUserData(MyUser.User listItem) async {
    // listItem.lastUpdateDate = DateTime.now().toString();
    return await _firebaseRepo.saveData("users/${currentUser?.uid ?? "unknown"}", MyUser.User.toJson(listItem));
  }

  Future<MyUser.User?> getUserData(String path) async {
    var result = await _firebaseRepo.getData(path, "users");
    if (result.isNotEmpty) {
      return MyUser.User.fromJson(result);
    } else {
      return null;
    }
  }
}