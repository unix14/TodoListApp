import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as FirebaseAuthLib;
import 'package:flutter_example/models/shared_list_config.dart';
import 'package:flutter_example/models/todo_list_item.dart';
import 'package:flutter_example/models/user.dart' as AppUser;
import 'package:flutter_example/common/consts.dart';
import 'package:flutter_example/repo/firebase_realtime_database_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Required for Timestamp

class FirebaseRepoInteractor {
  final FirebaseRealtimeDatabaseRepository _firebaseRepo = FirebaseRealtimeDatabaseRepository.instance;
  final FirebaseAuthLib.FirebaseAuth _firebaseAuth = FirebaseAuthLib.FirebaseAuth.instance;
  StreamSubscription? _userSubscription; // To manage user data stream if implemented

  FirebaseRepoInteractor._privateConstructor();
  static final FirebaseRepoInteractor _instance = FirebaseRepoInteractor._privateConstructor();
  static FirebaseRepoInteractor get instance => _instance;

  // For testing purposes, allow injecting a mock.
  static FirebaseRealtimeDatabaseRepository? _testDbInstance;
  static void setTestDbInstance(FirebaseRealtimeDatabaseRepository dbInstance) {
    _testDbInstance = dbInstance;
  }
  FirebaseRealtimeDatabaseRepository get _db => _testDbInstance ?? FirebaseRealtimeDatabaseRepository.instance;


  Future<AppUser.User?> getUserData(String userId) async {
    final path = '$kDBPathUsers/$userId';
    final data = await _db.getDataFromFullPath(path);
    if (data.isNotEmpty) {
      AppUser.User user = AppUser.User.fromJson(data, idFromKey: userId);

      final allSharedListsData = await _db.getDataFromFullPath(kDBPathSharedListConfigs);
      if (allSharedListsData.isNotEmpty) {
        user.sharedListsConfigs.clear();
        allSharedListsData.forEach((listId, listData) {
          if (listData is Map<String, dynamic>) {
            SharedListConfig config = SharedListConfig.fromJson(listData, listId);
            if (config.adminUserId == userId || (config.authorizedUserIds[userId] == true) ) {
              if (!user.sharedListsConfigs.any((existingConfig) => existingConfig.id == config.id)) {
                 user.sharedListsConfigs.add(config);
              }
            }
          }
        });
      }

      if (user.newIdsWereAssignedDuringDeserialization) {
        await saveUser(user);
        user.newIdsWereAssignedDuringDeserialization = false;
      }
      return user;
    }
    return null;
  }

  Future<void> saveUser(AppUser.User user) async {
    if (user.id == null || user.id!.isEmpty) {
      throw Exception("User ID cannot be null or empty to save user data.");
    }
    final path = '$kDBPathUsers/${user.id}';
    await _db.saveData(path, AppUser.User.toJson(user));
  }

  // Assumes User model has todoListItems (flat list) and TodoListItem has a category field
  Future<List<TodoListItem>> getTodoListItemsForCategory(String userId, String categoryNameOrId) async {
    final user = await getUserData(userId);
    if (user == null) return [];

    // Check if categoryNameOrId refers to a shared list
    final sharedConfig = user.sharedListsConfigs.firstWhere(
        (config) => config.id == categoryNameOrId || config.originalCategoryName == categoryNameOrId, // Check by ID or original name
        orElse: () => SharedListConfig(id: 'error', originalCategoryName: '', shortLinkPath: '', adminUserId: '', authorizedUserIds: {}, sharedTimestamp: Timestamp.now(), listNameInSharedCollection: '')
    );

    if (sharedConfig.id != 'error') { // It's a shared list ID
        return getTodosForSharedList(sharedConfig.id);
    } else { // It's a personal category name
        return user.todoListItems.where((todo) => todo.category == categoryNameOrId).toList();
    }
  }

  Future<SharedListConfig?> getSharedListConfigByPath(String shortLinkPath) async {
    final allConfigsData = await _db.getDataFromFullPath(kDBPathSharedListConfigs);
    if (allConfigsData.isNotEmpty) {
      for (var entry in allConfigsData.entries) {
        final configId = entry.key;
        final configData = entry.value;
        if (configData is Map<String, dynamic> && configData['shortLinkPath'] == shortLinkPath) {
          return SharedListConfig.fromJson(configData, configId);
        }
      }
    }
    return null;
  }

