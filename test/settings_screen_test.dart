import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:flutter_example/common/consts.dart';
// Real EncryptedSharedPreferencesHelper will be used, relying on SharedPreferences.setMockInitialValues
import 'package:flutter_example/models/user.dart' as app_user; // Alias for local User model
import 'package:flutter_example/screens/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_example/common/globals.dart';
import 'package:flutter_example/mixin/app_locale.dart';
import 'package:flutter_localization/flutter_localization.dart';

// Manual mock for firebase_auth.User
class MockFbUser implements fb_auth.User {
  @override
  final String uid;
  @override
  final String? email;
  // Add other fields if necessary, but keep it minimal for this test

  MockFbUser({required this.uid, this.email});

  // Implement other methods and properties as needed by the code under test
  // For SettingsScreen, only `uid` and `email` (potentially) are accessed via `currentUser`
  @override
  bool get emailVerified => false;
  @override
  bool get isAnonymous => false;
  @override
  fb_auth.UserMetadata get metadata => fb_auth.UserMetadata(0, 0); // Dummy data
  @override
  List<fb_auth.UserInfo> get providerData => [];
  @override
  Future<String> getIdToken([bool forceRefresh = false]) async => 'mock_token';
  @override
  Future<fb_auth.UserCredential> linkWithCredential(fb_auth.AuthCredential credential) {
    throw UnimplementedError();
  }
  @override
  Future<fb_auth.UserCredential> reauthenticateWithCredential(fb_auth.AuthCredential credential) {
    throw UnimplementedError();
  }
  @override
  Future<void> reload() async {}
  @override
  Future<void> sendEmailVerification([fb_auth.ActionCodeSettings? actionCodeSettings]) async {}
  @override
  Future<fb_auth.User> unlink(String providerId) {
    throw UnimplementedError();
  }
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
    SharedPreferences.setMockInitialValues({});
    isLoggedIn = false;
    currentUser = null; // This is fb_auth.User?
    myCurrentUser = null; // This is app_user.User?
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  testWidgets('deleteAll confirmation and action - Logged-out user',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget(const SettingsScreen()));

    // Wait for widgets to settle, especially if there are FutureBuilders or initState async work
    await tester.pumpAndSettle();


    final String deleteAllText = AppLocale.deleteAll.getString(tester.element(find.byType(SettingsScreen)));
    final String areYouSureText = AppLocale.areUsure.getString(tester.element(find.byType(SettingsScreen)));

    expect(find.text(deleteAllText), findsOneWidget);

    await tester.tap(find.text(deleteAllText));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(areYouSureText), findsOneWidget);

    // Using find.text('OK') as it's a common default.
    // If specific text like AppLocale.ok.getString(context) is used in DialogHelper, this should be updated.
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(kAllListSavedPrefs), "");
  });

  testWidgets('deleteAll confirmation and action - Logged-in user',
      (WidgetTester tester) async {
    isLoggedIn = true;
    currentUser = MockFbUser(uid: 'testuid123', email: 'test@example.com'); // Assign mock firebase user
    myCurrentUser = app_user.User(uid: "testuid123", email: "test@example.com", todoListItems: ["item1"]); // app specific user

    await tester.pumpWidget(buildTestableWidget(const SettingsScreen()));
    // Wait for widgets to settle
    await tester.pumpAndSettle();

    final String deleteAllText = AppLocale.deleteAll.getString(tester.element(find.byType(SettingsScreen)));
    final String areYouSureText = AppLocale.areUsure.getString(tester.element(find.byType(SettingsScreen)));

    expect(find.text(deleteAllText), findsOneWidget);

    await tester.tap(find.text(deleteAllText));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(areYouSureText), findsOneWidget);

    await tester.tap(find.text('OK'));
    // Increased timeout for pumpAndSettle can be useful if there are longer async operations,
    // but ideally, tests are fast. The original fix was about ensuring pop happens,
    // not about successful Firebase op, so this should be okay.
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(kAllListSavedPrefs), "");

    // As before, Firebase calls themselves are not mocked/verified here due to tool limitations.
    // The main check is that the dialog closes and local prefs are updated.
  });
}
