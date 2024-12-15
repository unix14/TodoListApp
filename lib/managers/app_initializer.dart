import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_example/firebase_options.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_example/common/globals.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_example/auth/authenticator.dart';

/// AppInitializer class is responsible for initializing the app.
/// It ensures that the app is initialized with all the necessary services before it starts.
/// It initializes Firebase, Google Mobile Ads, and other services can be added in the future.
class AppInitializer {

  //todo add crash detection and analytics with Firebase
  static Future<void> initialize({required Function andThen}) async {
    WidgetsFlutterBinding.ensureInitialized();
    // MobileAds.instance.initialize();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
    //todo add auto login if user exist or anon user if not
    await initAuthentication();
    await initIsLoggedIn();
    andThen();
  }



  static initAuthentication() async {
    /// If user exists -> Save the already logged-in user
    var loggedInUser = Authenticator.getCurrentUser();
    print("Logged in user: $loggedInUser");

    if(loggedInUser != null && loggedInUser.isAnonymous == false
        && loggedInUser.email?.isNotEmpty == true) {
      /// If user is the default user -> Admin
      isLoggedIn = true;
    } else {
      /// If user does not exist -> Sign in anonymously
      loggedInUser = await Authenticator.signInAnonymously();
      isLoggedIn = false;
    }
    handleLoginSuccess(loggedInUser!);
  }


  static initIsLoggedIn() {
    Authenticator.onAuthStateChanged.listen((event) {
      print("isLoggedInStream: $event");
      isLoggedIn = event != null && event.isAnonymous == false;
    });
  }


  static handleLoginSuccess(User user) {
    currentUser = user;

    //todo add anlytix?
    // AnalytixManager().setUserId(currentUser?.isAnonymous == true? "anonymous" :  currentUser?.email ?? currentUser?.uid ?? "anonymous");
    // AnalytixManager().setUserProperty('lastLoginTime', DateTime.now().toString());
    // AnalytixManager().setUserProperty('isAdmin', isAdmin == true ? "true" : "false");
    // AnalytixManager().setUserProperty('isLoggedIn', isLoggedIn == true ? "true" : "false");
    // AnalytixManager().setUserProperty('isAnonymous', currentUser?.isAnonymous == true ? "true" : "false");
  }
}