  Future<SharedListConfig?> getSharedListConfigById(String configId) async {
    final path = '$kDBPathSharedListConfigs/$configId';
    final data = await _db.getDataFromFullPath(path);
    if (data.isNotEmpty) {
      return SharedListConfig.fromJson(data, configId);
    }
    return null;
  }

  Future<SharedListConfig> createOrUpdateSharedList({
    required String categoryIdOrName, // For new shares, this is original category name. For existing, it's sharedListConfig.id
    required String listDisplayName, // User-facing name for the list
    required String adminUserId,
    String? desiredShortLinkPath,
    SharedListConfig? existingConfig,
  }) async {
    String shortLink = desiredShortLinkPath?.trim() ?? '';
    if (shortLink.isEmpty) {
      shortLink = listDisplayName.toLowerCase().replaceAll(RegExp(r'\s+'), '-').replaceAll(RegExp(r'[^a-zA-Z0-9-]'), '');
      if (shortLink.length > 20) shortLink = shortLink.substring(0, 20);
      if (shortLink.isEmpty) shortLink = Uuid().v4().substring(0, 8);
    }

    // Sanitize shortLinkPath
    String sanitizedShortLinkPath = shortLink
        .replaceAll('.', '_') // Replace dot with underscore
        .replaceAll('#', '_') // Replace hash with underscore
        .replaceAll('\$', '_') // Replace dollar with underscore
        .replaceAll('[', '_') // Replace open bracket with underscore
        .replaceAll(']', '_'); // Replace close bracket with underscore

    if (sanitizedShortLinkPath.isEmpty) {
        // Generate a random fallback if sanitization results in an empty string
        sanitizedShortLinkPath = Uuid().v4().substring(0, 8);
    }
    shortLink = sanitizedShortLinkPath; // Use the sanitized version

    SharedListConfig configToSave;
    bool isNewShare = existingConfig == null;

    if (isNewShare) {
      SharedListConfig? existingByPath;
      String originalShortLink = shortLink; // Already sanitized
      int attempt = 1;
      do {
        existingByPath = await getSharedListConfigByPath(shortLink); // Use sanitized shortLink for checking
        if (existingByPath != null) {
          shortLink = "$originalShortLink-${attempt++}"; // Append to sanitized original
        }
      } while (existingByPath != null && attempt < 10);
       if (existingByPath != null) {
        shortLink = "$originalShortLink-${Uuid().v4().substring(0,4)}"; // Append to sanitized original
      }

      final newConfigId = _db.getNewKey(basePath: kDBPathSharedListConfigs);
      if (newConfigId == null || newConfigId.isEmpty) throw Exception("Could not generate new key for shared list config.");

      configToSave = SharedListConfig(
        id: newConfigId,
        originalCategoryName: categoryIdOrName, // For new share, categoryIdOrName is the original category name
        shortLinkPath: shortLink,
        adminUserId: adminUserId,
        authorizedUserIds: {adminUserId: true},
        sharedTimestamp: Timestamp.now(),
        listNameInSharedCollection: listDisplayName,
      );

      final adminUser = await getUserData(adminUserId);
      if (adminUser != null) {
        // Using categoryIdOrName as the source category name for personal todos
        final personalTodos = adminUser.todoListItems.where((todo) => todo.category == categoryIdOrName).toList();
        if (personalTodos.isNotEmpty) {
            final sharedTodosPath = '$kDBPathSharedTodos/${configToSave.id}/todos';
            Map<String, dynamic> todosToMigrateJson = {};
            for (var todo in personalTodos) {
                todosToMigrateJson[todo.id!] = todo.toJson(); // Assumes todo.id is not null
            }
            if (todosToMigrateJson.isNotEmpty) {
                await _db.saveData(sharedTodosPath, todosToMigrateJson);
            }
        }
      }
    } else {
      configToSave = existingConfig!;
      if (desiredShortLinkPath != null && desiredShortLinkPath.trim().isNotEmpty && desiredShortLinkPath.trim() != configToSave.shortLinkPath) {
        SharedListConfig? existingByNewPath = await getSharedListConfigByPath(desiredShortLinkPath.trim());
        if (existingByNewPath != null && existingByNewPath.id != configToSave.id) {
          throw Exception("Desired short link path '$desiredShortLinkPath' is already taken.");
        }
        configToSave.shortLinkPath = desiredShortLinkPath.trim();
      }
      configToSave.listNameInSharedCollection = listDisplayName;
      configToSave.sharedTimestamp = Timestamp.now();
    }

    final String configPath = '$kDBPathSharedListConfigs/${configToSave.id}';
    await _db.saveData(configPath, configToSave.toJson());

    final user = await getUserData(adminUserId);
    if (user != null) {
        final index = user.sharedListsConfigs.indexWhere((c) => c.id == configToSave.id);
        if (index != -1) {
            user.sharedListsConfigs[index] = configToSave;
        } else {
            user.sharedListsConfigs.add(configToSave);
        }
        await saveUser(user);
    }

    return configToSave;
  }

