import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_example/common/globals.dart';
import 'package:flutter_example/mixin/app_locale.dart';
import 'package:flutter_example/models/user.dart' as MyUser;
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_example/screens/homepage.dart';

import '../widgets/white_round_button.dart';
import '../common/context_extensions.dart';
import '../auth/authenticator.dart';
import 'package:flutter_example/common/DialogHelper.dart';


//todo refactor package name
// todo refactor android app name
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

//todo find suitable font
// todo add option to do repeating tasks

class _OnboardingScreenState extends State<OnboardingScreen> {

  // Helper function to display authentication errors using AppLocale keys
  void _showAuthErrorDialog(BuildContext context, String titleLocaleKey, String rawAuthErrorKey) {
    String localizedDialogTitle = titleLocaleKey.getString(context); // e.g., AppLocale.loginFailedTitle.getString(context)
    String localizedMessage;

    switch (rawAuthErrorKey) {
      case AppLocale.authNoUserFound: // Compares raw string "authNoUserFound" with AppLocale.authNoUserFound (which is 'authNoUserFound')
        localizedMessage = AppLocale.authNoUserFound.getString(context);
        break;
      case AppLocale.authWrongPassword:
        localizedMessage = AppLocale.authWrongPassword.getString(context);
        break;
      case AppLocale.authWeakPassword:
        localizedMessage = AppLocale.authWeakPassword.getString(context);
        break;
      case AppLocale.authEmailAlreadyInUse:
        localizedMessage = AppLocale.authEmailAlreadyInUse.getString(context);
        break;
      // Use AppLocale.authUnknownError for any other error key from Authenticator or if it's explicitly returned
      case AppLocale.authUnknownError:
      default: // Catches any other string from Authenticator or if "authUnknownError" was passed directly
        localizedMessage = AppLocale.authUnknownError.getString(context);
        break;
    }

    DialogHelper.showAlertDialog(context, localizedDialogTitle, localizedMessage, () {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }, null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.blueAccent],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Align(
                alignment: Alignment.topRight,
                child: TextButton(onPressed: () {
                  if(currentLocaleStr == "he") {
                    currentLocaleStr = "en";
                  } else {
                    currentLocaleStr = "he";
                  }
                  FlutterLocalization.instance.translate(currentLocaleStr);
                }, child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(FlutterLocalization.instance.getLanguageName(), style: TextStyle(color: Colors.white),),
                )),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: SizedBox(
                  width: 96,
                    child: Image.asset("icons/Icon-192.png")
                ),
              ),
              Text(
                AppLocale.todoLater.getString(context),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              WhiteRoundButton(text: AppLocale.loginWEmail.getString(context), onPressed: () async {
      // JULES_TODO: Refactor login logic below to use Authenticator.signIn and handle results:
      // 1. Obtain email and password from your dialog (e.g., by adapting context.showLoginDialog or a new dialog).
      // 2. Call: var result = await Authenticator.signIn(email, password);
      // 3. If result is User: show AppLocale.loggedInWelcomeMessage.getString(context) snackbar, navigate to HomePage.
      //    (Ensure widget is mounted if async operations are involved before BuildContext use)
      //    if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.loggedInWelcomeMessage.getString(context)))); }
      //    if (mounted) { Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage())); }
      // 4. If result is String (error key from Authenticator): call _showAuthErrorDialog(context, AppLocale.loginFailedTitle, result);
      //    (The 'result' is the raw error string like "authNoUserFound", which _showAuthErrorDialog now handles)
      //    if (mounted) { _showAuthErrorDialog(context, AppLocale.loginFailedTitle, result); }
      // 5. Handle any other cases (e.g., null result from dialog if it can return that) appropriately.
      // Note: AppLocale.loginWEmail.getString(context) is already used for the button text.
                // todo Implement email login functionality
                /// go to email login screen
                context.showLoginDialog();//(_a, emailController, passwordController) async {
                //   var email = emailController.text;
                //   var password = passwordController.text;
                //   // UserCredential? userCredential = await loginManager.signInWithEmailPassword(email, password);
                //
                //   var user = await Authenticator.signIn(email, password);
                //
                //   if(user != null) {
                //     Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyHomePage(title: 'Todo Later')));
                //   } else {
                //     // todo handle errors here
                //   }
                //
                // });
              },),
              // const SizedBox(height: 20), // todo reimplement google login
              // WhiteRoundButton(text: 'Login with Google', onPressed: () async {
              //   // Implement Google login functionality
              //   User? user = await Authenticator.signInWithGoogle();
              //   if (user != null) {
              //     // User is signed in
              //     // Navigate to home screen or do something else
              //     // userCredential.user // todo use this??
              //     //todo add on logged in move to next screen
              //   } else {
              //     // User is not signed in
              //     // Handle the error
              //   }
              // },),
              const Spacer(),
              Padding(padding: const EdgeInsets.only(bottom: 8, top: 30),
                child: TextButton(
                  onPressed: _skipToMainScreen,
                  child: Text(
                    AppLocale.loginAsGuest.getString(context),
                    style: const TextStyle(
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _skipToMainScreen() async {
    User? user = await Authenticator.signInAnonymously();
    // Navigate to main screen even if sign in anon is failed
    //todo use routes!!
    // Navigator.pushReplacementNamed(context, '/main');
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
  }
}