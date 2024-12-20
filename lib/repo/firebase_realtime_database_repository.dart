
import 'package:firebase_database/firebase_database.dart';

class FirebaseRealtimeDatabaseRepository {
  FirebaseRealtimeDatabaseRepository._();
  static final FirebaseRealtimeDatabaseRepository instance = FirebaseRealtimeDatabaseRepository._();

  Future<dynamic> saveData(String path, Map<String, dynamic> data) async {
    var finalId = path.replaceAll("users/", "");
    DatabaseReference reference;

    if(path == "users/") {
      reference = FirebaseDatabase.instance.ref(path).ref.push();
      finalId = reference.key ?? "";
    } else {
      reference = FirebaseDatabase.instance.ref().child(path);
      finalId = data['id'] ?? "";
    }
    data['id'] = finalId; // todo remove id??
    return await reference.set(data).then((value) {
      print('Data saved successfully');
      return true;
    }).catchError((error) {
      print('Failed to save data: ${error} tried to save data: ${data} to path: ${path}');
      return false;
    });
  }

  Future<Map<String, dynamic>> getData(String path, String referencePath) async {
    final reference = FirebaseDatabase.instance.ref(referencePath).ref.child(path);
    final event = await reference.once();
    if (event.snapshot.value is Map) {
      final data = event.snapshot.value as Map;
      return data.map((key, value) => MapEntry(key.toString(), value));
    } else {
      return {}; // return an empty map as default value
    }
  }


  Future<void> deleteData(String path) async {
    final reference = FirebaseDatabase.instance.ref().child(path);
    return await reference.remove().then((value) {
      print('Data deleted successfully');
    }).catchError((error) {
      print('Failed to delete data: ${error} tried to delete data at path: ${path}');
    });
  }
}