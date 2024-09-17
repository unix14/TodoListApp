import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_example/main.dart';
import 'package:flutter_example/managers/login_manager.dart';
import 'package:flutter_example/models/user.dart';

import '../widgets/white_round_button.dart';


//todo refactor package name
// todo refactor android app name
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

//todo find suitable font

class _OnboardingScreenState extends State<OnboardingScreen> {
  double angle = 0.0;
  late Timer timer;
  final LoginManager loginManager = LoginManager();

  @override
  void initState() {
    super.initState();
    //todo refactor weird bg animation into a widget
    timer = Timer.periodic(const Duration(seconds: 3), (Timer t) {
      setState(() {
        angle += 0.1;
        if (angle >= 1.0) {
          angle -= 0.2;
        } else if(angle <= 0.0) {
          angle += 0.1;
        }
      });
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment(-1.5, -angle),
            colors: const [Colors.blue, Colors.blueAccent],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Spacer(),
              const Text(
                'Todo Later',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              WhiteRoundButton(text: 'Login with Email', onPressed: () async {
                // Implement email login functionality
                // UserCredential? userCredential = await loginManager.signInWithEmailPassword('email', 'password');
                /// todo go to email login screen
              },),
              const SizedBox(height: 20),
              WhiteRoundButton(text: 'Login with Google', onPressed: () async {
                // Implement Google login functionality
                UserCredential? userCredential = await loginManager.signInWithGoogle();
                if (userCredential != null) {
                  // User is signed in
                  // Navigate to home screen or do something else
                  // userCredential.user // todo use this??
                  userCredential.toUser();
                  //todo add on logged in move to next screen
                } else {
                  // User is not signed in
                  // Handle the error
                }
              },),
              const Spacer(),
              Padding(padding: const EdgeInsets.only(bottom: 8, top: 30),
                child: TextButton(
                  onPressed: _skipToMainScreen,
                  child: const Text(
                    //todo use translation service \ app localization
                    'or skip',
                    style: TextStyle(
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
    UserCredential? userCredential = await loginManager.signInAnonymously();
    if (userCredential != null) {
      // Navigate to main screen
      //todo use routes!!
      // Navigator.pushReplacementNamed(context, '/main');
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyHomePage(title: 'Todo Later')));
    } else {
      // Handle the error
    }
  }
}