  Future<bool> updateSharedListConfig(SharedListConfig config) async {
    try {
      final path = '$kDBPathSharedListConfigs/${config.id}';
      await _db.saveData(path, config.toJson());

      List<String> userIdsToUpdate = config.authorizedUserIds.keys.toList();
      if (!userIdsToUpdate.contains(config.adminUserId)) {
          userIdsToUpdate.add(config.adminUserId);
      }

      for (String userId in userIdsToUpdate) {
          AppUser.User? user = await getUserData(userId);
          if (user != null) {
              int index = user.sharedListsConfigs.indexWhere((c) => c.id == config.id);
              if (index != -1) {
                  user.sharedListsConfigs[index] = config;
              } else {
                  user.sharedListsConfigs.add(config);
              }
              await saveUser(user);
          }
      }
      return true;
    } catch (e) {
      print("Error updating SharedListConfig: $e");
      return false;
    }
  }

  Future<List<TodoListItem>> getTodosForSharedList(String sharedListId) async {
    final path = '$kDBPathSharedTodos/$sharedListId/todos';
    final data = await _db.getDataFromFullPath(path);
    if (data.isNotEmpty) {
      return data.entries.map((entry) {
        return TodoListItem.fromJson(entry.value as Map<String, dynamic>, idFromKey: entry.key);
      }).toList();
    }
    return [];
  }

  Stream<List<TodoListItem>> getTodosStreamForSharedList(String sharedListId) {
    final String path = '$kDBPathSharedTodos/$sharedListId/todos';
    return _db.getStream(path).map((data) {
      if (data != null && data.isNotEmpty) {
        return data.entries.map((entry) {
          return TodoListItem.fromJson(entry.value as Map<String, dynamic>, idFromKey: entry.key);
        }).toList();
      }
      return [];
    });
  }

  Future<void> addTodoToSharedList(String sharedListId, TodoListItem todo) async {
    if (todo.id == null || todo.id!.isEmpty) todo.id = Uuid().v4();
    final path = '$kDBPathSharedTodos/$sharedListId/todos/${todo.id}';
    await _db.saveData(path, todo.toJson());
  }

  Future<void> updateTodoInSharedList(String sharedListId, TodoListItem todo) async {
    if (todo.id == null || todo.id!.isEmpty) throw Exception("Todo ID cannot be null for update.");
    final path = '$kDBPathSharedTodos/$sharedListId/todos/${todo.id}';
    await _db.updateData(path, todo.toJson());
  }

  Future<void> deleteTodoFromSharedList(String sharedListId, String todoId) async {
    final path = '$kDBPathSharedTodos/$sharedListId/todos/$todoId';
    await _db.deleteData(path);
  }

  Future<AppUser.User?> joinSharedList(String shortLinkPath) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw Exception("User must be logged in to join a shared list.");
    }

    final config = await getSharedListConfigByPath(shortLinkPath);
    if (config == null) {
      throw Exception("Shared list not found with path: $shortLinkPath");
    }

    if (config.authorizedUserIds[currentUser.uid] != true) {
      config.authorizedUserIds[currentUser.uid] = true;
      config.sharedTimestamp = Timestamp.now();
      await updateSharedListConfig(config);
    }

    return getUserData(currentUser.uid);
  }

  Future<List<AppUser.User>> getUsersDetails(List<String> userIds) async {
    List<AppUser.User> users = [];
    for (String userId in userIds) {
      final user = await getUserData(userId);
      if (user != null) {
        users.add(AppUser.User(id: userId, name: user.name, profilePictureUrl: user.profilePictureUrl, email: user.email));
      } else {
        users.add(AppUser.User(id: userId, name: "Unknown User", email: ""));
      }
    }
    return users;
  }

  void disposeUserSubscription() {
    _userSubscription?.cancel();
    _userSubscription = null;
  }
}