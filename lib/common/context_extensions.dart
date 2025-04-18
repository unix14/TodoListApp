

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_example/common/consts.dart';
import 'package:flutter_example/common/encrypted_shared_preferences_helper.dart';
import 'package:flutter_example/main.dart';
import 'package:flutter_example/common/dialog_extensions.dart';
import 'package:flutter_example/auth/authenticator.dart';
import 'package:flutter_example/managers/app_initializer.dart';
import 'package:flutter_example/mixin/app_locale.dart';
import 'package:flutter_example/models/user.dart' as MyUser;
import 'package:flutter_example/repo/firebase_repo_interactor.dart';
import 'package:flutter_example/common/globals.dart';
import 'package:flutter_example/screens/homepage.dart';
import 'package:flutter_localization/flutter_localization.dart';


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
          title: Text(AppLocale.login.getString(context)),
          content: AutofillGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    labelText: AppLocale.email.getString(context),
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
                    decoration: InputDecoration(
                      labelText: AppLocale.password.getString(context),
                    ),
                    obscureText: true,
                    controller: passwordController,
                    onSubmitted: (_) => onLoginClicked(context, emailController, passwordController),
                    focusNode: passwordFocusNode,
                  ),
                ),
                shouldShowSignupButton ? orWidget(context) : const SizedBox
                    .shrink(),
                shouldShowSignupButton ? TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    showSignupDialog();
                  },
                  child: Text(AppLocale.signup.getString(context),
                    style: const TextStyle(color: Colors.black, fontSize: 12,),),
                ) : const SizedBox.shrink(),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                AppLocale.cancel.getString(context), style: const TextStyle(color: Colors.black),),
            ),
            TextButton(
              onPressed: () async {
                onLoginClicked(context, emailController, passwordController);
              },
              child: Text(
                AppLocale.login.getString(context), style: const TextStyle(color: Colors.black),),
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
            title: Text(AppLocale.signup.getString(context)),
            content: AutofillGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(
                      labelText: AppLocale.email.getString(context),
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
                      decoration: InputDecoration(
                        labelText: AppLocale.password.getString(context),
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
                child: Text(AppLocale.cancel.getString(context), style: const TextStyle(color: Colors.black),),
              ),
              TextButton(
                onPressed: () async {
                  onSignupClicked(context, emailController, passwordController);
                },
                child: Text(AppLocale.signup.getString(context), style: const TextStyle(color: Colors.black),),
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
      myCurrentUser = await FirebaseRepoInteractor.instance.getUserData(currentUser!.uid);

      myCurrentUser!.dateOfLoginIn = DateTime.now();


      Future.delayed(const Duration(milliseconds: 500), () async {
        Navigator.of(this).pushReplacement(MaterialPageRoute(builder: (context) => const HomePage()));
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

      myCurrentUser = MyUser.User(
        email: user.email,
        imageURL: user.photoURL ?? "",
        name: user.displayName ?? "",);

      myCurrentUser!.dateOfRegistration = DateTime.now();
      myCurrentUser!.dateOfLoginIn = DateTime.now();

      myCurrentUser!.todoListItems = [];

      var didSuccess = await FirebaseRepoInteractor.instance.updateUserData(myCurrentUser!);
      if(didSuccess == true) {
        print("success save after signup to DB");
      }

      // PageData pageData = PageData(
      //   id: user.uid,
      //   email: currentUser?.email ?? "",
      // );
      // currentPage = pageData;

      Future.delayed(const Duration(milliseconds: 500), () async {
        Navigator.of(this).pushReplacement(MaterialPageRoute(builder: (context) => const HomePage()));
      });
    } else {
      showAlertDialog("Signup failed", "Please try again");
    }

    // AnalytixManager().logEvent('user_click', 'signup_result', params: {
    //   'email': email,
    //   'isSignedUpSuccessfully': user != null,
    // });
  }

  Future<void> onLogoutClicked(Function() onLogout) async {
    showAreYouSureDialog(AppLocale.logout.getString(this), AppLocale.logoutText.getString(this), () async {
      // AnalytixManager().logEvent('user_click', 'logout');
      await Authenticator.signOut();

      currentLocaleStr = "en";

      await EncryptedSharedPreferencesHelper.setString(kAllListSavedPrefs, "");
      await EncryptedSharedPreferencesHelper.setString(kCurrentLocaleSavedPrefs, currentLocaleStr);


      showSnackBar("You are logged out");
      await Future.delayed(Duration.zero, () async {
        Navigator.of(this).popUntil((route) => route.isFirst);
        currentUser = null;
        myCurrentUser= null;
        isLoggedIn = false;
        // isAdmin = false;
      });
      await onLogout();
    }, firstButtonText: AppLocale.ok.getString(this),
    secondButtonText: AppLocale.cancel.getString(this));
  }


}