// Example of how context_extensions.dart might look after some corrections
// (This is highly dependent on its original full content and purpose)
// lib/common/context_extensions.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // Alias for Firebase Auth User
import 'package:flutter_example/models/user.dart' as AppUser;
import 'package:flutter_example/repo/firebase_repo_interactor.dart';
import 'package:flutter_example/common/globals.dart';
import 'package:flutter_example/common/encrypted_shared_preferences_helper.dart';
import 'package:flutter_example/common/consts.dart'; // For kAllListSavedPrefs, kCurrentLocaleSavedPrefs

extension ContextExtension on BuildContext {
  // Example: Refactored method that was trying to use context for state
  Future<void> updateUserDetailsOnLogin(fb_auth.User firebaseUser) async {
    // Get user data, if it exists, update login time
    AppUser.User? appUser = await FirebaseRepoInteractor.instance.getUserData(firebaseUser.uid);
    if (appUser != null) {
      appUser.dateOfLoginIn = DateTime.now();
      // Globals.currentUser is updated by getUserData if it re-saves, or by direct assignment after this call
      Globals.currentUser = appUser;
      await FirebaseRepoInteractor.instance.saveUser(appUser); // Corrected: saveUser
    } else {
      // New user scenario
      // The toUser() extension is on Firebase's UserCredential, not User.
      // Assuming firebaseUser (which is fb_auth.User) needs to be converted to AppUser.User
      // This typically happens after signup or if data is missing.
      // The toUser() extension on UserCredential should handle this.
      // For now, if appUser is null, we might need to create a new one.
      // This logic might be better placed in AppInitializer or auth service.
      // For this refactor, let's assume if appUser is null, we create a new one.
      appUser = AppUser.User( // Directly create AppUser.User
          id: firebaseUser.uid,
          email: firebaseUser.email,
          name: firebaseUser.displayName,
          profilePictureUrl: firebaseUser.photoURL, // Corrected parameter name
          dateOfRegistration: DateTime.now(),
          dateOfLoginIn: DateTime.now(),
          todoListItems: [] // Initialize empty list
      );
      Globals.currentUser = appUser;
      await FirebaseRepoInteractor.instance.saveUser(appUser); // Corrected: saveUser
    }
    Globals.isLoggedIn = true;
  }

  Future<void> clearLocalDataOnLogout() async {
    // Example of clearing some prefs, ensure keys are correct
    await EncryptedSharedPreferencesHelper.remove(kAllListSavedPrefs);
    // await EncryptedSharedPreferencesHelper.remove(kCurrentLocaleSavedPrefs); // If you save locale this way
    Globals.currentUser = null;
    Globals.isLoggedIn = false;
  }

  // Other extensions can remain if they are valid utility functions on BuildContext
  // For example, if translate was here:
  // String translate(String key) => AppLocale.getString(this, key); // Example: Needs AppLocale and flutter_localization import
}