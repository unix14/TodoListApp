

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_example/common/consts.dart';
import 'package:flutter_example/main.dart';
import 'package:flutter_example/common/dialog_extensions.dart';
import 'package:flutter_example/auth/authenticator.dart';
import 'package:flutter_example/managers/app_initializer.dart';


extension ContextExtension on BuildContext { // todo rename to auth extensions?
  
  void showLoginDialog() {
    var emailController = TextEditingController();
    var passwordController = TextEditingController();
    var passwordFocusNode = FocusNode();
    bool shouldShowSignupButton = true ;// todo add remoteConfig ? remoteConfigParams?.shouldShowSignupButton == true;

    // todo add analytix?
    // AnalytixManager().logEvent('user_click', 'show_login_dialog', params: {
    //   'shouldShowSignupButton': shouldShowSignupButton ? "true" : "false",
    // });

    showDialog(
      context: this,
      builder: (context) {
        return AlertDialog(
          title: const Text('Login'),
          content: AutofillGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Email',
                  ),
                  controller: emailController,
                  onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                ),
                RawKeyboardListener(
                  focusNode: FocusNode(),
                  onKey: (event) {
                    if (FocusScope
                        .of(context)
                        .focusedChild != passwordFocusNode &&
                        event.logicalKey == LogicalKeyboardKey.enter) {
                      onLoginClicked(context, emailController, passwordController);
                    }
                  },
                  child: TextField(
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(
                      labelText: 'Password',
                    ),
                    obscureText: true,
                    controller: passwordController,
                    onSubmitted: (_) => onLoginClicked(context, emailController, passwordController),
                    focusNode: passwordFocusNode,
                  ),
                ),
                shouldShowSignupButton ? orWidget : const SizedBox
                    .shrink(),
                shouldShowSignupButton ? TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    showSignupDialog();
                  },
                  child: const Text('Signup',
                    style: TextStyle(color: Colors.black, fontSize: 12,),),
                ) : const SizedBox.shrink(),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel', style: TextStyle(color: Colors.black),),
            ),
            TextButton(
              onPressed: () async {
                onLoginClicked(context, emailController, passwordController);
              },
              child: const Text(
                'Login', style: TextStyle(color: Colors.black),),
            ),
          ],
        );
      },
    );
  }



  void showSignupDialog() {
    var emailController = TextEditingController();
    var passwordController = TextEditingController();
    var passwordFocusNode = FocusNode();

    // AnalytixManager().logEvent('user_click', 'show_signup_dialog');

    showDialog(
        context: this,
        builder: (context) {
          return AlertDialog(
            title: const Text('Signup'),
            content: AutofillGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email',
                    ),
                    controller: emailController,
                    onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                  RawKeyboardListener(
                    focusNode: FocusNode(),
                    onKey: (event) {
                      if(FocusScope.of(context).focusedChild != passwordFocusNode && event.logicalKey == LogicalKeyboardKey.enter) {
                        onSignupClicked(context, emailController, passwordController);
                      }
                    },
                    child: TextField(
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(
                        labelText: 'Password',
                      ),
                      obscureText: true,
                      controller: passwordController,
                      onSubmitted: (_) => onSignupClicked(context, emailController, passwordController),
                      focusNode: passwordFocusNode,
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel', style: TextStyle(color: Colors.black),),
              ),
              TextButton(
                onPressed: () async {
                  onSignupClicked(context, emailController, passwordController);
                },
                child: const Text('Signup', style: TextStyle(color: Colors.black),),
              ),
            ],
          );
        }
    );
  }



  void onLoginClicked(BuildContext context, TextEditingController emailController, TextEditingController passwordController) async {
    Navigator.of(context).pop();

    var email = emailController.text;
    var password = passwordController.text;

    // AnalytixManager().logEvent('user_click', 'try_to_login', params: {
    //   'email': email,
    // });

    var user = await Authenticator.signIn(email, password);

    if(user != null) {
      showSnackBar("You are now logged in, Welcome ${/*currentPage?.userName ??*/ user.email}");
      AppInitializer.handleLoginSuccess(user);



      Future.delayed(const Duration(milliseconds: 500), () async {
        Navigator.of(this).pushReplacement(MaterialPageRoute(builder: (context) => const MyHomePage(title: 'Todo Later')));
      });
    } else {
      showAlertDialog("Login failed", "Please try again");
    }

    // AnalytixManager().logEvent('user_click', 'login_result', params: {
    //   'email': email,
    //   'isLoggedInSuccessfully': user != null ? "true" : "false",
    // });
  }

  void onSignupClicked(BuildContext context, TextEditingController emailController, TextEditingController passwordController) async {
    Navigator.of(context).pop();

    var email = emailController.text;
    var password = passwordController.text;

    // AnalytixManager().logEvent('user_click', 'try_to_signup', params: {
    //   'email': email,
    // });

    var user = await Authenticator.signUp(email, password);

    if(user != null) {
      showSnackBar("You are now signed up, Welcome ${/*currentPage?.userName ??*/ user.email}");
      AppInitializer.handleLoginSuccess(user);


      // PageData pageData = PageData(
      //   id: user.uid,
      //   email: currentUser?.email ?? "",
      // );
      // currentPage = pageData;

      Future.delayed(const Duration(milliseconds: 500), () async {
        Navigator.of(this).pushReplacement(MaterialPageRoute(builder: (context) => const MyHomePage(title: 'Todo Later')));
      });
    } else {
      showAlertDialog("Signup failed", "Please try again");
    }

    // AnalytixManager().logEvent('user_click', 'signup_result', params: {
    //   'email': email,
    //   'isSignedUpSuccessfully': user != null,
    // });
  }

  // Future<void> onLogoutClicked(Function() onLogout) async {
  //   showAreYouSureDialog("Logout", "Are you sure you want to logout?", () async {
  //     AnalytixManager().logEvent('user_click', 'logout');
  //     await Authenticator.signOut();
  //     await Future.delayed(Duration.zero, () async {
  //       Navigator.of(this).popUntil((route) => route.isFirst);
  //       currentUser = null;
  //       isLoggedIn = false;
  //       isAdmin = false;
  //       await onLogout();
  //     });
  //
  //     showSnackBar("You are logged out");
  //   });
  // }


}