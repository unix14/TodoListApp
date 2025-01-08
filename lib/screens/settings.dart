
import 'package:flutter/material.dart';
import 'package:flutter_example/mixin/pwa_installer_mixin.dart';

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


class _SettingsScreenState extends State<SettingsScreen> with PWAInstallerMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"), // todo heb translation
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
            title: Text("Language"),
            subtitle: Text("Hebrew/Engish"), // todo
            onTap: () {
             // todo
            },
          ),
          ListTile(
            title: Text("Account"),
            subtitle: Text("todo@change.this"), // todo
            onTap: () {
             // todo
            },
          ),
          ListTile(
            title: Text("Version"),
            subtitle: Text("1.0.0"), // todo
            onTap: () {
             // todo
            },
          ),
          ListTile(
            title: Text("Install App"), // todo make it possible via archive screen // todo translation
            onTap: () {
              // todo
              if(isInstallable()) {
                showInstallPrompt();
              } else {
                // todo show error popup
              }
            },
          ),
          //todo add dangerous divider,
          // todo red color texts
          ListTile(
            title: Text("Delete All Archive"), // todo make it possible via archive screen
            onTap: () {
             // todo
            },
          ),
          ListTile(
            title: Text("Delete all user data"),
            onTap: () {
              // todo
            },
          ),
          ListTile(
            title: Text("Log out"),
            onTap: () {
              // todo
            },
          ),
          // todo add AdView?
        ],
      ),
    );
  }
}