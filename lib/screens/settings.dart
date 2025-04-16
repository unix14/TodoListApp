import 'package:flutter/material.dart';
import 'package:flutter_example/common/DialogHelper.dart';
import 'package:flutter_example/common/context_extensions.dart';
import 'package:flutter_example/common/dialog_extensions.dart';
import 'package:flutter_example/common/encrypted_shared_preferences_helper.dart';
import 'package:flutter_example/mixin/app_locale.dart';
import 'package:flutter_example/mixin/pwa_installer_mixin.dart';
import 'package:flutter_example/repo/firebase_repo_interactor.dart';
import 'package:flutter_example/screens/onboarding.dart';
import 'package:flutter_localization/flutter_localization.dart';

import '../common/consts.dart';
import '../common/globals.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

/// fix font issues in no internet condition
/// todo add internet detection code
///
/// Failed to load font Noto Sans SC at https://fonts.gstatic.com/s/notosanssc/v36/k3kCo84MPvpLmixcA63oeAL7Iqp5IZJF9bmaG9_FnYxNbPzS5HE.ttf
//todo Flutter Web engine failed to complete HTTP request to fetch "https://fonts.gstatic.com/s/notosanssc/v36/k3kCo84MPvpLmixcA63oeAL7Iqp5IZJF9bmaG9_FnYxNbPzS5HE.ttf": TypeError: Failed to fetch
// todo add pb for loading

class _SettingsScreenState extends State<SettingsScreen>
    with PWAInstallerMixin {
  String version = "1.0.0";

  @override
  void initState() {
    Future.delayed(const Duration(seconds: 1), () async {
      var returnedVersion = await context.getAppVersion();
      setState(() {
        version = returnedVersion;
      });
    });
    super.initState();
  }

  TextStyle redTextsStyle =
      const TextStyle(color: Colors.red, fontWeight: FontWeight.bold);
  TextStyle redSubTextsStyle =
      const TextStyle(color: Colors.red, fontWeight: FontWeight.w400);

  @override
  Widget build(BuildContext context) {
    var email = myCurrentUser?.email ?? AppLocale.guest.getString(context);
    // var name = myCurrentUser?.name ?? AppLocale.unknown.getString(context); // todo bring back
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocale.settings.getString(context)),
        // todo add trailing icon with info button
        actions: [
          // Info button
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          ListTile(
            title: Text(AppLocale.account.getString(context)),
            subtitle: Text(email), // todo
            onTap: () {
              context.copyToClipboard(email);
            },
          ),
          // ListTile(
          //   title: Text(AppLocale.name.getString(context)),
          //   subtitle: Text(name),
          //   onTap: () {
          //     // todo when clicked show different name input dialog and change it in firebase
          //   },
          // ),
          simpleDivider,
          ListTile(
            title: Text(AppLocale.lang.getString(context)),
            subtitle: Text(FlutterLocalization.instance.getLanguageName()),
            // todo
            onTap: () {
              // todo on click opens a two options menu box pop up Hebrew or enlgish,
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return SimpleDialog(
                    title: const Text("Select Language"),
                    children: <Widget>[
                      SimpleDialogOption(
                        onPressed: () {
                          // Handle Hebrew selection
                          _onLanguageChanged("he");
                        },
                        child: Text(FlutterLocalization.instance
                            .getLanguageName(languageCode: "he")),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          // Handle English selection
                          _onLanguageChanged("en");
                        },
                        child: Text(FlutterLocalization.instance
                            .getLanguageName(languageCode: "en")),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          simpleDivider,
          ListTile(
            title: Text(AppLocale.version.getString(context)),
            subtitle: Text(version), // todo
            onTap: () {
              context.copyToClipboard(version);
            },
          ),
          ListTile(
            title: Text(AppLocale.installApp.getString(context)),
            onTap: () {
              if (isInstallable()) {
                showInstallPrompt();
              }
              context.showSnackBar(AppLocale.appIsInstalled.getString(context));
            },
          ),
          const Divider(color: Color(0x56ff0000)),
          ListTile(
            title: Text(
              AppLocale.deleteAll.getString(context),
              style: redTextsStyle,
            ),
            // todo make it possible via archive screen
            subtitle: Text(
              AppLocale.deleteAllSubtitle.getString(context),
              style: redSubTextsStyle,
            ),
            onTap: () {
              deleteAll();
            },
          ),
          // ListTile( // todo think about this
          //   title: Text("Delete all user data", style: redTextsStyle),
          //   onTap: () {
          //     // todo
          //   },
          // ),
          if (isLoggedIn == true)
            ListTile(
              title: Text(AppLocale.logout.getString(context),
                  style: redTextsStyle),
              onTap: () {
                context.onLogoutClicked(() {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (context) => const OnboardingScreen()));
                });
              },
            ),
          // todo add AdView?
        ],
      ),
    );
  }

  Future<void> _onLanguageChanged(String newLang) async {
    currentLocaleStr = newLang;
    await EncryptedSharedPreferencesHelper.setString(
        kCurrentLocaleSavedPrefs, currentLocaleStr);
    FlutterLocalization.instance.translate(currentLocaleStr);
    Navigator.pop(context);
  }

  void deleteAll() async {
    DialogHelper.showAlertDialog(context, "Are you sure?",
        "Deleting all Todos will result in an empty list and an empty archive list. Do you really want to delete everything?",
        () async {
      await EncryptedSharedPreferencesHelper.setString(kAllListSavedPrefs, "");
      print("Delete all list from settings");

      // update realtime DB if logged in
      if (isLoggedIn && currentUser?.uid.isNotEmpty == true) {
        myCurrentUser ??=
            await FirebaseRepoInteractor.instance.getUserData(currentUser!.uid);
        myCurrentUser!.todoListItems = [];

        var didSuccess = await FirebaseRepoInteractor.instance
            .updateUserData(myCurrentUser!);
        if (didSuccess == true) {
          print("success save to DB");
        }
      }
    }, () {
      // Cancel
      Navigator.of(context).pop(); // dismiss dialog
    });
  }
}
