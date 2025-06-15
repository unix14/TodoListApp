import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:flutter_example/common/consts.dart';
import 'package:flutter_example/models/todo_list_item.dart'; // Import TodoListItem
// Real EncryptedSharedPreferencesHelper will be used, relying on SharedPreferences.setMockInitialValues
import 'package:flutter_example/models/user.dart' as app_user; // Alias for local User model
import 'package:flutter_example/screens/homepage.dart'; // Import HomePage
import 'package:flutter_example/screens/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_example/common/globals.dart';
import 'package:flutter_example/mixin/app_locale.dart';
import 'package:flutter_localization/flutter_localization.dart';

// Manual mock for firebase_auth.User (as before)
class MockFbUser implements fb_auth.User {
  @override
  final String uid;
  @override
  final String? email;

  MockFbUser({required this.uid, this.email});

  @override
  bool get emailVerified => false;
  @override
  bool get isAnonymous => false;
  @override
  fb_auth.UserMetadata get metadata => fb_auth.UserMetadata(0, 0);
  @override
  List<fb_auth.UserInfo> get providerData => [];
  @override
  Future<String> getIdToken([bool forceRefresh = false]) async => 'mock_token';
  @override
  Future<fb_auth.UserCredential> linkWithCredential(fb_auth.AuthCredential credential) => throw UnimplementedError();
  @override
  Future<fb_auth.UserCredential> reauthenticateWithCredential(fb_auth.AuthCredential credential) => throw UnimplementedError();
  @override
  Future<void> reload() async {}
  @override
  Future<void> sendEmailVerification([fb_auth.ActionCodeSettings? actionCodeSettings]) async {}
  @override
  Future<fb_auth.User> unlink(String providerId) => throw UnimplementedError();
  @override
  Future<void> updateDisplayName(String? displayName) async {}
  @override
  Future<void> updateEmail(String newEmail) async {}
  @override
  Future<void> updatePassword(String newPassword) async {}
  @override
  Future<void> updatePhoneNumber(fb_auth.PhoneAuthCredential credential) async {}
  @override
  Future<void> updatePhotoURL(String? photoUrl) async {}
  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail, [fb_auth.ActionCodeSettings? actionCodeSettings]) async {}
  @override
  String? get displayName => null;
  @override
  String? get photoURL => null;
  @override
  String? get tenantId => null;
  @override
  Future<void> delete() async {}
  @override
  List<fb_auth.MultiFactorInfo> get multiFactor => [];
  @override
  fb_auth.MultiFactor get mfa => throw UnimplementedError();
}

