import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // Renamed to fb_auth.User
import 'package:flutter_example/common/encrypted_shared_preferences_helper.dart';
import 'package:flutter_example/common/globals.dart' as Globals; // Added Globals prefix
import 'package:flutter_example/models/user.dart' as AppUser; // For AppUser.User type
import 'package:flutter_example/repo/firebase_repo_interactor.dart';
import 'package:get_it/get_it.dart';

// Service Locator
final getIt = GetIt.instance;

class AppInitializer {
  static bool _isInitialized = false;

  static void initialize({required Function(bool) andThen}) {
    if (_isInitialized) {
      // If already initialized, directly call the 'andThen' callback.
      // This might need to re-check login status or other conditions
      // depending on app requirements. For now, assuming initial check is enough.
      _checkLoginStatusAndProceed(andThen);
      return;
    }

    // Register FirebaseRepoInteractor as a singleton
    // Ensure FirebaseRealtimeDatabaseRepository.instance or .current is used inside it.
    getIt.registerSingleton<FirebaseRepoInteractor>(FirebaseRepoInteractor.instance);

    // Perform other initializations like checking login status
    _checkLoginStatusAndProceed(andThen);
    _isInitialized = true;
  }

  static Future<void> _checkLoginStatusAndProceed(Function(bool) andThen) async {
    // Check if user is logged in with Firebase Auth
    final fb_auth.User? firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;

    if (firebaseUser != null) {
      Globals.isLoggedIn = true; // Set global isLoggedIn flag

      // Fetch user data from Firebase/local storage
      AppUser.User? user = await getIt<FirebaseRepoInteractor>().getUserData(firebaseUser.uid);

      if (user != null) {
        Globals.currentUser = user; // Assign to global currentUser in Globals
      } else {
        // If user data is not found in DB (e.g., new registration but DB entry failed)
        // Create a local AppUser.User from Firebase user info
        user = firebaseUser.toUser(); // Using the extension method
        Globals.currentUser = user;
        // Attempt to save this new user to the database
        await getIt<FirebaseRepoInteractor>().saveUser(user);
      }

      // Check if the user has entered any todos before (example logic)
      // This could be a flag in SharedPreferences or based on fetched user data
      bool hasEnteredTodos = Globals.currentUser?.todoListItems.isNotEmpty ?? false;
                                // Adjusted to use flat todoListItems from the User model in this subtask
      andThen(hasEnteredTodos);

    } else {
      Globals.isLoggedIn = false;
      Globals.currentUser = null; // Clear global current user
      // User is not logged in, proceed accordingly (e.g., show onboarding)
      andThen(false); // 'false' indicating not logged in / no todos entered
    }
  }
}