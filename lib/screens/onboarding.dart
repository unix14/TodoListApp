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
import 'package:flutter_example/generated/l10n.dart';
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

// JULES_TODO: Review all AppLocale.xyz.getString(context) usages in this file.
// If corresponding keys (e.g., 'loginWEmail', 'loginAsGuest') have been added to your ARB files for the S class,
// please update them to use S.of(context).yourKey format.
class _OnboardingScreenState extends State<OnboardingScreen> {

  void _showAuthErrorDialog(BuildContext context, String title, String errorKey) {
    String message;
    switch (errorKey) {
      case 'authNoUserFound':
        message = S.of(context).authNoUserFound;
        break;
      case 'authWrongPassword':
        message = S.of(context).authWrongPassword;
        break;
      case 'authWeakPassword':
        message = S.of(context).authWeakPassword;
        break;
      case 'authEmailAlreadyInUse':
        message = S.of(context).authEmailAlreadyInUse;
        break;
      case 'authUnknownError':
        // It's good practice to have a generic unknown error string in ARB files
        // For now, using a hardcoded fallback if S.of(context).authUnknownError is not defined
        message = S.of(context).authUnknownError ?? "An unexpected error occurred. Please try again.";
        break;
      default:
        message = "An unexpected error: $errorKey"; // Should ideally be localized too
    }
    DialogHelper.showAlertDialog(context, title, message, () {
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
      // 1. Obtain email and password from your dialog (e.g., context.showLoginDialog).
      // 2. Call: var result = await Authenticator.signIn(email, password);
      // 3. If result is User: show S.of(context).loggedInWelcomeMessage snackbar, navigate to HomePage.
      //    (Ensure widget is mounted if async operations are involved before BuildContext use)
      //    if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).loggedInWelcomeMessage))); }
      //    if (mounted) { Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage())); }
      // 4. If result is String (error key): call _showAuthErrorDialog(context, S.of(context).loginFailedTitle, result);
      //    if (mounted) { _showAuthErrorDialog(context, S.of(context).loginFailedTitle, result); }
      // 5. Handle any other cases (e.g., null result from dialog) appropriately.
      // Remember to replace AppLocale.loginWEmail.getString(context) with S.of(context).yourLoginButtonKey if you added one.
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