void main() {
  final FlutterLocalization localization = FlutterLocalization.instance;

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: child,
      localizationsDelegates: localization.localizationsDelegates,
      supportedLocales: localization.supportedLocales,
      locale: const Locale('en'),
      // Adding routes if direct navigation to SettingsScreen is needed in other tests,
      // though for this flow, we start at HomePage.
      routes: {
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    localization.init(
      mapLocales: [
        const MapLocale('en', AppLocale.EN, countryCode: 'US'),
        const MapLocale('he', AppLocale.HE, countryCode: 'IL'),
      ],
      initLanguageCode: 'en',
    );
  });

  setUp(() async {
    // Clear all preferences and reset global state
    SharedPreferences.setMockInitialValues({});
    isLoggedIn = false;
    currentUser = null;
    myCurrentUser = null;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  testWidgets('deleteAll confirmation and action - Logged-out user',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget(const SettingsScreen()));
    await tester.pumpAndSettle();

    final settingsScreenElement = tester.element(find.byType(SettingsScreen));
    final String deleteAllText = AppLocale.deleteAll.getString(settingsScreenElement);
    final String areYouSureText = AppLocale.areUsure.getString(settingsScreenElement);

    expect(find.text(deleteAllText), findsOneWidget);
    await tester.tap(find.text(deleteAllText));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(areYouSureText), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(kAllListSavedPrefs), "");
  });

  testWidgets('deleteAll confirmation and action - Logged-in user',
      (WidgetTester tester) async {
    isLoggedIn = true;
    currentUser = MockFbUser(uid: 'testuid123', email: 'test@example.com');
    myCurrentUser = app_user.User(uid: "testuid123", email: "test@example.com", todoListItems: [TodoListItem("item1", DateTime.now(), false)]);

    await tester.pumpWidget(buildTestableWidget(const SettingsScreen()));
    await tester.pumpAndSettle();

    final settingsScreenElement = tester.element(find.byType(SettingsScreen));
    final String deleteAllText = AppLocale.deleteAll.getString(settingsScreenElement);
    final String areYouSureText = AppLocale.areUsure.getString(settingsScreenElement);

    expect(find.text(deleteAllText), findsOneWidget);
    await tester.tap(find.text(deleteAllText));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(areYouSureText), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(kAllListSavedPrefs), "");
  });

  testWidgets('Full "delete all and refresh" flow from HomePage', (WidgetTester tester) async {
    // 1. Setup initial SharedPreferences state with some items
    final initialItems = [
      TodoListItem("Test Item 1", DateTime.now(), false),
      TodoListItem("Test Item 2", DateTime.now(), true),
    ];
    final String initialItemsJson = jsonEncode(initialItems.map((item) => item.toJson()).toList());
    SharedPreferences.setMockInitialValues({
      kAllListSavedPrefs: initialItemsJson,
      // Ensure other prefs used by HomePage or SettingsScreen are initialized if necessary
      // For example, categories if HomePage depends on them immediately.
      kCategoriesSavedPrefs: jsonEncode(["Work", "Personal"]),
    });

    // Reset globals that might affect initial state (isLoggedIn for menu items etc.)
    isLoggedIn = false; // Example: test as logged-out user for simplicity of Firebase interaction
    currentUser = null;
    myCurrentUser = null;

    // 2. Pump HomePage
    await tester.pumpWidget(buildTestableWidget(const HomePage()));
    await tester.pumpAndSettle(); // Allow HomePage to loadList and build

    // Verify initial items are present (optional, but good for sanity check)
    // This depends on how HomePage displays items, e.g., by text in ListTile
    // HomePage's FutureBuilder needs to complete.
    expect(find.text("Test Item 1"), findsOneWidget);
    expect(find.text("Test Item 2"), findsOneWidget);

    // 3. Navigate from HomePage to SettingsScreen
    // Find settings icon/button (assuming it's an Icon for this example)
    // The settings button is in a PopupMenuButton. First tap the menu button.
    final moreButton = find.byTooltip("More options"); // Or specific icon if PopupMenuButton has one
    if (moreButton.evaluate().isNotEmpty) { // Check if a more specific tooltip/icon exists
         await tester.tap(moreButton);
    } else {
        // Fallback to generic PopupMenuButton icon if specific not found
        await tester.tap(find.byIcon(Icons.more_vert));
    }
    await tester.pumpAndSettle(); // For menu to appear

    // Find "Settings" text in the menu. Need context for AppLocale.
    // Since HomePage is on screen, its context can be used.
    final homePageElement = tester.element(find.byType(HomePage));
    final String settingsText = AppLocale.settings.getString(homePageElement);
    await tester.tap(find.text(settingsText));
    await tester.pumpAndSettle(); // For navigation to SettingsScreen

    // Now on SettingsScreen
    expect(find.byType(SettingsScreen), findsOneWidget);
    final settingsScreenElement = tester.element(find.byType(SettingsScreen));

    // 4. Perform "Delete All" on SettingsScreen
    final String deleteAllText = AppLocale.deleteAll.getString(settingsScreenElement);
    await tester.tap(find.text(deleteAllText));
    await tester.pumpAndSettle(); // For confirmation dialog

    final String areYouSureText = AppLocale.areUsure.getString(settingsScreenElement);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(areYouSureText), findsOneWidget);

    await tester.tap(find.text('OK')); // Assuming 'OK' is the text for the confirm button
    await tester.pumpAndSettle(); // For delete, dialog pop, SettingsScreen pop, and HomePage rebuild

    // 5. Verify HomePage state
    // Check that HomePage is the current screen again
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(SettingsScreen), findsNothing);

    // Verify SharedPreferences was cleared for kAllListSavedPrefs
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(kAllListSavedPrefs), "");

    // Verify HomePage UI reflects an empty list
    // Items should be gone after loadList() re-fetches from now-empty prefs
    expect(find.text("Test Item 1"), findsNothing);
    expect(find.text("Test Item 2"), findsNothing);

    // If HomePage shows a specific widget for empty list, find that.
    // For example, if it shows "No items yet!", then:
    // expect(find.text("No items yet!"), findsOneWidget);
    // For now, just checking that the ListTiles for items are gone is sufficient.
    // The ListView itself might still exist, but be empty.
    // A common way items are displayed is via ListTile, check for absence of any.
    // This is a bit generic; more specific checks depend on HomePage's item widget structure.
    expect(find.byType(ListTile), findsNothing); // Assuming items are in ListTiles
                                                // This might be too broad if HomePage uses ListTiles for other things.
                                                // A more specific check would be to find ListTiles that contain item text.
  });
}
