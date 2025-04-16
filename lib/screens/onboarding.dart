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