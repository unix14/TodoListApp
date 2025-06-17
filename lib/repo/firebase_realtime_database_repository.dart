
import 'package:firebase_database/firebase_database.dart';

class FirebaseRealtimeDatabaseRepository {
  // For testing purposes, allow replacing the instance.
  static FirebaseRealtimeDatabaseRepository? _testInstance;
  static FirebaseRealtimeDatabaseRepository get instance => _testInstance ?? _instance;
  static final FirebaseRealtimeDatabaseRepository _instance = FirebaseRealtimeDatabaseRepository.internal();

  FirebaseRealtimeDatabaseRepository.internal(); // Made constructor internal
  FirebaseRealtimeDatabaseRepository._() : this.internal(); // Added for original call, redirects to internal. Or remove if _() was a mistake.

  Future<dynamic> saveData(String path, Map<String, dynamic>? data) async { // Made data nullable for deletion
  Future<dynamic> saveData(String fullPath, Map<String, dynamic>? dataToSave) async {
    // Path is now assumed to be the full path where data should be saved or deleted.
    DatabaseReference reference = FirebaseDatabase.instance.ref().child(fullPath);

    if (dataToSave == null) { // If data is null, treat as a delete operation
        return await reference.remove().then((_) {
            print('Data deleted successfully at $fullPath');
            return true;
        }).catchError((error) {
            print('Failed to delete data at $fullPath: $error');
            return false;
        });
    } else {
        // If 'id' is not in dataToSave and path is a collection path,
        // this will overwrite the collection node with a single map.
        // It's generally better if the ID is part of the path for specific items.
        // Or use push() for collections if generating new ID.
        // This simplified saveData assumes the fullPath includes the item's ID if it's not a new push.
        return await reference.set(dataToSave).then((_) {
            print('Data saved successfully to path: $fullPath');
            return true;
        }).catchError((error) {
            print('Failed to save data: $error tried to save data: $dataToSave to path: $fullPath');
            return false;
        });
    }
  }

  Future<Map<String, dynamic>> getData(String nodeKey, String collectionPath) async {
    // Constructs path as collectionPath/nodeKey
    final reference = FirebaseDatabase.instance.ref(collectionPath).child(nodeKey);
    final event = await reference.once();
    if (event.snapshot.exists && event.snapshot.value is Map) {
      final data = event.snapshot.value as Map;
      return data.map((key, value) => MapEntry(key.toString(), value));
    } else if (event.snapshot.exists && event.snapshot.value != null) {
      // Handle cases where data might not be a map but some other value (e.g. a direct value under a key)
      // For FirebaseRepoInteractor, we mostly expect maps. This is a basic conversion.
      return {'_value': event.snapshot.value};
    }
    return {}; // return an empty map as default value
  }

  // Specific method to get data when the full path is already known
  Future<Map<String, dynamic>> getDataFromFullPath(String fullPath) async {
    final reference = FirebaseDatabase.instance.ref(fullPath);
    final event = await reference.once();
     if (event.snapshot.exists && event.snapshot.value is Map) {
      final data = event.snapshot.value as Map;
      return data.map((key, value) => MapEntry(key.toString(), value));
    } else if (event.snapshot.exists && event.snapshot.value != null) {
      return {'_value': event.snapshot.value};
    }
    return {};
  }


  Future<void> deleteData(String fullPath) async { // Path is full path
    final reference = FirebaseDatabase.instance.ref().child(fullPath);
    return await reference.remove().then((value) {
      print('Data deleted successfully at $fullPath');
    }).catchError((error) {
      print('Failed to delete data at $fullPath: $error');
    });
  }

  String getNewKey({required String basePath}) {
    // basePath is the path to the collection where the new key is needed.
    return FirebaseDatabase.instance.ref(basePath).push().key!;
  }

  // getStream might need adjustment based on how it's used, especially if full paths are common.
  Stream<DatabaseEvent> getStream(String path, {bool isFullPath = false, String? child}) {
    DatabaseReference ref;
    if (isFullPath) {
      ref = FirebaseDatabase.instance.ref(path);
    } else {
      ref = FirebaseDatabase.instance.ref(path).child(child!);
    }
    return ref.onValue;
  }
}