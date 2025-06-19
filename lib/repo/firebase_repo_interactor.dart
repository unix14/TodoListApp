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
  // Use .instance for the singleton, and allow testInstance to be set for testing.
  final FirebaseRealtimeDatabaseRepository _firebaseRepo = FirebaseRealtimeDatabaseRepository.instance;
  final FirebaseAuthLib.FirebaseAuth _firebaseAuth = FirebaseAuthLib.FirebaseAuth.instance;
  StreamSubscription? _userSubscription;

  FirebaseRepoInteractor._privateConstructor();
  static final FirebaseRepoInteractor _instance = FirebaseRepoInteractor._privateConstructor();
  // Provide 'instance' as the public accessor. 'I' could be an internal alias if preferred.
  static FirebaseRepoInteractor get instance => _instance;

  // For testing - this allows injecting a mock/test instance.
  // static FirebaseRepoInteractor? _testInstance; // This was in FirebaseRealtimeDatabaseRepository
  // static void setTestInstance(FirebaseRepoInteractor testInstance) {
  //   _testInstance = testInstance;
  // }
  // static FirebaseRepoInteractor get I => _testInstance ?? _instance;


  Future<AppUser.User?> getUserData(String userId) async {
    final path = '$kDBPathUsers/$userId';
    final data = await _firebaseRepo.getDataFromFullPath(path);
    if (data.isNotEmpty) {
      AppUser.User user = AppUser.User.fromJson(data, idFromKey: userId);

      final allSharedListsData = await _firebaseRepo.getDataFromFullPath(kDBPathSharedListConfigs);
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
    if (user.id == null) throw Exception("User ID cannot be null to save user data.");
    final path = '$kDBPathUsers/${user.id}';
    await _firebaseRepo.saveData(path, user.toJson());
  }

  Future<List<TodoListItem>> getTodosForCategory(String userId, String categoryId) async {
    final user = await getUserData(userId);
    if (user != null) {
        // This part of the logic for User model from Turn 91 (Subtask 50)
        // assumes todosByCategories. This User model (from this subtask) uses todoListItems.
        // This needs to be reconciled. For now, I'll assume the User model provided in THIS subtask
        // which has user.todoListItems directly.
        // If categoryId is "All" or matches user's default, return user.todoListItems.
        // Otherwise, it must be a sharedListId.

        // If the User model changes to todosByCategories, this logic needs to adapt:
        // if (user.todosByCategories.containsKey(categoryId)) {
        //     return user.todosByCategories[categoryId]!;
        // }

        // Assuming current User model with flat todoListItems and categoryId is either "All" (for personal) or a sharedListId
        if (categoryId == "All") { // Or some other identifier for the main personal list
             return user.todoListItems.where((todo) => todo.category == null || todo.category == "All").toList(); // Example filter
        }
        // Fallback to check if categoryId is a sharedListId
        final sharedConfig = user.sharedListsConfigs.firstWhere(
            (config) => config.id == categoryId,
            orElse: () => SharedListConfig(id: 'error', originalCategoryName: '', shortLinkPath: '', adminUserId: '', authorizedUserIds: {}, sharedTimestamp: Timestamp.now(), listNameInSharedCollection: '')
        );
        if (sharedConfig.id != 'error') {
              return getTodosForSharedList(sharedConfig.id);
        }
    }
    return [];
  }

  Future<SharedListConfig?> getSharedListConfigByPath(String shortLinkPath) async {
    final allConfigsData = await _firebaseRepo.getDataFromFullPath(kDBPathSharedListConfigs);
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
    final data = await _firebaseRepo.getDataFromFullPath(path);
    if (data.isNotEmpty) {
      return SharedListConfig.fromJson(data, configId);
    }
    return null;
  }

  Future<SharedListConfig> createOrUpdateSharedList({
    required String categoryId,
    required String categoryName,
    required String adminUserId,
    String? desiredShortLinkPath,
    SharedListConfig? existingConfig,
  }) async {
    String shortLink = desiredShortLinkPath?.trim() ?? '';
    if (shortLink.isEmpty) {
      shortLink = categoryName.toLowerCase().replaceAll(RegExp(r'\s+'), '-').replaceAll(RegExp(r'[^a-zA-Z0-9-]'), '');
      if (shortLink.length > 20) shortLink = shortLink.substring(0, 20);
      if (shortLink.isEmpty) shortLink = Uuid().v4().substring(0, 8);
    }

    SharedListConfig configToSave;
    bool isNewShare = existingConfig == null;

    if (isNewShare) {
      SharedListConfig? existingByPath;
      String originalShortLink = shortLink;
      int attempt = 1;
      do {
        existingByPath = await getSharedListConfigByPath(shortLink);
        if (existingByPath != null) {
          shortLink = "$originalShortLink-${attempt++}";
        }
      } while (existingByPath != null && attempt < 10);
       if (existingByPath != null) {
        shortLink = "$originalShortLink-${Uuid().v4().substring(0,4)}";
      }

      final newConfigId = _firebaseRepo.getNewKey(basePath: kDBPathSharedListConfigs) ?? Uuid().v4();
      configToSave = SharedListConfig(
        id: newConfigId,
        originalCategoryName: categoryId,
        shortLinkPath: shortLink,
        adminUserId: adminUserId,
        authorizedUserIds: {adminUserId: true},
        sharedTimestamp: Timestamp.now(),
        listNameInSharedCollection: categoryName,
      );

      final adminUser = await getUserData(adminUserId);
      // This part assumes user.todoListItems and items have a .category field or are filtered appropriately
      // For the User model in *this* subtask, it's user.todoListItems.
      // The categoryId for a new share IS the original category name.
      if (adminUser != null) {
        final personalTodos = adminUser.todoListItems.where((todo) => todo.category == categoryId).toList();
        if (personalTodos.isNotEmpty) {
            final sharedTodosPath = '$kDBPathSharedTodos/${configToSave.id}/todos';
            Map<String, dynamic> todosToMigrateJson = {};
            for (var todo in personalTodos) {
                // Ensure todo.id is not null; TodoListItem constructor now assigns one if null.
                todosToMigrateJson[todo.id!] = todo.toJson();
            }
            if (todosToMigrateJson.isNotEmpty) {
                await _firebaseRepo.saveData(sharedTodosPath, todosToMigrateJson);
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
      configToSave.listNameInSharedCollection = categoryName;
      configToSave.sharedTimestamp = Timestamp.now();
    }

    final String configPath = '$kDBPathSharedListConfigs/${configToSave.id}';
    await _firebaseRepo.saveData(configPath, configToSave.toJson());

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
      await _firebaseRepo.saveData(path, config.toJson());

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
    final data = await _firebaseRepo.getDataFromFullPath(path);
    if (data.isNotEmpty) {
      return data.entries.map((entry) {
        return TodoListItem.fromJson(entry.value as Map<String, dynamic>, idFromKey: entry.key);
      }).toList();
    }
    return [];
  }

  Stream<List<TodoListItem>> getTodosStreamForSharedList(String sharedListId) {
    final String path = '$kDBPathSharedTodos/$sharedListId/todos';
    return _firebaseRepo.getStream(path).map((data) { // Changed from getDataStream
      if (data != null && data.isNotEmpty) {
        return data.entries.map((entry) {
          return TodoListItem.fromJson(entry.value as Map<String, dynamic>, idFromKey: entry.key);
        }).toList();
      }
      return [];
    });
  }

  Future<void> addTodoToSharedList(String sharedListId, TodoListItem todo) async {
    if (todo.id == null) todo.id = Uuid().v4();
    final path = '$kDBPathSharedTodos/$sharedListId/todos/${todo.id}';
    await _firebaseRepo.saveData(path, todo.toJson());
  }

  Future<void> updateTodoInSharedList(String sharedListId, TodoListItem todo) async {
    if (todo.id == null) throw Exception("Todo ID cannot be null for update.");
    final path = '$kDBPathSharedTodos/$sharedListId/todos/${todo.id}';
    await _firebaseRepo.updateData(path, todo.toJson()); // Use updateData
  }

  Future<void> deleteTodoFromSharedList(String sharedListId, String todoId) async {
    final path = '$kDBPathSharedTodos/$sharedListId/todos/$todoId';
    await _firebaseRepo.deleteData(path); // Use deleteData
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