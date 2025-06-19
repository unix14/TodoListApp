import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as FirebaseAuthLib;
import 'package:flutter_example/models/shared_list_config.dart';
import 'package:flutter_example/models/todo_list_item.dart';
import 'package:flutter_example/models/user.dart' as AppUser;
import 'package:flutter_example/common/consts.dart'; // For kDBPathUsers etc.
import 'firebase_realtime_database_repository.dart';
import 'package:uuid/uuid.dart';

class FirebaseRepoInteractor {
  final FirebaseRealtimeDatabaseRepository _firebaseRepo = FirebaseRealtimeDatabaseRepository.I;
  final FirebaseAuthLib.FirebaseAuth _firebaseAuth = FirebaseAuthLib.FirebaseAuth.instance;
  StreamSubscription? _userSubscription;

  // Private constructor for Singleton pattern
  FirebaseRepoInteractor._privateConstructor();

  // Static instance variable
  static final FirebaseRepoInteractor _instance = FirebaseRepoInteractor._privateConstructor();

  // Public accessor for the instance
  static FirebaseRepoInteractor get instance => _instance;

  // For testing
  static FirebaseRepoInteractor? _testInstance;
  static void setTestInstance(FirebaseRepoInteractor testInstance) {
    _testInstance = testInstance;
  }
  static FirebaseRepoInteractor get I => _testInstance ?? _instance;


  Future<AppUser.User?> getUserData(String userId) async {
    final path = '$kDBPathUsers/$userId';
    final data = await _firebaseRepo.getData(path: path);
    if (data != null) {
      AppUser.User user = AppUser.User.fromJson(data, idFromKey: userId);

      // Fetch SharedListConfigs where user is an admin or authorized
      // This is a simplified approach; ideally, query for lists where user's ID is in authorizedUserIds or is admin.
      // For now, fetching all and filtering client-side (not scalable for many shared lists).
      final allSharedListsData = await _firebaseRepo.getData(path: kDBPathSharedListConfigs);
      if (allSharedListsData != null) {
        allSharedListsData.forEach((listId, listData) {
          if (listData is Map<String, dynamic>) {
            SharedListConfig config = SharedListConfig.fromJson(listData, listId);
            if (config.adminUserId == userId || (config.authorizedUserIds[userId] == true) ) {
              // Check if this config is already in the user's list to avoid duplicates
              if (!user.sharedListsConfigs.any((existingConfig) => existingConfig.id == config.id)) {
                 user.sharedListsConfigs.add(config);
              }
            }
          }
        });
      }

      // If TodoListItem IDs were generated during deserialization, re-save the user object
      if (user.newIdsWereAssignedDuringDeserialization) {
        await saveUser(user);
        user.newIdsWereAssignedDuringDeserialization = false; // Reset flag after saving
      }
      return user;
    }
    return null;
  }

  Future<void> saveUser(AppUser.User user) async {
    if (user.id == null) throw Exception("User ID cannot be null to save user data.");
    final path = '$kDBPathUsers/${user.id}';
    await _firebaseRepo.saveData(path: path, data: user.toJson());
  }

  Future<List<TodoListItem>> getTodosForCategory(String userId, String categoryId) async {
    // This method might need to be re-evaluated based on whether categoryId is a personal category name
    // or a sharedListId. The current User model stores personal todos in todosByCategories.
    final user = await getUserData(userId);
    if (user != null) {
        if (user.todosByCategories.containsKey(categoryId)) {
            return user.todosByCategories[categoryId]!;
        } else {
            // Check if categoryId is a sharedListId
            final sharedConfig = user.sharedListsConfigs.firstWhere((config) => config.id == categoryId, orElse: () => SharedListConfig(id: 'error', originalCategoryName: '', shortLinkPath: '', adminUserId: '', authorizedUserIds: {}, sharedTimestamp: Timestamp.now(), listNameInSharedCollection: ''));
            if (sharedConfig.id != 'error') {
                 return getTodosForSharedList(sharedConfig.id);
            }
        }
    }
    return [];
  }


