import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart'; // Not fully implemented
import 'package:flutter/material.dart';
// import 'package:flutter_example/common/common_styles.dart'; // Not used
import 'package:flutter_example/common/globals.dart';
import 'package:flutter_example/managers/app_initializer.dart'; // For getIt
import 'package:flutter_example/mixin/app_locale.dart';
import 'package:flutter_example/models/user.dart' as AppUser;
import 'package:flutter_example/repo/firebase_repo_interactor.dart';
// import 'package:image_picker/image_picker.dart'; // Not fully implemented
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_localization/flutter_localization.dart';


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
  File? _pickedImage;
  // bool _isUploading = false; // Optional: for loading indicator on upload

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
    _loadCurrentUser();
  }

  Future<void> _loadVersionInfo() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    }
  }

  Future<void> _loadCurrentUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      // Ensure getIt is initialized and FirebaseRepoInteractor is registered
      // This might require AppInitializer.initialize() to have completed
      // or for getIt to be configured synchronously if possible.
      final user = await getIt<FirebaseRepoInteractor>().getUserData(firebaseUser.uid);
      if (mounted) {
        setState(() {
          _isGuest = firebaseUser.isAnonymous;
          _currentUser = user;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isGuest = true;
          _currentUser = null;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    if (_isGuest || !mounted) return;
    // Placeholder for image picking logic (e.g., using image_picker)
    // final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
    // if (image != null) {
    //   if (mounted) setState(() => _pickedImage = File(image.path));
    // } else {
    //   // User canceled the picker
    // }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocale.imagePickingNotImplemented.getString(context))),
    );
  }

  Future<void> _uploadProfilePicture() async {
    if (_pickedImage == null || _currentUser == null || FirebaseAuth.instance.currentUser == null || !mounted) return;

    // setState(() => _isUploading = true); // Start loading indicator

    // Placeholder for upload logic (e.g., to Firebase Storage)
    // final userId = FirebaseAuth.instance.currentUser!.uid;
    // final storageRef = FirebaseStorage.instance.ref().child('profile_pictures/$userId/profile_pic.jpg');
    // try {
    //   await storageRef.putFile(_pickedImage!);
    //   final downloadUrl = await storageRef.getDownloadURL();

    //   _currentUser!.profilePictureUrl = downloadUrl;
    //   // Assuming saveUser is available in FirebaseRepoInteractor
    //   await getIt<FirebaseRepoInteractor>().saveUser(_currentUser!);

    //   if (mounted) {
    //     setState(() { _pickedImage = null; }); // Clear picked image
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(content: Text(AppLocale.profilePictureUpdated.getString(context))),
    //     );
    //   }
    // } catch (e) {
    //    if (mounted) {
    //      ScaffoldMessenger.of(context).showSnackBar(
    //        SnackBar(content: Text(AppLocale.errorUploadingProfilePicture.getString(context).replaceAll('{errorDetails}', e.toString()))),
    //      );
    //    }
    // } finally {
    //    if (mounted) setState(() => _isUploading = false); // Stop loading indicator
    // }

    // Using placeholder for now:
    const String placeholderDownloadUrl = "https://via.placeholder.com/150/007bff/FFFFFF?Text=Profile";
    _currentUser!.profilePictureUrl = placeholderDownloadUrl;
    await getIt<FirebaseRepoInteractor>().saveUser(_currentUser!); // Assumes saveUser exists
    if (mounted) {
      setState(() { _pickedImage = null; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocale.profilePictureUpdated.getString(context))),
      );
      // if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocale.settings.getString(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            _buildProfileSection(context),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(AppLocale.lang.getString(context)),
              trailing: DropdownButton<String>(
                value: FlutterLocalization.instance.currentLocale.languageCode,
                items: FlutterLocalization.instance.supportedLocales.map((Locale locale) {
                  return DropdownMenuItem<String>(
                    value: locale.languageCode,
                    child: Text(locale.languageCode.toUpperCase()),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    FlutterLocalization.instance.translate(newValue);
                    // The onTranslatedLanguage callback in _MyAppState handles UI rebuild for locale change
                  }
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(AppLocale.version.getString(context)),
              subtitle: Text('$_version ($_buildNumber)'),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: _isGuest ? Colors.grey : Theme.of(context).colorScheme.error),
              title: Text(
                _isGuest ? AppLocale.login.getString(context) : AppLocale.logout.getString(context),
                style: TextStyle(color: _isGuest ? Colors.grey : Theme.of(context).colorScheme.error),
              ),
              onTap: _isGuest
                  ? () {
                       if (mounted) Navigator.of(context).pushReplacementNamed('/onboarding');
                    }
                  : () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext dialogContext) { // Renamed context
                          return AlertDialog(
                            title: Text(AppLocale.logout.getString(dialogContext)),
                            content: Text(AppLocale.logoutText.getString(dialogContext)),
                            actions: <Widget>[
                              TextButton(
                                child: Text(AppLocale.cancelButtonText.getString(dialogContext)),
                                onPressed: () => Navigator.of(dialogContext).pop(false),
                              ),
                              TextButton(
                                child: Text(AppLocale.okButtonText.getString(dialogContext)),
                                onPressed: () => Navigator.of(dialogContext).pop(true),
                              ),
                            ],
                          );
                        },
                      );
                      if (confirmed == true && mounted) {
                        await FirebaseAuth.instance.signOut();
                        // Consider clearing any user-specific data or resetting state here
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
    String displayName = _isGuest ? AppLocale.guest.getString(context) : (_currentUser?.name ?? AppLocale.unknown.getString(context));
    String displayEmail = _isGuest ? "" : (_currentUser?.email ?? "");
    String? profilePicUrlToShow = _currentUser?.profilePictureUrl;

    ImageProvider<Object> backgroundImageProvider;
    if (_pickedImage != null) {
      backgroundImageProvider = FileImage(_pickedImage!);
    } else if (profilePicUrlToShow != null && profilePicUrlToShow.isNotEmpty) {
      backgroundImageProvider = NetworkImage(profilePicUrlToShow);
    } else {
      backgroundImageProvider = AssetImage(Globals.defaultProfilePicAsset);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _isGuest ? null : _pickImage,
          child: CircleAvatar(
            radius: 50,
            backgroundImage: backgroundImageProvider,
            child: (_pickedImage == null && (profilePicUrlToShow == null || profilePicUrlToShow.isEmpty))
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
        ),
        const SizedBox(height: 10),
        Text(displayName, style: Theme.of(context).textTheme.headlineSmall),
        if (displayEmail.isNotEmpty) Text(displayEmail, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 10),
        if (!_isGuest)
          ElevatedButton(
            onPressed: _pickImage,
            child: Text(AppLocale.changeProfilePictureButton.getString(context)),
          ),
        if (_pickedImage != null && !_isGuest)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: ElevatedButton(
              onPressed: _uploadProfilePicture,
              child: Text(AppLocale.uploadProfilePictureButton.getString(context)),
            ),
          ),
      ],
    );
  }
}
