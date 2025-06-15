import 'dart:io'; // Placeholder, will be used with image_picker

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Placeholder, for Firebase Storage
import 'package:flutter/material.dart';
import 'package:flutter_example/common/common_styles.dart';
import 'package:flutter_example/common/context_extensions.dart';
import 'package:flutter_example/common/globals.dart';
import 'package:flutter_example/l10n/intl_en.arb';
import 'package:flutter_example/main.dart';
import 'package:flutter_example/managers/app_initializer.dart';
import 'package:flutter_example/mixin/app_locale.dart';
import 'package:flutter_example/models/user.dart' as AppUser;
import 'package:flutter_example/repo/firebase_repo_interactor.dart';
import 'package:image_picker/image_picker.dart'; // Placeholder, for image_picker
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';
  String _buildNumber = '';
  bool _isGuest = true;
  AppUser.User? _currentUser;
  File? _pickedImage; // To store the picked image file

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
    _loadCurrentUser();
  }

  Future<void> _loadVersionInfo() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  Future<void> _loadCurrentUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      final user = await getIt<FirebaseRepoInteractor>().getUser(firebaseUser.uid);
      setState(() {
        _isGuest = firebaseUser.isAnonymous;
        _currentUser = user;
      });
    } else {
      setState(() {
        _isGuest = true;
        _currentUser = null;
      });
    }
  }

  Future<void> _pickImage() async {
    if (_isGuest) return; // Should not happen if UI is correctly disabled

    // Placeholder for image_picker logic
    // final picker = ImagePicker();
    // final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    // if (pickedFile != null) {
    //   setState(() {
    //     _pickedImage = File(pickedFile.path);
    //   });
    //   _uploadProfilePicture();
    // }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Image picking logic to be implemented here.')),
    );
  }

  Future<void> _uploadProfilePicture() async {
    if (_pickedImage == null || _currentUser == null || FirebaseAuth.instance.currentUser == null) return;

    final userId = FirebaseAuth.instance.currentUser!.uid;
    final storageRef = FirebaseStorage.instance.ref().child('profile_pictures/$userId/profile_pic.jpg');

    try {
      // Placeholder for firebase_storage logic
      // await storageRef.putFile(_pickedImage!);
      // final downloadUrl = await storageRef.getDownloadURL();
      final String placeholderDownloadUrl = "https://via.placeholder.com/150/0000FF/808080?Text=Uploaded+Image"; // Simulated URL

      _currentUser!.profilePictureUrl = placeholderDownloadUrl; // downloadUrl;
      await getIt<FirebaseRepoInteractor>().saveUser(_currentUser!);

      setState(() {
        // UI will rebuild and show the new image via _currentUser.profilePictureUrl
        _pickedImage = null; // Clear picked image
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.translate(AppLocale.profilePictureUpdated))), // New Locale String
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.translate(AppLocale.errorUploadingProfilePicture)}: $e')), // New Locale String
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocale = Provider.of<AppLocaleViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.translate(AppLocale.settings)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            _buildProfileSection(context),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(context.translate(AppLocale.lang)),
              trailing: DropdownButton<String>(
                value: appLocale.currentLocale.languageCode,
                items: AppLocaleViewModel.supportedLocales.map((Locale locale) {
                  return DropdownMenuItem<String>(
                    value: locale.languageCode,
                    child: Text(locale.languageCode.toUpperCase()),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    appLocale.setLocale(Locale(newValue));
                  }
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(context.translate(AppLocale.version)),
              subtitle: Text('$_version ($_buildNumber)'),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: _isGuest ? Colors.grey : Colors.red),
              title: Text(
                _isGuest ? context.translate(AppLocale.login) : context.translate(AppLocale.logout),
                style: TextStyle(color: _isGuest ? Colors.grey : Colors.red),
              ),
              onTap: _isGuest
                  ? () {
                      // Navigate to login screen
                      Navigator.of(context).pushReplacementNamed('/onboarding');
                    }
                  : () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(context.translate(AppLocale.logout)),
                            content: Text(context.translate(AppLocale.logoutText)),
                            actions: <Widget>[
                              TextButton(
                                child: Text(context.translate(AppLocale.cancelButtonText)),
                                onPressed: () {
                                  Navigator.of(context).pop(false);
                                },
                              ),
                              TextButton(
                                child: Text(context.translate(AppLocale.okButtonText)),
                                onPressed: () {
                                  Navigator.of(context).pop(true);
                                },
                              ),
                            ],
                          );
                        },
                      );
                      if (confirmed == true) {
                        await FirebaseAuth.instance.signOut();
                        getIt<FirebaseRepoInteractor>().disposeUserSubscription();
                        Navigator.of(context).pushReplacementNamed('/onboarding');
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    String displayName = context.translate(AppLocale.guest);
    String displayEmail = "";
    String? profilePicUrl = Globals.defaultProfilePicUrl; // Use a global default

    if (!_isGuest && _currentUser != null) {
      displayName = _currentUser!.name ?? context.translate(AppLocale.unknown);
      displayEmail = _currentUser!.email ?? "";
      if (_currentUser!.profilePictureUrl != null && _currentUser!.profilePictureUrl!.isNotEmpty) {
        profilePicUrl = _currentUser!.profilePictureUrl;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _isGuest ? null : _pickImage,
          child: CircleAvatar(
            radius: 50,
            backgroundImage: _pickedImage != null
                ? FileImage(_pickedImage!)
                : (profilePicUrl != null ? NetworkImage(profilePicUrl) : AssetImage('assets/icons/Icon-192.png')) as ImageProvider,
            child: _isGuest || (_pickedImage == null && (profilePicUrl == null || profilePicUrl.isEmpty))
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
        ),
        const SizedBox(height: 10),
        Text(displayName, style: context.textTheme.headlineSmall),
        if (displayEmail.isNotEmpty) Text(displayEmail, style: context.textTheme.bodySmall),
        const SizedBox(height: 10),
        if (!_isGuest)
          ElevatedButton(
            onPressed: _pickImage,
            child: Text(context.translate(AppLocale.changeProfilePictureButton)), // New Locale String
          ),
        if (_pickedImage != null && !_isGuest) // Show upload button only if an image is picked
          ElevatedButton(
            onPressed: _uploadProfilePicture,
            child: Text(context.translate(AppLocale.uploadProfilePictureButton)), // New Locale String
          ),
      ],
    );
  }
}

// Add these new keys to AppLocale.dart and its EN/HE maps
// static const String changeProfilePictureButton = 'changeProfilePictureButton';
// static const String uploadProfilePictureButton = 'uploadProfilePictureButton';
// static const String profilePictureUpdated = 'profilePictureUpdated';
// static const String errorUploadingProfilePicture = 'errorUploadingProfilePicture';
// static const String defaultProfilePicUrl = 'assets/icons/default_avatar.png'; // Consider adding a default avatar to assets

// Remember to add defaultProfilePicUrl to Globals.dart if you plan to use it from there.
// e.g. static const String defaultProfilePicUrl = 'https://www.transparentpng.com/thumb/user/gray-user-profile-icon-png-fP8Q1P.png';
// or an asset path.
