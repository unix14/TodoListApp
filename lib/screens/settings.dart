import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_example/common/DialogHelper.dart';
import 'package:flutter_example/common/context_extensions.dart';
import 'package:flutter_example/common/dialog_extensions.dart';
import 'package:flutter_example/common/encrypted_shared_preferences_helper.dart';
import 'package:flutter_example/mixin/app_locale.dart';
import 'package:flutter_example/mixin/pwa_installer_mixin.dart';
import 'package:flutter_example/repo/firebase_repo_interactor.dart';
import 'package:flutter_example/auth/authenticator.dart'; // Added for account deletion
import 'package:flutter_example/repo/firebase_realtime_database_repository.dart';
import 'package:flutter_example/screens/homepage.dart';
import 'package:flutter_example/screens/onboarding.dart';
import 'package:flutter_example/helpers/settings_logic_helper.dart'; // Import the helper
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
// Conditional import for dart:html, aliased as html
// This specific conditional import syntax might need adjustment based on project setup for stubs,
// but for direct use with kIsWeb, a direct import is often used and guarded.
// For this exercise, we'll assume a direct import and guard with kIsWeb.
import 'dart:html' as html;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_example/models/user.dart'; // Correct import for User model


import '../common/consts.dart';
import '../common/globals.dart'; // myCurrentUser is of type User? from here

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
  final SettingsLogicHelper _settingsHelper = SettingsLogicHelper(); // Instantiate the helper

  @override
  void initState() {
    Future.delayed(const Duration(milliseconds: 5), () async {
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
    var name = myCurrentUser?.name ?? AppLocale.unknown.getString(context);
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Tooltip(
                  message:
                      '${name.isNotEmpty ? name : AppLocale.anonymous.getString(context)}${email.isNotEmpty ? '\n$email' : ''}',
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: (myCurrentUser?.imageURL != null && myCurrentUser!.imageURL!.isNotEmpty)
                        ? (myCurrentUser!.imageURL!.startsWith('http')
                            ? NetworkImage(myCurrentUser!.imageURL!)
                            : MemoryImage(base64Decode(myCurrentUser!.imageURL!)) as ImageProvider)
                        : null,
                    child: (myCurrentUser?.imageURL != null && myCurrentUser!.imageURL!.isNotEmpty)
                        ? null
                        : (name.trim().isNotEmpty
                            ? Text(name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase())
                            : const Icon(Icons.person)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    name.isNotEmpty ? name : AppLocale.unknown.getString(context),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                if (currentUser != null && currentUser!.isAnonymous == false)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      _settingsHelper.updateUserName(context);
                    },
                  ),
              ],
            ),
          ),
          ListTile(
            title: Text(AppLocale.account.getString(context)),
            subtitle: Text(email),
            onTap: () {
              context.copyToClipboard(email);
            },
          ),
          if(currentUser != null && currentUser!.isAnonymous == false)
            ListTile(
              title: Text(AppLocale.name.getString(context)),
              subtitle: Text(name),
              onTap: () {
                _settingsHelper.updateUserName(context);
              },
            ),
          if(currentUser != null && currentUser!.isAnonymous == false)
            ListTile(
              title: Text(AppLocale.profilePicture.getString(context)),
              onTap: () {
                _settingsHelper.updateProfilePicture(context);
              },
            ),
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
                    title: Text(AppLocale.selectLanguage.getString(context)),
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
            subtitle: Text(version),
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
          simpleDivider,
          ListTile(
            title: Text(AppLocale.settingsExportDataTitle.getString(context)),
            onTap: () {
              _settingsHelper.exportData(context);
            },
          ),
          simpleDivider,
          ListTile(
            title: Text(AppLocale.settingsImportDataTitle.getString(context)),
            onTap: () async { // Make onTap async
              bool importSuccess = await _settingsHelper.importData(context, (User? importedUserData) {
                setState(() {
                  if (importedUserData != null) {
                    // Authenticated import: Update screen's local myCurrentUser
                    myCurrentUser = importedUserData;
                  } else {
                    // Anonymous import: Local shared prefs changed.
                    // Global myCurrentUserGlobal would have been nulled out or set to guest by helper.
                    // Reflect this in the local state for UI.
                    myCurrentUser = null;
                  }
                });
              }, () => setState(() {})); // General UI refresh callback

              if (importSuccess && mounted) { // Check if mounted before using context for Navigator
                Navigator.pop(context, true); // Pop with true to signal HomePage
              }
            },
          ),
          const Divider(color: Color(0x56ff0000)),
          ListTile(
            title: Text(
              AppLocale.deleteAll.getString(context),
              style: redTextsStyle,
            ),
            subtitle: Text(
              AppLocale.deleteAllSubtitle.getString(context),
              style: redSubTextsStyle,
            ),
            onTap: () {
              _settingsHelper.deleteAllDataAndAccount(context, () {
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                  (Route<dynamic> route) => false,
                );
              });
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
    Navigator.pop(context); // Pop the language selection dialog
    // No, we should not pop settings screen, but refresh it.
    // However, the original code popped twice and pushed replacement.
    // For now, to minimize behavioral change beyond refactoring:
    Navigator.pop(context); // Pop the settings screen itself
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage())); // Then push homepage
  }

  // The deleteAll method is now removed from _SettingsScreenState as its logic is in SettingsLogicHelper
}
