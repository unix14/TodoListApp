// lib/repo/firebase_realtime_database_repository.dart
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class FirebaseRealtimeDatabaseRepository {
  FirebaseRealtimeDatabaseRepository._internal(); // Private constructor for singleton
  static final FirebaseRealtimeDatabaseRepository _instance = FirebaseRealtimeDatabaseRepository._internal();
  // Public accessor for the instance - changed to 'instance' from 'I' for consistency with older versions if any existed
  static FirebaseRealtimeDatabaseRepository get instance => _testInstance ?? _instance;


  // Optional: For testing, allow replacing the instance
  static FirebaseRealtimeDatabaseRepository? _testInstance;
  // static set testInstance(FirebaseRealtimeDatabaseRepository? instance) { // Setter for testInstance
  //   _testInstance = instance;
  // }
  // Use this to get the current instance (real or test)
  static FirebaseRealtimeDatabaseRepository get current { // Changed from I to current for clarity
    return _testInstance ?? _instance;
  }
   // Method to set a test instance, if needed for testing.
  static void setTestInstance(FirebaseRealtimeDatabaseRepository testInstance) { // Added explicit setter
    _testInstance = testInstance;
  }


  Future<bool> saveData(String fullPath, Map<String, dynamic>? dataToSave) async {
    DatabaseReference reference = FirebaseDatabase.instance.ref(fullPath);
    try {
      if (dataToSave == null) { // Handle null dataToSave as a delete operation
        await reference.remove();
        print('Data deleted successfully at $fullPath');
      } else {
        await reference.set(dataToSave);
        print('Data saved successfully to $fullPath');
      }
      return true;
    } catch (error) {
      print('Failed to save/delete data at $fullPath: $error. Data: $dataToSave');
      return false;
    }
  }

  Future<Map<String, dynamic>> getData(String nodeKey, String collectionPath) async {
    final reference = FirebaseDatabase.instance.ref(collectionPath).child(nodeKey);
    final event = await reference.once();
    if (event.snapshot.exists && event.snapshot.value != null) {
      if (event.snapshot.value is Map) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      } else {
        // If it's not a map (e.g., a single value like a string or number directly under the nodeKey)
        return {'_value': event.snapshot.value};
      }
    }
    return {};
  }

  Future<Map<String, dynamic>> getDataFromFullPath(String fullPath) async {
    final reference = FirebaseDatabase.instance.ref(fullPath);
    final event = await reference.once();
    if (event.snapshot.exists && event.snapshot.value != null) {
       if (event.snapshot.value is Map) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      } else {
        return {'_value': event.snapshot.value};
      }
    }
    return {};
  }

  Future<void> deleteData(String fullPath) async {
    final reference = FirebaseDatabase.instance.ref(fullPath);
    try {
        await reference.remove();
        print('Data deleted successfully from $fullPath');
    } catch (error) {
        print('Failed to delete data at $fullPath: $error');
        rethrow; // Re-throw to allow caller to handle
    }
  }

  String getNewKey({required String basePath}) {
     if (basePath.isEmpty) {
        throw ArgumentError("Base path cannot be empty when generating a new key.");
    }
    return FirebaseDatabase.instance.ref(basePath).push().key!;
  }

  // getDataStream now matches the interactor's expectation of full path and Map<String, dynamic>?
  Stream<Map<String, dynamic>?> getDataStream({required String path}) {
    DatabaseReference ref = FirebaseDatabase.instance.ref(path);
    return ref.onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        if (event.snapshot.value is Map) {
          return Map<String, dynamic>.from(event.snapshot.value as Map);
        } else {
          print("Warning: Data at stream path $path is not a Map: ${event.snapshot.value}");
          return null;
        }
      }
      return null;
    });
  }

    // Added updateData method as it's used by FirebaseRepoInteractor in target code
  Future<void> updateData({required String path, required Map<String, dynamic> data}) async {
    try {
      DatabaseReference ref = FirebaseDatabase.instance.ref(path);
      await ref.update(data);
      print("Data updated successfully at $path");
    } catch (e) {
      print("Error updating data in Firebase Realtime Database at $path: $e");
      rethrow;
    }
  }
}