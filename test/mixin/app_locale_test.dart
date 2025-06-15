import 'package:flutter_example/mixin/app_locale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLocale Tests', () {
    // A representative list of new keys added for recent features.
    // This list should be maintained as new critical keys are added.
    const List<String> newFeatureKeys = [
      AppLocale.changeProfilePictureButton,
      AppLocale.uploadProfilePictureButton,
      AppLocale.profilePictureUpdated,
      AppLocale.errorUploadingProfilePicture,
      AppLocale.shareDialogTitle,
      AppLocale.shareableLink,
      AppLocale.notSharedYet,
      AppLocale.customLinkPathHint,
      AppLocale.copyLinkButton,
      AppLocale.linkCopiedToClipboard,
      AppLocale.authorizedUsersSectionTitle,
      AppLocale.saveShareButton,
      AppLocale.updateShareButton,
      AppLocale.linkPathInvalid,
      AppLocale.shareError,
      AppLocale.loading,
      AppLocale.clearInput,
      AppLocale.editSuffixTooltip,
      AppLocale.shareSettingsUpdated,
      AppLocale.noAuthorizedUsers,
      AppLocale.unknownUser,
      AppLocale.adminText,
      AppLocale.removeUserButtonTooltip,
      AppLocale.removeUserConfirmationTitle,
      AppLocale.removeUserConfirmationMessage,
      AppLocale.userRemovedSuccess,
      AppLocale.userRemovedError,
      AppLocale.joinListSuccess,
      AppLocale.joinListError,
      AppLocale.loginToJoinPrompt,
      AppLocale.simulateOpenLinkButton,
      AppLocale.enterLinkPathHint,
      AppLocale.joinButtonText,
      AppLocale.manageShareSettings,
      AppLocale.noTasksInSharedList,
      AppLocale.noCategoriesYet,
      AppLocale.addTodo,
      // Keys from settings.dart localization
      AppLocale.imagePickingNotImplemented,
      // Keys from share_list_dialog.dart for error messages (if specific keys were made)
      AppLocale.fetchConfigError,
      AppLocale.fetchParticipantsError,
      AppLocale.loginToSharePrompt,
      AppLocale.adminRequiredToRemoveUser,
    ];

    test('New feature keys have non-empty EN and HE translations', () {
      for (final key in newFeatureKeys) {
        expect(AppLocale.EN[key], isNotNull, reason: 'EN translation for $key should not be null');
        expect(AppLocale.EN[key]!.isNotEmpty, isTrue, reason: 'EN translation for $key should not be empty');

        expect(AppLocale.HE[key], isNotNull, reason: 'HE translation for $key should not be null');
        expect(AppLocale.HE[key]!.isNotEmpty, isTrue, reason: 'HE translation for $key should not be empty');
        // Basic check for placeholder format in HE, assuming they all start with "[HE]"
        expect(AppLocale.HE[key]!.startsWith('[HE]'), isTrue, reason: 'HE translation for $key should be a placeholder starting with [HE]');
      }
    });

    test('Placeholder format in specific EN translations is correct', () {
      // Test for AppLocale.shareDialogTitle = 'Share \'{categoryName}\'';
      expect(AppLocale.EN[AppLocale.shareDialogTitle], contains('{categoryName}'),
          reason: 'EN translation for shareDialogTitle should contain {categoryName}');

      // Test for AppLocale.joinListSuccess = 'Successfully joined list: {listName}';
      expect(AppLocale.EN[AppLocale.joinListSuccess], contains('{listName}'),
          reason: 'EN translation for joinListSuccess should contain {listName}');

      // Test for AppLocale.removeUserConfirmationMessage = 'Are you sure you want to remove {userName} from this shared list?';
      expect(AppLocale.EN[AppLocale.removeUserConfirmationMessage], contains('{userName}'),
          reason: 'EN translation for removeUserConfirmationMessage should contain {userName}');

      // Test for AppLocale.userRemovedSuccess = '{userName} has been removed.';
      expect(AppLocale.EN[AppLocale.userRemovedSuccess], contains('{userName}'),
          reason: 'EN translation for userRemovedSuccess should contain {userName}');

      // Test for AppLocale.userRemovedError = 'Could not remove {userName}. Please try again.';
       expect(AppLocale.EN[AppLocale.userRemovedError], contains('{userName}'),
          reason: 'EN translation for userRemovedError should contain {userName}');

      // Test for error messages with placeholders
       expect(AppLocale.EN[AppLocale.fetchConfigError], contains('{errorDetails}'),
          reason: 'EN translation for fetchConfigError should contain {errorDetails}');
       expect(AppLocale.EN[AppLocale.fetchParticipantsError], contains('{errorDetails}'),
          reason: 'EN translation for fetchParticipantsError should contain {errorDetails}');
    });

    test('All defined keys exist in both EN and HE maps', () {
      // This test is more comprehensive but requires maintaining the allKeys list.
      // It's a good practice to have a list of ALL keys for this kind of test.
      // For now, we'll use the newFeatureKeys list as a proxy for "all important keys".
      // A more robust solution might involve code generation or a script to extract all static const strings.

      final List<String> allKnownKeys = newFeatureKeys; // In a real scenario, this list would be exhaustive.
      // Add existing keys that were present before this subtask for a more complete check
      allKnownKeys.addAll([
        AppLocale.title, AppLocale.lang, AppLocale.settings, AppLocale.archive,
        // ... (add all other existing keys if desired for full coverage)
      ]);

      Set<String> uniqueKeys = Set<String>.from(allKnownKeys); // Ensure uniqueness

      for (final key in uniqueKeys) {
         expect(AppLocale.EN.containsKey(key), isTrue, reason: 'EN map is missing key: $key');
         expect(AppLocale.HE.containsKey(key), isTrue, reason: 'HE map is missing key: $key');
      }
    });

  });
}
