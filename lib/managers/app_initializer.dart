// lib/managers/app_initializer.dart
import 'package:firebase_auth/firebase_auth.dart' hide User; // Hide Firebase User
import 'package:flutter_example/common/globals.dart' as Globals;
import 'package:flutter_example/models/user.dart' as AppUser; // Using the alias
import 'package:flutter_example/repo/firebase_repo_interactor.dart';
// Removed: import 'package:get_it/get_it.dart';

// Removed: final getIt = GetIt.instance; // User said not to use GetIt

class AppInitializer {
  // Added _isInitialized flag to prevent multiple initializations if called more than once.
  static bool _isInitialized = false;

  static Future<void> initialize({required Function(bool) andThen}) async {
    if (_isInitialized) {
      // If called again after full initialization, re-check login and proceed.
      // This could happen if main() is somehow re-invoked or on a hot restart with state loss.
      await _checkLoginStatusAndProceed(andThen);
      return;
    }

    // FirebaseRepoInteractor uses a singleton pattern (FirebaseRepoInteractor.instance)
    // No explicit registration with getIt needed here.

    await _checkLoginStatusAndProceed(andThen);
    _isInitialized = true; // Mark as initialized after the first full run.
  }

  static Future<void> _checkLoginStatusAndProceed(Function(bool) andThen) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final firebaseUser = auth.currentUser;

    if (firebaseUser != null) {
      try {
        // Use the singleton instance pattern for FirebaseRepoInteractor
        AppUser.User? user = await FirebaseRepoInteractor.instance.getUserData(firebaseUser.uid);
        if (user != null) {
          Globals.currentUser = user;
          Globals.isLoggedIn = true;
          // AppInitializer.handleLoginSuccess(user); // This method was causing errors, direct assignment above
        } else {
          // User is authenticated with Firebase, but no data in DB - treat as new DB user
          user = firebaseUser.toUser(); // Using the extension method from user.dart
          Globals.currentUser = user;
          Globals.isLoggedIn = true;
          // AppInitializer.handleLoginSuccess(user); // Direct assignment
          await FirebaseRepoInteractor.instance.saveUser(user); // Save new user to DB
        }
      } catch (e) {
        print("Error fetching/creating user data during init: $e");
        Globals.currentUser = null; // Ensure currentUser is null on error
        Globals.isLoggedIn = false;
        // Potentially sign out if user data is critical and missing/corrupted
        // await auth.signOut();
      }
    } else {
      Globals.currentUser = null;
      Globals.isLoggedIn = false;
    }

    // Determine if the user has existing todos (based on the potentially loaded currentUser)
    bool hasEnteredTodos = Globals.currentUser?.todoListItems.isNotEmpty ?? false;
    andThen(hasEnteredTodos);
  }

  // This static method is not directly part of AppInitializer's responsibility
  // but can be a utility if needed elsewhere, or part of an AuthService.
  static Future<void> performLogout() async {
    await FirebaseAuth.instance.signOut();
    Globals.currentUser = null;
    Globals.isLoggedIn = false;
    // Any other app-specific cleanup on logout
  }
}