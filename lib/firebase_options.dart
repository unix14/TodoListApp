// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAwBdVMUVyTC_NaXsPQ5P25WGbYUbLFRQw',
    appId: '1:681999893255:web:9a51184915bd6e8862bba2',
    messagingSenderId: '681999893255',
    projectId: 'todo-later',
    authDomain: 'todo-later.firebaseapp.com',
    storageBucket: 'todo-later.appspot.com',
    measurementId: 'G-20RXHFVRQE',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD5JTkLw8pF9OfHpYLqgPU7861Ubj59p8c',
    appId: '1:681999893255:android:c9342b789280409962bba2',
    messagingSenderId: '681999893255',
    projectId: 'todo-later',
    storageBucket: 'todo-later.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBpJWjV7R0Ez7Kjuagw_VrTqWMuBmvsRt0',
    appId: '1:681999893255:ios:c4182ca9238d07b662bba2',
    messagingSenderId: '681999893255',
    projectId: 'todo-later',
    storageBucket: 'todo-later.appspot.com',
    iosBundleId: 'com.triPCups.tools.flutterExample',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBpJWjV7R0Ez7Kjuagw_VrTqWMuBmvsRt0',
    appId: '1:681999893255:ios:3359aba7b49b1f4862bba2',
    messagingSenderId: '681999893255',
    projectId: 'todo-later',
    storageBucket: 'todo-later.appspot.com',
    iosBundleId: 'com.eyalya94.tools.todoLater',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAwBdVMUVyTC_NaXsPQ5P25WGbYUbLFRQw',
    appId: '1:681999893255:web:4939c32bd98404bc62bba2',
    messagingSenderId: '681999893255',
    projectId: 'todo-later',
    authDomain: 'todo-later.firebaseapp.com',
    storageBucket: 'todo-later.appspot.com',
    measurementId: 'G-9DZC6HZPJD',
  );
}
