import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:flutter_example/common/consts.dart';
import 'package:flutter_example/common/encrypted_shared_preferences_helper.dart'; // Import for kCategoriesListPrefs
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
    // Initialize EncryptedSharedPreferencesHelper for tests if it's not already
    // This is tricky as it's async and uses rootBundle. For widget tests,
    // we often rely on SharedPreferences.setMockInitialValues to bypass deeper init.
    // If EncryptedSharedPreferencesHelper.initialize() is strictly needed for kCategoriesListPrefs to be defined,
    // this setup might need more work, but typically static consts are available.
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    isLoggedIn = false;
    currentUser = null;
    myCurrentUser = null;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  testWidgets('deleteAll confirmation and action - Logged-out user',
      (WidgetTester tester) async {
    // This test remains as is, focusing on SettingsScreen isolation
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
    // Also check categories are cleared if this test implies full delete action
    expect(prefs.getString(EncryptedSharedPreferencesHelper.kCategoriesListPrefs), "[]");
  });

  testWidgets('deleteAll confirmation and action - Logged-in user',
      (WidgetTester tester) async {
    // This test remains as is, focusing on SettingsScreen isolation
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
    // Also check categories are cleared
    expect(prefs.getString(EncryptedSharedPreferencesHelper.kCategoriesListPrefs), "[]");
  });

  testWidgets('Full "delete all and refresh" flow from HomePage', (WidgetTester tester) async {
    final initialItems = [
      TodoListItem("Test Item 1", DateTime.now(), false),
      TodoListItem("Test Item 2", DateTime.now(), true),
    ];
    final initialCategories = ["Work", "Personal"];
    final String initialItemsJson = jsonEncode(initialItems.map((item) => item.toJson()).toList());
    final String initialCategoriesJson = jsonEncode(initialCategories);

    SharedPreferences.setMockInitialValues({
      kAllListSavedPrefs: initialItemsJson,
      EncryptedSharedPreferencesHelper.kCategoriesListPrefs: initialCategoriesJson,
    });

    isLoggedIn = false;
    currentUser = null;
    myCurrentUser = null;

    await tester.pumpWidget(buildTestableWidget(const HomePage()));
    await tester.pumpAndSettle();

    // Verify initial items
    expect(find.text("Test Item 1"), findsOneWidget);
    expect(find.text("Test Item 2"), findsOneWidget);

    // Verify initial tabs
    final homePageElementInitial = tester.element(find.byType(HomePage));
    final String allTextInitial = AppLocale.all.getString(homePageElementInitial);
    expect(find.widgetWithText(Tab, allTextInitial), findsOneWidget);
    expect(find.widgetWithText(Tab, "Work"), findsOneWidget);
    expect(find.widgetWithText(Tab, "Personal"), findsOneWidget);
    expect(find.widgetWithIcon(Tab, Icons.add), findsOneWidget);
    expect(find.byType(Tab), findsNWidgets(initialCategories.length + 2)); // "All", custom_cats, "+"

    // Navigate to Settings
    final moreButton = find.byIcon(Icons.more_vert); // Assuming this is the primary way
    expect(moreButton, findsOneWidget);
    await tester.tap(moreButton);
    await tester.pumpAndSettle();

    final String settingsText = AppLocale.settings.getString(homePageElementInitial);
    await tester.tap(find.text(settingsText));
    await tester.pumpAndSettle();

    // On SettingsScreen, perform Delete All
    expect(find.byType(SettingsScreen), findsOneWidget);
    final settingsScreenElement = tester.element(find.byType(SettingsScreen));
    final String deleteAllText = AppLocale.deleteAll.getString(settingsScreenElement);
    await tester.tap(find.text(deleteAllText));
    await tester.pumpAndSettle();

    final String areYouSureText = AppLocale.areUsure.getString(settingsScreenElement);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(areYouSureText), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Back on HomePage
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(SettingsScreen), findsNothing);

    // Verify SharedPreferences cleared
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(kAllListSavedPrefs), "");
    expect(prefs.getString(EncryptedSharedPreferencesHelper.kCategoriesListPrefs), "[]");

    // Verify HomePage UI reflects empty list
    expect(find.text("Test Item 1"), findsNothing);
    expect(find.text("Test Item 2"), findsNothing);
    // More specific check for item ListTiles if possible, for now, byType(ListTile) might be okay if no other ListTiles exist
    // Assuming HomePage shows no ListTiles when items are empty and not part of scaffold.
    // This check needs to be robust. If HomePage has other ListTiles, it will fail.
    // A better way: ensure no ListTile contains text of deleted items. (Already covered by text findsNothing)
    // Or ensure a specific "empty state" widget appears.

    // Verify TabBar UI update
    final homePageElementAfterDelete = tester.element(find.byType(HomePage));
    final String allTextAfterDelete = AppLocale.all.getString(homePageElementAfterDelete);

    expect(find.widgetWithText(Tab, allTextAfterDelete), findsOneWidget);
    expect(find.widgetWithIcon(Tab, Icons.add), findsOneWidget);
    expect(find.byType(Tab), findsNWidgets(2)); // Only "All" and "+" tabs should remain

    expect(find.text("Work"), findsNothing);
    expect(find.text("Personal"), findsNothing);
  });
}