  Future<SharedListConfig?> getSharedListConfigByPath(String shortLinkPath) async {
    final allConfigsData = await _firebaseRepo.getData(path: kDBPathSharedListConfigs);
    if (allConfigsData != null) {
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
    final data = await _firebaseRepo.getData(path: path);
    if (data != null) {
      return SharedListConfig.fromJson(data, configId);
    }
    return null;
  }

  Future<SharedListConfig> createOrUpdateSharedList({
    required String categoryId, // For new shares, this is original category name. For existing, it's sharedListConfig.id
    required String categoryName, // User-facing name for the list
    required String adminUserId,
    String? desiredShortLinkPath, // Optional user-defined path
    SharedListConfig? existingConfig,
  }) async {
    String shortLink = desiredShortLinkPath?.trim() ?? '';
    if (shortLink.isEmpty) {
      shortLink = categoryName.toLowerCase().replaceAll(RegExp(r'\s+'), '-').replaceAll(RegExp(r'[^a-zA-Z0-9-]'), '');
      if (shortLink.length > 20) shortLink = shortLink.substring(0, 20); // Max length
      if (shortLink.isEmpty) shortLink = Uuid().v4().substring(0, 8); // Fallback if name was all special chars
    }

    SharedListConfig configToSave;
    bool isNewShare = existingConfig == null;

    if (isNewShare) {
      // Ensure shortLink is unique
      SharedListConfig? existingByPath;
      String originalShortLink = shortLink;
      int attempt = 1;
      do {
        existingByPath = await getSharedListConfigByPath(shortLink);
        if (existingByPath != null) {
          shortLink = "$originalShortLink-${attempt++}";
        }
      } while (existingByPath != null);
      // TODO: Add a more robust loop with max attempts for short link generation

      final newConfigId = _firebaseRepo.getNewKey(basePath: kDBPathSharedListConfigs) ?? Uuid().v4();
      configToSave = SharedListConfig(
        id: newConfigId,
        originalCategoryName: categoryId, // categoryId is the original name for a new share
        shortLinkPath: shortLink,
        adminUserId: adminUserId,
        authorizedUserIds: {adminUserId: true},
        sharedTimestamp: Timestamp.now(),
        listNameInSharedCollection: categoryName, // User-facing name
      );

      // Migrate personal todos to the shared list location
      final adminUser = await getUserData(adminUserId);
      if (adminUser != null && adminUser.todosByCategories.containsKey(categoryId)) {
        final personalTodos = adminUser.todosByCategories[categoryId]!;
        final sharedTodosPath = '$kDBPathSharedTodos/${configToSave.id}/todos';
        Map<String, dynamic> todosToMigrateJson = {};
        for (var todo in personalTodos) {
          todosToMigrateJson[todo.id ?? Uuid().v4()] = todo.toJson();
        }
        if (todosToMigrateJson.isNotEmpty) {
          await _firebaseRepo.saveData(path: sharedTodosPath, data: todosToMigrateJson);
        }
        // Optionally, remove from personal list or mark as shared
        // adminUser.todosByCategories.remove(categoryId);
        // await saveUser(adminUser);
      }

    } else { // Existing share, update it
      configToSave = existingConfig!;
      if (desiredShortLinkPath != null && desiredShortLinkPath.trim().isNotEmpty && desiredShortLinkPath.trim() != configToSave.shortLinkPath) {
        // User wants to change the short link path. Ensure new one is unique.
        SharedListConfig? existingByNewPath = await getSharedListConfigByPath(desiredShortLinkPath.trim());
        if (existingByNewPath != null && existingByNewPath.id != configToSave.id) {
          throw Exception("Desired short link path '$desiredShortLinkPath' is already taken.");
        }
        configToSave.shortLinkPath = desiredShortLinkPath.trim();
      }
      configToSave.listNameInSharedCollection = categoryName; // Allow renaming
      configToSave.sharedTimestamp = Timestamp.now(); // Update timestamp
    }

    final String configPath = '$kDBPathSharedListConfigs/${configToSave.id}';
    await _firebaseRepo.saveData(path: configPath, data: configToSave.toJson());

    // Also update the AppUser.User object's sharedListsConfigs
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
      await _firebaseRepo.saveData(path: path, data: config.toJson());

      // Update this config in all authorized users' local User objects
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
                  // This case should ideally not happen if user was already authorized or admin
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
    final data = await _firebaseRepo.getData(path: path);
    if (data != null) {
      return data.entries.map((entry) {
        // Assuming each entry.value is a Map<String, dynamic> for a TodoListItem
        // And entry.key is the TodoListItem's ID
        return TodoListItem.fromJson(entry.value as Map<String, dynamic>, idFromKey: entry.key);
      }).toList();
    }
    return [];
  }

  Stream<List<TodoListItem>> getTodosStreamForSharedList(String sharedListId) {
    final String path = '$kDBPathSharedTodos/$sharedListId/todos';
    return _firebaseRepo.getDataStream(path: path).map((data) {
      if (data != null) {
        return data.entries.map((entry) {
          return TodoListItem.fromJson(entry.value as Map<String, dynamic>, idFromKey: entry.key);
        }).toList();
      }
      return []; // Return empty list if data is null
    });
  }


  Future<void> addTodoToSharedList(String sharedListId, TodoListItem todo) async {
    if (todo.id == null) todo.id = Uuid().v4();
    final path = '$kDBPathSharedTodos/$sharedListId/todos/${todo.id}';
    await _firebaseRepo.saveData(path: path, data: todo.toJson());
  }

  Future<void> updateTodoInSharedList(String sharedListId, TodoListItem todo) async {
    if (todo.id == null) throw Exception("Todo ID cannot be null for update.");
    final path = '$kDBPathSharedTodos/$sharedListId/todos/${todo.id}';
    await _firebaseRepo.updateData(path: path, data: todo.toJson());
  }

  Future<void> deleteTodoFromSharedList(String sharedListId, String todoId) async {
    final path = '$kDBPathSharedTodos/$sharedListId/todos/$todoId';
    await _firebaseRepo.deleteData(path: path);
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

    // Add current user to authorizedUserIds if not already present
    if (config.authorizedUserIds[currentUser.uid] != true) {
      config.authorizedUserIds[currentUser.uid] = true;
      config.sharedTimestamp = Timestamp.now(); // Mark update
      await updateSharedListConfig(config); // This saves the config and updates all users
    }

    // Return the updated local user object
    return getUserData(currentUser.uid);
  }

  Future<List<AppUser.User>> getUsersDetails(List<String> userIds) async {
    List<AppUser.User> users = [];
    for (String userId in userIds) {
      final user = await getUserData(userId); // This already fetches from DB
      if (user != null) {
        users.add(AppUser.User(id: userId, name: user.name, profilePictureUrl: user.profilePictureUrl, email: user.email));
      } else {
        // Add a placeholder for users not found, or handle as error
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