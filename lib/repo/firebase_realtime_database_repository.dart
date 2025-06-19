import 'package:firebase_database/firebase_database.dart';
import 'dart:async'; // For StreamController

class FirebaseRealtimeDatabaseRepository {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Private constructor for Singleton pattern
  FirebaseRealtimeDatabaseRepository._privateConstructor();

  // Static instance variable
  static final FirebaseRealtimeDatabaseRepository _instance =
      FirebaseRealtimeDatabaseRepository._privateConstructor();

  // Public accessor for the instance
  static FirebaseRealtimeDatabaseRepository get instance => _instance;

  // Static variable to hold a test instance
  static FirebaseRealtimeDatabaseRepository? _testInstance;

  // Method to set a test instance
  static void setTestInstance(FirebaseRealtimeDatabaseRepository testInstance) {
    _testInstance = testInstance;
  }

  // Getter that returns the test instance if set, otherwise the real one
  static FirebaseRealtimeDatabaseRepository get I => _testInstance ?? _instance;


  Future<void> saveData({required String path, required Map<String, dynamic> data}) async {
    try {
      DatabaseReference ref = _database.ref(path);
      await ref.set(data);
    } catch (e) {
      print("Error saving data to Firebase Realtime Database at $path: $e");
      rethrow; // Rethrow the exception to be handled by the caller
    }
  }

  Future<Map<String, dynamic>?> getData({required String path}) async {
    try {
      DatabaseReference ref = _database.ref(path);
      final DataSnapshot snapshot = await ref.get();
      if (snapshot.exists && snapshot.value != null) {
        // Ensure the value is correctly cast to Map<String, dynamic>
        // Firebase might return Map<Object?, Object?> or similar.
        if (snapshot.value is Map) {
            final Map<dynamic, dynamic> rawMap = snapshot.value as Map<dynamic, dynamic>;
            final Map<String, dynamic> typedMap = Map<String, dynamic>.fromEntries(
                rawMap.entries.map((entry) => MapEntry(entry.key.toString(), entry.value))
            );
            return typedMap;
        }
        return null; // Or handle other types if expected
      } else {
        return null; // Data does not exist at this path
      }
    } catch (e) {
      print("Error getting data from Firebase Realtime Database from $path: $e");
      rethrow;
    }
  }

  // Specific method for getting data when the full path is known and data is expected to be Map<String, dynamic>
  Future<Map<String, dynamic>?> getDataFromFullPath({required String fullPath}) async {
    return getData(path: fullPath);
  }


  Future<void> updateData({required String path, required Map<String, dynamic> data}) async {
    try {
      DatabaseReference ref = _database.ref(path);
      await ref.update(data);
    } catch (e) {
      print("Error updating data in Firebase Realtime Database at $path: $e");
      rethrow;
    }
  }

  Future<void> deleteData({required String path}) async {
    try {
      DatabaseReference ref = _database.ref(path);
      await ref.remove();
    } catch (e) {
      print("Error deleting data from Firebase Realtime Database at $path: $e");
      rethrow;
    }
  }

  // Method to get a new unique key for a path
  String? getNewKey({required String basePath}) {
    try {
      DatabaseReference ref = _database.ref(basePath);
      return ref.push().key;
    } catch (e) {
      print("Error getting new key from Firebase Realtime Database at $basePath: $e");
      return null;
    }
  }

  // Method to get a stream of data from a specific path
  Stream<Map<String, dynamic>?> getDataStream({required String path}) {
    StreamController<Map<String, dynamic>?> controller = StreamController();
    DatabaseReference ref = _database.ref(path);

    final listener = ref.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        if (event.snapshot.value is Map) {
             final Map<dynamic, dynamic> rawMap = event.snapshot.value as Map<dynamic, dynamic>;
             final Map<String, dynamic> typedMap = Map<String, dynamic>.fromEntries(
                rawMap.entries.map((entry) => MapEntry(entry.key.toString(), entry.value))
            );
            controller.add(typedMap);
        } else {
            // If data is not a map (e.g. just a value or null), you might want to handle it.
            // For now, assuming we expect a map or null.
            controller.add(null); // Or throw an error, or transform as needed
        }
      } else {
        controller.add(null); // Data does not exist or is null
      }
    }, onError: (Object error) {
      print("Error in Firebase Realtime Database stream at $path: $error");
      controller.addError(error);
      controller.close(); // Close stream on error
    });

    // When the stream subscription is cancelled, cancel the Firebase listener
    controller.onCancel = () {
      listener.cancel();
    };

    return controller.stream;
  }
}