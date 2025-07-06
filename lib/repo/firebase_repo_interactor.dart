
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

  Future<Map<String, dynamic>> getSharedCategoryData(String slug) async {
    return await _firebaseRepo.getData(slug, 'sharedLists');
  }

  Future<bool> saveSharedCategoryData(String slug, Map<String, dynamic> data) async {
    return await _firebaseRepo.saveData('sharedLists/$slug', data);
  }

  Future<bool> sharedCategorySlugExists(String slug) async {
    final data = await getSharedCategoryData(slug);
    return data.isNotEmpty;
  }

  Future<String> generateUniqueSlug(String categoryName) async {
    String baseSlug = categoryName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    baseSlug = baseSlug.replaceAll(RegExp(r'-+'), '-').replaceAll(RegExp(r'^-|-$'), '');
    if (baseSlug.isEmpty) {
      baseSlug = DateTime.now().millisecondsSinceEpoch.toRadixString(36).substring(0,4);
    }
    String slug = baseSlug;
    int counter = 0;
    while (await sharedCategorySlugExists(slug)) {
      counter++;
      slug = '$baseSlug-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).substring(0,4)}';
      if (counter > 5) break;
    }
    return slug;
  }

  Future<bool> saveSharedCategoryItems(String slug, List<TodoListItem> items) async {
    final map = <String, dynamic>{};
    for (int i = 0; i < items.length; i++) {
      map[i.toString()] = items[i].toJson();
    }
    return await _firebaseRepo.saveData('sharedLists/$slug/items', map);
  }

  Future<List<TodoListItem>> getSharedCategoryItems(String slug) async {
    final data = await _firebaseRepo.getData('items', 'sharedLists/$slug');
    return data.values
        .where((e) => e is Map)
        .map((e) => TodoListItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
  Future<String?> uploadProfileImage(String uid, Uint8List bytes) async {
    try {
      return await FirebaseStorageRepository.instance.uploadProfileImage(uid, bytes);
    } catch (e) {
      print("Error uploading profile image: $e");
      return null;
    }
  }
}
