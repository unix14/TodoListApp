import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_example/common/encrypted_shared_preferences_helper.dart';
import 'package:flutter_example/common/encryption_helper.dart';
import 'package:flutter_example/firebase_options.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_example/common/globals.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_example/auth/authenticator.dart';
import 'package:flutter_example/mixin/app_locale.dart';
import 'package:flutter_localization/flutter_localization.dart';

import '../common/consts.dart';

/// AppInitializer class is responsible for initializing the app.
/// It ensures that the app is initialized with all the necessary services before it starts.
/// It initializes Firebase, Google Mobile Ads, Encryption Helper and other services can be added in the future.
class AppInitializer {

  //todo add crash detection and analytics with Firebase
  static Future<void> initialize({required Function(bool) andThen}) async {
    WidgetsFlutterBinding.ensureInitialized();
    bool isAlreadyEnteredTodos = false;
    await EncryptedSharedPreferencesHelper.initialize();
    await EncryptionHelper.initialize();
    await initLanguages();
    // MobileAds.instance.initialize();
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
      await initAuthentication();
      await initIsLoggedIn();

      var listStr = await EncryptedSharedPreferencesHelper.getString(kAllListSavedPrefs) ?? "";
      print("initialize: load list :" + listStr);
      isAlreadyEnteredTodos = listStr.isNotEmpty; // this is a check to see if the user has already entered the app and saved his data-> we want to let him use the app again in offline mode
      // todo rethink offline mode maybe - we need to pop up a snackbar that defined this is an offline mode
    } catch (exception) {
      // firebase auth failed
      print("Error logging in to firebase -> stay in offline mode, exception is $exception");
      // todo show error msg
    }
    andThen(isAlreadyEnteredTodos);
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
      isLoggedIn = event != null && event.isAnonymous == false && event.email?.isNotEmpty == true;
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

  static Future<void> initLanguages() async {
    await FlutterLocalization.instance.init(
      mapLocales: [
        const MapLocale('en', AppLocale.EN),
        const MapLocale('he', AppLocale.HE),
      ],
      initLanguageCode: 'en',
    );
    currentLocaleStr = await EncryptedSharedPreferencesHelper
        .getString(kCurrentLocaleSavedPrefs) ?? currentLocaleStr;
  }
}