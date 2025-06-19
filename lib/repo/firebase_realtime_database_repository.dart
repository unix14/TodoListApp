// lib/repo/firebase_realtime_database_repository.dart
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class FirebaseRealtimeDatabaseRepository {
  FirebaseRealtimeDatabaseRepository._internal();
  static final FirebaseRealtimeDatabaseRepository _instance = FirebaseRealtimeDatabaseRepository._internal();
  static FirebaseRealtimeDatabaseRepository get instance => _testInstance ?? _instance; // Allow test instance override

  static FirebaseRealtimeDatabaseRepository? _testInstance;
  static set testInstance(FirebaseRealtimeDatabaseRepository? i) { // Setter for test instance
    _testInstance = i;
  }

  Future<bool> saveData(String fullPath, Map<String, dynamic>? dataToSave) async {
    DatabaseReference reference = FirebaseDatabase.instance.ref(fullPath);
    try {
      if (dataToSave == null) {
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

  Future<void> deleteData(String fullPath) async { // Changed to not have path: named param
    final reference = FirebaseDatabase.instance.ref(fullPath);
    try {
        await reference.remove();
        print('Data deleted successfully from $fullPath');
    } catch (error) {
        print('Failed to delete data at $fullPath: $error');
        rethrow;
    }
  }

  String getNewKey({required String basePath}) {
    if (basePath.isEmpty) { // Added check for empty basePath
        // It's often better to let Firebase generate a key at the root if basePath is truly not applicable
        // but this depends on the desired DB structure.
        // For now, allowing push at root. Consider if this is intended.
        return FirebaseDatabase.instance.ref().push().key!;
    }
    return FirebaseDatabase.instance.ref(basePath).push().key!;
  }

  Stream<Map<String, dynamic>?> getStream(String fullPath) { // Return type nullable map
    return FirebaseDatabase.instance.ref(fullPath).onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        if (event.snapshot.value is Map) {
             return Map<String, dynamic>.from(event.snapshot.value as Map);
        }
        // Handle non-map data if necessary, or return null/empty if structure is unexpected
        print("Warning: Data at $fullPath is not a Map, returning null for stream.");
        return null;
      }
      return null; // Or {} if an empty map is preferred for no data
    });
  }

  Future<void> updateData(String fullPath, Map<String, dynamic> dataToUpdate) async {
    DatabaseReference reference = FirebaseDatabase.instance.ref(fullPath);
    try {
        await reference.update(dataToUpdate);
        print('Data updated successfully at $fullPath');
    } catch (error) {
        print('Failed to update data at $fullPath: $error. Data: $dataToUpdate');
        rethrow;
    }
}
}