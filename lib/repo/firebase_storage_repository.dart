import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageRepository {
  FirebaseStorageRepository._();
  static final FirebaseStorageRepository instance = FirebaseStorageRepository._();

  Future<String> uploadProfileImage(String uid, Uint8List data) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_photos/$uid/profile.jpg');
    final task = ref.putData(data, SettableMetadata(contentType: 'image/jpeg'));
    await task.whenComplete(() => null);
    return await ref.getDownloadURL();
  }
}
