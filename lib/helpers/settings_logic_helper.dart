import 'dart:convert';
import 'dart:typed_data'; // Required for Uint8List
// ignore_for_file: avoid_web_libraries_in_flutter, duplicate_ignore
import 'dart:html' as html if (dart.library.io) 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_example/auth/authenticator.dart';
import 'package:flutter_example/common/DialogHelper.dart';
import 'package:flutter_example/common/encrypted_shared_preferences_helper.dart';
import 'package:flutter_example/common/globals.dart';
import 'package:flutter_example/mixin/app_locale.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/models/todo_list_item.dart';
import 'package:flutter_example/repo/firebase_realtime_database_repository.dart';
import 'package:flutter_example/repo/firebase_repo_interactor.dart';
import 'package:flutter_localization/flutter_localization.dart';

import '../common/consts.dart';
// Removed import for 'onboarding.dart' as onNavigateToOnboarding is a VoidCallback, context is enough for navigation if needed by caller.


class SettingsLogicHelper {

  Future<void> exportData(BuildContext context) async {
    if (currentUser?.isAnonymous == true) {
      try {
        String todoListItemsJsonString = await EncryptedSharedPreferencesHelper.getString(kAllListSavedPrefs) ?? "[]";
        List<dynamic> todoListItems = jsonDecode(todoListItemsJsonString);
        List<String> categories = await EncryptedSharedPreferencesHelper.loadCategories();

        Map<String, dynamic> anonymousData = {
          "isAnonymous": true,
          "todoListItems": todoListItems,
          "categories": categories
        };
        final jsonString = jsonEncode(anonymousData);
        final String fileName = "local_user_data.json";

        if (kIsWeb) {
          final blob = html.Blob([utf8.encode(jsonString)], 'application/json');
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute("download", fileName)
            ..click();
          html.Url.revokeObjectUrl(url);
        } else {
          print("Exported JSON for anonymous user: $jsonString");
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.settingsAnonExportSuccess.getString(context))));
      } catch (e) {
        print("Error exporting anonymous data: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocale.settingsExportErrorGeneral.getString(context))));
      }
    } else if (currentUser != null && myCurrentUser != null) {
      try {
        final jsonString = jsonEncode(User.toJson(myCurrentUser!)); // myCurrentUser is not null here
        final String fileName = "user_data.json";

        if (kIsWeb) {
          final blob = html.Blob([utf8.encode(jsonString)], 'application/json');
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute("download", fileName)
            ..click();
          html.Url.revokeObjectUrl(url);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(AppLocale.settingsImportSuccess.getString(context))));
        } else {
          print("Exported JSON for authenticated user: $jsonString");
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(AppLocale.settingsImportErrorMobileNotFullyImplemented.getString(context))));
        }
      } catch (e) {
        print("Error exporting authenticated data: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocale.settingsExportErrorGeneral.getString(context))));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocale.settingsExportErrorNotLoggedIn.getString(context))));
    }
  }

  Future<bool> importData(BuildContext context, Function(User?) onUpdateLocalUserUI, VoidCallback refreshUI) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.isNotEmpty) {
        if (kIsWeb) {
            Uint8List? fileBytes = result.files.first.bytes;
            if (fileBytes != null) {
                String jsonString = utf8.decode(fileBytes);
                Map<String, dynamic> jsonData = jsonDecode(jsonString);
                bool isAnonymousImport = jsonData['isAnonymous'] == true;

                if (isAnonymousImport) {
                  bool? confirmAnon = await DialogHelper.showAlertDialog(
                    context,
                    AppLocale.settingsAnonImportTitle.getString(context),
                    AppLocale.settingsAnonImportConfirmMessage.getString(context),
                    () => Navigator.of(context).pop(true),
                    () => Navigator.of(context).pop(false),
                  );

                  if (confirmAnon == true) {
                    List<dynamic> todoListItemsRaw = jsonData['todoListItems'] as List<dynamic>;
                    List<String> categories = List<String>.from(jsonData['categories'] as List<dynamic>);

                    await EncryptedSharedPreferencesHelper.setString(kAllListSavedPrefs, jsonEncode(todoListItemsRaw));
                    await EncryptedSharedPreferencesHelper.saveCategories(categories);

                    currentUser = null; // Ensure global currentUser reflects anonymous state
                    myCurrentUser = null; // Ensure global myCurrentUser reflects no specific user data / guest
                    isLoggedIn = false; // Ensure global login state is false

                    onUpdateLocalUserUI(null);
                    refreshUI();

                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.settingsAnonImportSuccess.getString(context))));
                    return true;
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.settingsAnonImportCancelled.getString(context))));
                    return false;
                  }
                }

                // Authenticated User Import Logic
                if (currentUser == null || currentUser!.isAnonymous) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(AppLocale.settingsExportErrorNotLoggedIn.getString(context))));
                  return false;
                }

                User importedUser = User.fromJson(jsonData);

                bool? confirmAuth = await DialogHelper.showAlertDialog(
                  context,
                  AppLocale.settingsImportConfirmDialogTitle.getString(context),
                  AppLocale.settingsImportConfirmDialogMessage.getString(context),
                  () => Navigator.of(context).pop(true),
                  () => Navigator.of(context).pop(false),
                );

                if (confirmAuth == true) {
                  if (currentUser!.email != importedUser.email &&
                      currentUser!.email != null &&
                      importedUser.email != null &&
                      importedUser.email!.isNotEmpty) {
                     final String importedUserEmailString = importedUser.email!;
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(AppLocale.settingsImportErrorMismatchUser.getString(context).replaceFirst('{email}', importedUserEmailString))));
                    return false;
                  }

                  bool success = await FirebaseRepoInteractor.instance.updateUserData(importedUser);

                  if (success) {
                    myCurrentUser = importedUser; // Update the global instance
                    onUpdateLocalUserUI(importedUser);
                    refreshUI();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(AppLocale.settingsImportSuccess.getString(context))));
                    return true;
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(AppLocale.settingsImportErrorSaveFailed.getString(context))));
                    return false;
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(AppLocale.settingsImportCancelled.getString(context))));
                  return false;
                }
            } else { // fileBytes is null on web
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(AppLocale.settingsImportErrorNoFile.getString(context))));
                return false;
            }
        } else { // Non-Web
            String? filePath = result.files.first.path;
            if (filePath != null) {
                print("File path for mobile import: $filePath");
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(AppLocale.settingsImportErrorMobileNotFullyImplemented.getString(context))));
                return false; // Mobile import not fully implemented
            } else { // filePath is null on mobile
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(AppLocale.settingsImportErrorNoFile.getString(context))));
                 return false;
            }
        }
      } else {  // result is null or files.isEmpty
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocale.settingsImportErrorNoFile.getString(context))));
        return false;
      }
    } catch (e) {
      print("Error importing data: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error importing: ${e.toString()}")));
      return false;
    }
  }

  Future<void> deleteAllDataAndAccount(BuildContext context, VoidCallback onNavigateToOnboarding) async {
    if (currentUser?.isAnonymous == true) {
      bool? confirmAnon = await DialogHelper.showAlertDialog(
              context,
        AppLocale.settingsAnonDeleteDialogTitle.getString(context),
        AppLocale.settingsAnonDeleteDialogMessage.getString(context),
        () => Navigator.of(context).pop(true),
        () => Navigator.of(context).pop(false),
      );

      if (confirmAnon == true) {
        try {
          await EncryptedSharedPreferencesHelper.setString(kAllListSavedPrefs, "[]");
          await EncryptedSharedPreferencesHelper.saveCategories([]);
          print("Cleared local data for anonymous user.");
          myCurrentUser = null;
          isLoggedIn = false;

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.settingsAnonImportSuccess.getString(context).replaceFirst("imported", "deleted"))));
          onNavigateToOnboarding();
        } catch (e) {
           print("Error clearing local data for anonymous user: $e");
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.settingsAnonDeleteError.getString(context))));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.settingsImportCancelled.getString(context))));
      }
      return;
    }

    // Authenticated User Deletion Logic
    final String? userIdForRtdbDeletion = currentUser?.uid; // Use global currentUser
    final String? userEmailForLogging = myCurrentUser?.email ?? currentUser?.email; // Use globals

    bool? confirmAuth = await DialogHelper.showAlertDialog(
      context,
      AppLocale.areUsure.getString(context),
      AppLocale.settingsDeleteAccountDialogMessage.getString(context),
      () => Navigator.of(context).pop(true),
      () => Navigator.of(context).pop(false),
    );

    if (confirmAuth != true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocale.settingsImportCancelled.getString(context))));
        return;
    }

    try {
      await EncryptedSharedPreferencesHelper.setString(kAllListSavedPrefs, "[]");
      await EncryptedSharedPreferencesHelper.saveCategories([]);
      print("Cleared general shared preferences (authenticated user flow).");

      if (currentUser == null) { // Global currentUser check
        print("User became null unexpectedly. Navigating to onboarding.");
        onNavigateToOnboarding();
        return;
      }

      // Pre-cleanup using global myCurrentUser
      if (myCurrentUser != null) {
        print("Attempting to clear local todoListItems for user: ${userEmailForLogging ?? 'unknown email'} before full deletion.");
        User userCopyForModification = User.fromJson(User.toJson(myCurrentUser!));
        userCopyForModification.todoListItems = [];
        print("Local user copy's todoListItems cleared (not synced to Firebase).");
      }

      try {
        await Authenticator.deleteCurrentUserAccount();
        print("Successfully deleted user from Firebase Authentication.");
      } catch (e) {
        print("Failed to delete user from Firebase Authentication: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocale.settingsDeleteErrorAuthFailed.getString(context))));
        return;
      }

      if (userIdForRtdbDeletion != null && userIdForRtdbDeletion.isNotEmpty) {
        try {
          String userPath = "users/$userIdForRtdbDeletion";
          await FirebaseRealtimeDatabaseRepository.instance.deleteData(userPath);
          print("Successfully deleted user data from Firebase Realtime Database at path: $userPath");
        } catch (e) {
          print("Failed to delete user data from Firebase Realtime Database: $e");
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(AppLocale.settingsDeleteErrorCloudDataFailed.getString(context))));
        }
      } else {
        print("No userIdForRtdbDeletion available, skipping RTDB node deletion.");
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocale.settingsDeleteErrorCloudDataFailed.getString(context))));
      }

      await Authenticator.signOut();
      print("User signed out.");

      myCurrentUser = null;
      isLoggedIn = false;

      onNavigateToOnboarding();

    } catch (e) {
      print("Error during delete all data and account for authenticated user: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("An unexpected error occurred during deletion.")));
    }
  }
}
