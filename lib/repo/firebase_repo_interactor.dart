
import 'package:flutter_example/common/globals.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_example/models/todo_list_item.dart';
import 'dart:math'; // Added for random suffix
import 'package:uuid/uuid.dart'; // Added for unique IDs if needed & random suffix

import 'package:flutter_example/models/shared_list_config.dart';
import 'package:flutter_example/common/consts.dart';
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

  // Updated to fetch by userId and include shared list configurations
  Future<MyUser.User?> getUserData(String userId) async {
    final userPath = '$kDBPathUsers/$userId';
    // Use getDataFromFullPath as userPath is a full path
    var userResult = await _firebaseRepo.getDataFromFullPath(userPath);

    MyUser.User? user;
    if (userResult.isNotEmpty) {
      // Pass userId as idFromKey to ensure User object gets its ID
      user = MyUser.User.fromJson(Map<String, dynamic>.from(userResult), idFromKey: userId);
      if (user.newIdsWereAssignedDuringDeserialization == true) { // Null check for user already done by isNotEmpty
        print("User $userId had new TodoListItem IDs assigned during deserialization. Re-saving user data.");
        try {
          await _firebaseRepo.saveData( // Pass full path directly
            userPath,
            MyUser.User.toJson(user), // user is guaranteed non-null here
          );
          user.newIdsWereAssignedDuringDeserialization = false;
          print("Successfully re-saved user data for $userId after ID assignment.");
        } catch (e) {
          print("Error re-saving user $userId after ID assignment: $e");
        }
      }
    } else {
      return null;
    }

    try {
      // Fetch all shared list configs and filter client-side
      final allSharedConfigsMap = await _firebaseRepo.getDataFromFullPath(kDBPathSharedListConfigs);
      List<SharedListConfig> userSharedConfigs = [];

      if (allSharedConfigsMap.isNotEmpty && allSharedConfigsMap is Map) {
        (allSharedConfigsMap as Map<String, dynamic>).forEach((listId, configData) {
          if (configData is Map) {
            // Ensure SharedListConfig.fromJson can handle if configData doesn't have an 'id' field,
            // using listId from the map key.
            final config = SharedListConfig.fromJson(Map<String, dynamic>.from(configData)..putIfAbsent('id', () => listId));
            if (config.authorizedUserIds[userId] == true || config.adminUserId == userId) {
              userSharedConfigs.add(config);
            }
          }
        });
      }
      user?.sharedListsConfigs = userSharedConfigs; // Use null-safe operator
    } catch (e) {
      print("Error fetching shared list configs for user $userId: $e");
      user?.sharedListsConfigs = [];
    }

    // The user object should already be non-null if we reached this point after initial fetch.
    // However, if the initial fetch failed, user would be null.
    // The user object should already be non-null if we reached this point after initial fetch
    // or it would have returned null earlier if userResult was empty.
    return user;
    // The 'else { return null; }' was removed as it was syntactically incorrect here.
    // If userResult was empty, 'user' would be null and would have been returned already.
    // If user deserialization somehow results in a null user (which fromJson shouldn't do if userResult is not empty),
    // then 'user' would be null and returned.
  }

  Future<SharedListConfig?> getSharedListConfigById(String listId) async {
    final result = await _firebaseRepo.getData(listId, kDBPathSharedListConfigs);
    if (result.isNotEmpty) {
      return SharedListConfig.fromJson(Map<String, dynamic>.from(result));
    } else {
      return null;
    }
  }

  Future<SharedListConfig?> getSharedListConfigByPath(String shortLinkPath) async {
    // 1. Look up the list_id from the shared_link_paths node.
    final listIdResult = await _firebaseRepo.getData(shortLinkPath, kDBPathSharedLinkPaths);

    if (listIdResult.isNotEmpty && listIdResult['list_id'] != null) {
      final String listId = listIdResult['list_id'] as String;
      // 2. Fetch the SharedListConfig using the retrieved listId.
      return getSharedListConfigById(listId);
    } else {
      // Path does not exist or doesn't contain a list_id
      return null;
    }
  }

  String _normalizePath(String path) {
    return path.toLowerCase().replaceAll(RegExp(r'\s+'), '-').replaceAll(RegExp(r'[^a-z0-9\-]'), '');
  }

  Future<String> createOrUpdateSharedList({
    required String categoryId, // This will be SharedListConfig.id
    required String categoryName,
    required String adminUserId,
    required String desiredShortLinkPath,
  }) async {
    SharedListConfig? existingConfig;

    // 1. Check for existing share for this categoryId (which is config.id)
    // We assume categoryId is unique enough to be the SharedListConfig ID.
    // The admin check is important if multiple users could theoretically have categories with the same name/ID.
    final potentialExistingConfig = await getSharedListConfigById(categoryId);
    if (potentialExistingConfig != null && potentialExistingConfig.adminUserId == adminUserId) {
      existingConfig = potentialExistingConfig;
      print("Existing config found for categoryId: $categoryId by admin: $adminUserId");
    }

    // 2. Handle Short Link Path
    String finalShortLinkPath;
    String normalizedDesiredPath = _normalizePath(desiredShortLinkPath.isEmpty ? categoryName : desiredShortLinkPath);

    if (normalizedDesiredPath.isEmpty) { // Fallback if categoryName was also empty or only special chars
        normalizedDesiredPath = Uuid().v4().substring(0, 8);
    }

    // Uniqueness Check (Simplified for now - full loop in next step)
    // In a real scenario, this needs a loop if the first attempt with suffix is also taken.
    final pathData = await _firebaseRepo.getData(normalizedDesiredPath, kDBPathSharedLinkPaths);
    if (pathData.isNotEmpty && (existingConfig == null || pathData['list_id'] != existingConfig.id)) {
      // Path taken by someone else, or by this user but for a different list (should not happen if categoryId is config.id)
      final randomSuffix = Uuid().v4().substring(0, 6);
      finalShortLinkPath = "$normalizedDesiredPath-$randomSuffix";
      print("Path $normalizedDesiredPath taken, trying $finalShortLinkPath");
    } else if (existingConfig != null && existingConfig.shortLinkPath.isNotEmpty && normalizedDesiredPath == existingConfig.shortLinkPath) {
      // Path is the same as the existing one for this config, that's fine.
      finalShortLinkPath = normalizedDesiredPath;
      print("Path $finalShortLinkPath is current path for existing config.");
    }
    else {
      finalShortLinkPath = normalizedDesiredPath;
      print("Path $finalShortLinkPath is available or belongs to current config.");
    }
    // TODO: Add a loop here to ensure uniqueness if the suffixed path is also taken.

    // 3. Prepare SharedListConfig
    SharedListConfig configToSave;
    bool isNewShare = existingConfig == null;

    if (isNewShare) {
      configToSave = SharedListConfig(
        id: categoryId, // Using categoryId as the SharedListConfig's unique ID
        originalCategoryName: categoryName,
        shortLinkPath: finalShortLinkPath,
        adminUserId: adminUserId,
        authorizedUserIds: {adminUserId: true},
        sharedTimestamp: DateTime.now(),
        listNameInSharedCollection: categoryName, // Default to original name
      );
      print("Creating new SharedListConfig with id: ${configToSave.id}");
    } else {
      // Update existing config
      existingConfig.shortLinkPath = finalShortLinkPath; // Update path if it changed
      existingConfig.sharedTimestamp = DateTime.now(); // Update timestamp
      // Note: originalCategoryName and adminUserId should not change for an existing share.
      // authorizedUserIds and listNameInSharedCollection might be updatable elsewhere.
      configToSave = existingConfig;
      print("Updating existing SharedListConfig with id: ${configToSave.id}");
    }

    // 4. Firebase Operations
    // Use a Map for batched writes if underlying repository supports it,
    // otherwise, await them individually. For now, individual awaits.
    bool success = true;
    try {
      await _firebaseRepo.saveData(
        "${kDBPathSharedListConfigs}/${configToSave.id}",
        configToSave.toJson(),
      );

      await _firebaseRepo.saveData(
        "${kDBPathSharedLinkPaths}/${configToSave.shortLinkPath}",
        {'list_id': configToSave.id},
      );
      print("Successfully saved SharedListConfig and link path.");
    } catch (e) {
      print("Error saving shared list config or link path: $e");
      success = false;
      // Depending on error handling strategy, might re-throw or return an error indicator
      throw Exception("Failed to save shared list: $e"); // Or return a specific error code/message
    }

    // 5. First-time share data migration (only if save was successful and it's a new share)
    if (success && isNewShare) {
      print("Starting data migration for new share (id: ${configToSave.id})");
      try {
        final userPath = "$kDBPathUsers/${adminUserId}";
        final userDataMap = await _firebaseRepo.getDataFromFullPath(userPath);

        if (userDataMap.isNotEmpty) {
          // Pass adminUserId as idFromKey to ensure User object gets its ID
          MyUser.User? user = MyUser.User.fromJson(Map<String, dynamic>.from(userDataMap), idFromKey: adminUserId);
          if (user?.todoListItems != null) { // Null-safe access
            final itemsToCopy = user!.todoListItems! // user is non-null here
                .where((item) => item.category == categoryName)
                .toList();

            if (itemsToCopy.isNotEmpty) {
              // B. Copy filtered items to /shared_todos/{config.id}/items/
              // This might involve converting each item to JSON and saving it,
              // possibly under its existing ID or new IDs if the structure demands.
              // For simplicity, let's assume we save them as a list or map of items.
              // If FirebaseRealtimeDatabaseRepository.saveData saves the whole map overwriting,
              // we need to be careful or have a method that sets data under a specific child.
              // Assuming saveData to a path like "shared_todos/listId/items" replaces all items.
              Map<String, dynamic> sharedItemsMap = {};
              for (var item in itemsToCopy) {
                // If TodoListItem has a unique ID, use it. Otherwise, Firebase push IDs will be generated if saved one by one.
                // For simplicity, let's assume TodoListItem.toJson() is what we need.
                // And we'll store them by an ID. If items don't have IDs, Firebase push() would generate them.
                // Let's assume items have an 'id' field or we generate one for the shared copy.
                final itemId = item.id ?? Uuid().v4(); // Assuming item has an id or generate one
                sharedItemsMap[itemId] = item.toJson();
              }
               await _firebaseRepo.saveData(
                 "${kDBPathSharedTodos}/${configToSave.id}/$kDBPathSharedTodosItems",
                 sharedItemsMap,
               );
              print("Copied ${itemsToCopy.length} items to shared list.");
            } else {
              print("No items to copy for category '$categoryName'.");
            }
          } else {
             print("User data or todoListItems is null for user $adminUserId, skipping item copy.");
          }
        } else {
          print("User data not found for admin $adminUserId, cannot copy items.");
        }

        final metadata = {
          'adminUserId': adminUserId,
          'originalCategoryName': categoryName,
          'listNameInSharedCollection': configToSave.listNameInSharedCollection ?? categoryName,
          'sharedTimestamp': DateTime.now().toIso8601String(),
        };
        await _firebaseRepo.saveData(
          "${kDBPathSharedTodos}/${configToSave.id}/$kDBPathSharedTodosMetadata",
          metadata,
        );
        print("Saved metadata for shared list.");

      } catch (e) {
        print("Error during data migration: $e");
        // Potentially roll back previous saves or mark the share as incomplete/failed
        // For now, just log and continue. The main config is saved.
        // Consider re-throwing if this is critical: throw Exception("Data migration failed: $e");
      }
    }

    // 6. Return the shortLinkPath
    return configToSave.shortLinkPath;
  }

  Future<List<TodoListItem>> getTodosForSharedList(String listId) async {
    final fullPath = "${kDBPathSharedTodos}/$listId/$kDBPathSharedTodosItems";
    final itemsMap = await _firebaseRepo.getDataFromFullPath(fullPath);

    if (itemsMap.isNotEmpty && itemsMap is Map) {
       return (itemsMap as Map<String,dynamic>).entries.map((entry) {
        if (entry.value is Map) {
          // Pass entry.key as idFromKey
          return TodoListItem.fromJson(Map<String, dynamic>.from(entry.value as Map), idFromKey: entry.key);
        }
        return null;
      }).where((item) => item != null).cast<TodoListItem>().toList();
    }
    return [];
  }

  Stream<List<TodoListItem>> getTodosStreamForSharedList(String listId) {
    final path = "$kDBPathSharedTodos/$listId/$kDBPathSharedTodosItems";
    // Using direct Firebase SDK call for the stream as per subtask example
    return FirebaseDatabase.instance.ref(path).onValue.map((event) {
      final List<TodoListItem> items = [];
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          // Use the 'idFromKey' parameter in TodoListItem.fromJson
          items.add(TodoListItem.fromJson(Map<String, dynamic>.from(value as Map), idFromKey: key));
        });
      }
      return items;
    });
  }

  Future<void> addTodoToSharedList(String listId, TodoListItem todo) async {
    String todoId = todo.id ?? _firebaseRepo.getNewKey(basePath: "${kDBPathSharedTodos}/$listId/$kDBPathSharedTodosItems");
    todo.id = todoId; // Ensure the todo object has the ID

    final path = "${kDBPathSharedTodos}/$listId/$kDBPathSharedTodosItems/$todoId";
    await _firebaseRepo.saveData(
      path, // path is already full path
      todo.toJson(),
    );
  }

  Future<void> updateTodoInSharedList(String listId, TodoListItem todo) async {
    if (todo.id == null) {
      throw Exception("Todo ID cannot be null for updating.");
    }
    final path = "${kDBPathSharedTodos}/$listId/$kDBPathSharedTodosItems/${todo.id}";
    await _firebaseRepo.saveData(
      path, // path is already full path
      todo.toJson(),
    );
  }

  Future<void> deleteTodoFromSharedList(String listId, String todoId) async {
    final path = "${kDBPathSharedTodos}/$listId/$kDBPathSharedTodosItems/$todoId";
    // Use null data with saveData to delete
    await _firebaseRepo.saveData(
      path, // path is already full path
      null,
    );
  }

  Future<SharedListConfig?> joinSharedList(String shortLinkPath, String currentUserId) async {
    final config = await getSharedListConfigByPath(shortLinkPath);

    if (config != null) {
      // Check if user is neither the admin nor already an authorized user
      if (config.adminUserId != currentUserId && !(config.authorizedUserIds[currentUserId] == true)) {
        print("User $currentUserId is not admin and not in authorizedUserIds. Adding...");
        config.authorizedUserIds[currentUserId] = true;
        try {
          // Save the updated config
          await _firebaseRepo.saveData(
            "${kDBPathSharedListConfigs}/${config.id}",
            config.toJson(),
          );
          print("Successfully updated config for user $currentUserId to join list ${config.id}");
          return config;
        } catch (e) {
          print("Error saving updated SharedListConfig for join: $e");
          // Depending on desired behavior, could return original config, or null, or rethrow
          return null; // Indicate failure to update
        }
      } else {
        // User is admin or already authorized
        print("User $currentUserId is admin or already authorized for list ${config.id}.");
        return config; // Return existing config
      }
    } else {
      print("Shared list config not found for path: $shortLinkPath");
      return null; // Path not found
    }
  }

  Future<List<MyUser.User>> getUsersDetails(List<String> userIds) async {
    List<MyUser.User> userDetailsList = [];
    for (String userId in userIds) {
      final userPath = '$kDBPathUsers/$userId';
      var userResult = await _firebaseRepo.getDataFromFullPath(userPath); // Use getDataFromFullPath
      if (userResult.isNotEmpty) {
        // Pass userId as idFromKey to ensure User object gets its ID
        userDetailsList.add(MyUser.User.fromJson(Map<String, dynamic>.from(userResult), idFromKey: userId));
      } else {
        print("User details not found for UID: $userId");
      }
    }
    return userDetailsList;
  }

  Future<bool> updateSharedListConfig(SharedListConfig config) async {
    try {
      await _firebaseRepo.saveData(
        "${kDBPathSharedListConfigs}/${config.id}",
        config.toJson(),
      );
      print("Successfully updated SharedListConfig id: ${config.id}");
      return true;
    } catch (e) {
      print("Error updating SharedListConfig id ${config.id}: $e");
      return false;
    }
  }
}