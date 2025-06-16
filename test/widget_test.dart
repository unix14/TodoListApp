// This is a basic Flutter widget test.

import 'dart:convert'; // For utf8.decode
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_example/mixin/app_locale.dart';
import 'package:flutter_example/screens/homepage.dart';
import 'package:flutter_example/common/globals.dart';
import 'package:flutter_example/common/consts.dart';
import 'package:flutter_example/common/encryption_helper.dart';
import 'package:flutter_example/common/encrypted_shared_preferences_helper.dart';
import 'package:flutter_example/main.dart' as app; // To access MyApp

// New Minimal Test Widget for TabBar Alignment
class MinimalTabBarTestWidget extends StatefulWidget {
  final Locale locale;

  const MinimalTabBarTestWidget({Key? key, required this.locale}) : super(key: key);

  @override
  _MinimalTabBarTestWidgetState createState() => _MinimalTabBarTestWidgetState();
}

class _MinimalTabBarTestWidgetState extends State<MinimalTabBarTestWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ensure FlutterLocalization is available if any descendant widgets use AppLocale
    // For this minimal widget with hardcoded tab text, it's less critical,
    // but good practice for consistency with the main app structure.
    final FlutterLocalization? localizationInstance = FlutterLocalization.instance;

    return MaterialApp(
      locale: widget.locale,
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('he', 'IL'),
        // Add other supported locales if MinimalTabBarTestWidget might use them
      ],
      localizationsDelegates: [
        if (localizationInstance != null) ...localizationInstance.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        appBar: AppBar(
          bottom: TabBar(
            controller: _tabController,
            tabAlignment: TabAlignment.start, // As per requirement
            tabs: const [
              Tab(text: 'Tab 1'),
              Tab(text: 'Tab 2'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            Center(child: Text('Content 1')),
            Center(child: Text('Content 2')),
          ],
        ),
      ),
    );
  }
}


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  SharedPreferences.setMockInitialValues({
    'flutter.languageCode': 'en',
    'flutter.$kAllListSavedPrefs': '[]',
    'flutter.${EncryptedSharedPreferencesHelper.kCategoriesListPrefs}': '[]',
  });

  ServicesBinding.instance.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (ByteData? message) async {
    if (message == null) return null;
    final String assetPath = utf8.decode(message.buffer.asUint8List());

    if (assetPath == "config/encryption_config.json") {
       final String mockConfig = '{"key":"your_mock_key_for_testing_123", "iv":"your_mock_iv_for_testing_123"}';
       return ByteData.view(Uint8List.fromList(mockConfig.codeUnits).buffer);
    }
    print('Attempted to load unmocked asset in test: $assetPath');
    return null;
  });


  group('HomePage Widget Tests', () {
    final FlutterLocalization localization = FlutterLocalization.instance;

    setUpAll(() async {
      await EncryptionHelper.initialize();
      await EncryptedSharedPreferencesHelper.initialize();

      // Initialize localization (it might read from SharedPreferences for initial locale)
      localization.init(
        mapLocales: [
          const MapLocale('en', AppLocale.EN, countryCode: 'US'),
          const MapLocale('he', AppLocale.HE, countryCode: 'IL'),
        ],
        initLanguageCode: 'en',
      );
    });

    setUp(() async {
      // Reset SharedPreferences for each test to ensure isolation
      SharedPreferences.setMockInitialValues({
        'flutter.languageCode': 'en', // Default language for each test
        'flutter.$kAllListSavedPrefs': '[]',
        'flutter.${EncryptedSharedPreferencesHelper.kCategoriesListPrefs}': '[]',
      });
      // Ensure FlutterLocalization instance uses the 'en' texts for the start of each test
      localization.translate('en');

      const MethodChannel('home_widget').setMockMethodCallHandler((MethodCall methodCall) async {
        if (methodCall.method == 'updateWidget') {
          return true;
        }
        if (methodCall.method == 'registerBackgroundCallback') {
          return true;
        }
        return null;
      });
    });

    tearDown(() {
       const MethodChannel('home_widget').setMockMethodCallHandler(null);
    });

    tearDownAll(() {
      // Clear the global listener to prevent issues if _MyAppState was disposed
      localization.onTranslatedLanguage = null;
    });

    testWidgets('Adding a todo calls HomeWidget.updateWidget', (WidgetTester tester) async {
      await tester.pumpWidget(app.MyApp(isAlreadyEnteredTodos: true));
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      await tester.enterText(textFieldFinder, 'New Test Todo');
      await tester.pump();

      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();
    });

    testWidgets('HomePage TabBar tabAlignment updates with locale', (WidgetTester tester) async {
      const englishLocale = Locale('en', 'US');
      const hebrewLocale = Locale('he', 'IL');

      Future<void> pumpHomePageWithLocale(Locale locale) async {
        final originalOnTranslatedLanguage = localization.onTranslatedLanguage;
        localization.onTranslatedLanguage = null;

        SharedPreferences.setMockInitialValues({
          'flutter.languageCode': locale.languageCode,
          'flutter.$kAllListSavedPrefs': '[]',
          'flutter.${EncryptedSharedPreferencesHelper.kCategoriesListPrefs}': '[]',
        });
        localization.translate(locale.languageCode);

        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            supportedLocales: const [
              englishLocale,
              hebrewLocale,
            ],
            localizationsDelegates: localization.localizationsDelegates, // Uses the list from FlutterLocalization
            home: const HomePage(),
          ),
        );
        await tester.pumpAndSettle(const Duration(seconds: 5));
        localization.onTranslatedLanguage = originalOnTranslatedLanguage;
      }

      // Test with English locale
      await pumpHomePageWithLocale(englishLocale);
      expect(find.byType(TabBar), findsOneWidget, reason: "TabBar should be present for English locale (HomePage)");
      TabBar tabBarEn = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBarEn.tabAlignment, TabAlignment.start, reason: "TabBar in HomePage should align to start for English locale");

      // Test with Hebrew locale
      await pumpHomePageWithLocale(hebrewLocale);
      expect(find.byType(TabBar), findsOneWidget, reason: "TabBar should be present for Hebrew locale (HomePage)");
      TabBar tabBarHe = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBarHe.tabAlignment, TabAlignment.start, reason: "TabBar in HomePage should align to start for Hebrew locale (effective right due to RTL)");
    });

    testWidgets('MinimalTabBarTestWidget tabAlignment is start for English and Hebrew', (WidgetTester tester) async {
      const englishLocale = Locale('en', 'US');
      const hebrewLocale = Locale('he', 'IL');

      // Test with English locale
      await tester.pumpWidget(MinimalTabBarTestWidget(locale: englishLocale));
      await tester.pumpAndSettle(); // Allow TabController to initialize and widget to build

      expect(find.byType(TabBar), findsOneWidget, reason: "TabBar should be present for English locale (MinimalWidget)");
      TabBar tabBarEnMinimal = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBarEnMinimal.tabAlignment, TabAlignment.start, reason: "TabBar in MinimalWidget should align to start for English locale");
      // Optionally, verify Directionality for English
      final MaterialApp materialAppEn = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final Directionality directionalityEn = tester.widget<Directionality>(find.descendant(of: find.byWidget(materialAppEn), matching: find.byType(Directionality)));
      expect(directionalityEn.textDirection, TextDirection.ltr, reason: "Directionality should be LTR for English");


      // Test with Hebrew locale
      await tester.pumpWidget(MinimalTabBarTestWidget(locale: hebrewLocale));
      await tester.pumpAndSettle(); // Re-pump with new locale

      expect(find.byType(TabBar), findsOneWidget, reason: "TabBar should be present for Hebrew locale (MinimalWidget)");
      TabBar tabBarHeMinimal = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBarHeMinimal.tabAlignment, TabAlignment.start, reason: "TabBar in MinimalWidget should align to start for Hebrew locale");
      // Optionally, verify Directionality for Hebrew
      final MaterialApp materialAppHe = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final Directionality directionalityHe = tester.widget<Directionality>(find.descendant(of: find.byWidget(materialAppHe), matching: find.byType(Directionality)));
      expect(directionalityHe.textDirection, TextDirection.rtl, reason: "Directionality should be RTL for Hebrew");
    });

    testWidgets('renders search IconButton in AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(app.MyApp(isAlreadyEnteredTodos: true));
      await tester.pumpAndSettle();

      // Find the AppBar
      final appBarFinder = find.byType(AppBar);
      expect(appBarFinder, findsOneWidget);

      // Find the search IconButton within the AppBar
      // We can find it by its icon or tooltip
      final searchIconFinder = find.widgetWithIcon(IconButton, Icons.search);
      final searchButtonInAppBarFinder = find.descendant(
        of: appBarFinder,
        matching: searchIconFinder,
      );

      expect(searchButtonInAppBarFinder, findsOneWidget, reason: "Search IconButton not found in AppBar");

      // Optionally, verify the tooltip as well
      // Note: This test runs with the default 'en' locale.
      final expectedSearchTooltip = AppLocale.EN[AppLocale.searchTodosTooltip] as String;
      final searchButtonWithTooltipFinder = find.widgetWithTooltip(IconButton, expectedSearchTooltip);
      final searchButtonInAppBarWithTooltipFinder = find.descendant(
        of: appBarFinder,
        matching: searchButtonWithTooltipFinder,
      );
      expect(searchButtonInAppBarWithTooltipFinder, findsOneWidget, reason: "Search IconButton with correct tooltip ('$expectedSearchTooltip') not found in AppBar");
    });

    // This test is being replaced by 'renders search UI toggle correctly' and 'tapping search icon toggles search mode and focuses TextField'
    // testWidgets('tapping search IconButton calls _handleSearch and prints to console', (WidgetTester tester) async {
    //   final List<String> logMessages = <String>[];
    //   final DebugPrintCallback originalDebugPrint = debugPrint;
    //   debugPrint = (String? message, {int? wrapWidth}) {
    //     if (message != null) {
    //       logMessages.add(message);
    //     }
    //     originalDebugPrint(message, wrapWidth: wrapWidth); // Call original to see output in test console
    //   };

    //   await tester.pumpWidget(app.MyApp(isAlreadyEnteredTodos: true));
    //   await tester.pumpAndSettle();

    //   final searchIconFinder = find.widgetWithIcon(IconButton, Icons.search);
    //   expect(searchIconFinder, findsOneWidget);

    //   await tester.tap(searchIconFinder);
    //   await tester.pump(); // Allow time for the tap event and debugPrint to process

    //   expect(logMessages, contains("Search button tapped! _isSearching is now true"),
    //       reason: "_handleSearch did not print the expected message or state was not updated.");

    //   // Restore original debugPrint
    //   debugPrint = originalDebugPrint;
      // Clear any specific SharedPreferences values set if necessary
      SharedPreferences.setMockInitialValues({
         'flutter.languageCode': 'en',
         'flutter.$kAllListSavedPrefs': '[]',
         'flutter.${EncryptedSharedPreferencesHelper.kCategoriesListPrefs}': '[]',
      });
    });

    // Helper function to set up SharedPreferences with mock data and pump the widget with a specific locale
    Future<void> _setupMockDataAndPump(
      WidgetTester tester,
      List<Map<String, dynamic>> todoItems,
      List<String> categories,
      Locale locale
    ) async {
      final String encryptedTodoList = await EncryptedSharedPreferencesHelper.encryptData(jsonEncode(todoItems));
      final String encryptedCategories = await EncryptedSharedPreferencesHelper.encryptData(jsonEncode(categories));

      SharedPreferences.setMockInitialValues({
        'flutter.languageCode': locale.languageCode,
        'flutter.$kAllListSavedPrefs': encryptedTodoList,
        'flutter.${EncryptedSharedPreferencesHelper.kCategoriesListPrefs}': encryptedCategories,
      });

      await EncryptedSharedPreferencesHelper.initialize(); // Re-initialize with new mock values
      localization.translate(locale.languageCode); // Set the FlutterLocalization instance to the correct language

      // Pump MyApp with the specified locale
      await tester.pumpWidget(app.MyApp(isAlreadyEnteredTodos: true, forcedLocale: locale));
      await tester.pumpAndSettle(const Duration(seconds: 2)); // Allow time for everything to load
    }

    final List<Map<String, dynamic>> defaultMockTodoItems = [
      {"text": "Apple task", "dateTime": DateTime.now().toIso8601String(), "isChecked": false, "category": "Fruit", "isArchived": false},
      {"text": "Banana task", "dateTime": DateTime.now().toIso8601String(), "isChecked": false, "category": "Fruit", "isArchived": false},
      {"text": "Carrot task", "dateTime": DateTime.now().toIso8601String(), "isChecked": false, "category": "Vegetable", "isArchived": false},
      {"text": "Apricot task", "dateTime": DateTime.now().toIso8601String(), "isChecked": false, "category": "Fruit", "isArchived": false},
      {"text": "Broccoli task", "dateTime": DateTime.now().toIso8601String(), "isChecked": false, "category": "Vegetable", "isArchived": false},
      {"text": "Uncategorized apple search test", "dateTime": DateTime.now().toIso8601String(), "isChecked": false, "category": null, "isArchived": false},
    ];
    final List<String> defaultMockCategories = ["Fruit", "Vegetable"];


    testWidgets('renders search UI toggle correctly (icon, textfield, close button)', (WidgetTester tester) async {
      await tester.pumpWidget(app.MyApp(isAlreadyEnteredTodos: true));
      await tester.pumpAndSettle();

      // Initially, search icon is present, TextField is not
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(1)); // The main todo input, not the search one
      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.byType(TabBar), findsOneWidget); // TabBar should be visible

      // Tap search icon to enter search mode
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle(); // Allow for focus node callback

      // Now, TextField (search bar) and close icon are present, search icon is not
      // There will be two TextFields: one for main input, one for search.
      // The search TextField is in the AppBar.
      final appBarSearchField = find.descendant(of: find.byType(AppBar), matching: find.byType(TextField));
      expect(appBarSearchField, findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.search), findsNothing); // Original search icon in actions is gone
      expect(find.byType(TabBar), findsNothing); // TabBar should be hidden

      // Tap close icon to exit search mode
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Back to initial state
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(appBarSearchField, findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.byType(TabBar), findsOneWidget); // TabBar should be visible again
    });

    testWidgets('tapping search icon toggles search mode and focuses TextField', (WidgetTester tester) async {
      await tester.pumpWidget(app.MyApp(isAlreadyEnteredTodos: true));
      await tester.pumpAndSettle();

      final searchIcon = find.byIcon(Icons.search);
      await tester.tap(searchIcon);
      await tester.pumpAndSettle(); // pumpAndSettle for state change and focus request

      final searchTextFieldInAppBar = find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(TextField),
      );
      expect(searchTextFieldInAppBar, findsOneWidget);

      // Check if the TextField in AppBar has focus
      TextField searchTextFieldWidget = tester.widget(searchTextFieldInAppBar);
      expect(searchTextFieldWidget.focusNode?.hasFocus, isTrue, reason: "Search TextField should have focus");
    });

    testWidgets('search in "All" category displays matching items', (WidgetTester tester) async {
      await _setupMockData(defaultMockTodoItems, defaultMockCategories);
      await tester.pumpWidget(app.MyApp(isAlreadyEnteredTodos: true));
      await tester.pumpAndSettle(const Duration(seconds: 2)); // Ensure tabs and list are loaded

      // Enter search mode
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Type search query
      final searchTextFieldInAppBar = find.descendant(of: find.byType(AppBar), matching: find.byType(TextField));
      await tester.enterText(searchTextFieldInAppBar, 'apple');
      await tester.pumpAndSettle();

      expect(find.text("Apple task"), findsOneWidget);
      expect(find.text("Uncategorized apple search test"), findsOneWidget);
      expect(find.text("Banana task"), findsNothing);
    });

    testWidgets('search in specific category displays categorized results with headers', (WidgetTester tester) async {
      await _setupMockData(defaultMockTodoItems, defaultMockCategories);
      await tester.pumpWidget(app.MyApp(isAlreadyEnteredTodos: true));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to "Fruit" category tab
      await tester.tap(find.text('Fruit')); // Assuming "Fruit" is a category name
      await tester.pumpAndSettle();

      // Enter search mode
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Type search query "task" (should match items in Fruit and Vegetable)
      final searchTextFieldInAppBar = find.descendant(of: find.byType(AppBar), matching: find.byType(TextField));
      await tester.enterText(searchTextFieldInAppBar, 'task');
      await tester.pumpAndSettle();

      // Verify items from current category "Fruit" appear first
      expect(find.text("Apple task"), findsOneWidget);
      expect(find.text("Banana task"), findsOneWidget);
      expect(find.text("Apricot task"), findsOneWidget);

      // Verify header for "Vegetable" category and its items
      final expectedVegetableHeader = (AppLocale.EN[AppLocale.resultsInCategory] as String).replaceAll('{categoryName}', 'Vegetable');
      expect(find.text(expectedVegetableHeader), findsOneWidget);
      expect(find.text("Carrot task"), findsOneWidget);
      expect(find.text("Broccoli task"), findsOneWidget);

      // Verify header for "Uncategorized" and its items
      await tester.enterText(searchTextFieldInAppBar, 'apple');
      await tester.pumpAndSettle();
      expect(find.text("Apple task"), findsOneWidget); // From current "Fruit"
      final expectedUncategorizedHeader = AppLocale.EN[AppLocale.uncategorizedResults] as String;
      expect(find.text(expectedUncategorizedHeader), findsOneWidget);
      expect(find.text("Uncategorized apple search test"), findsOneWidget);
    });

    testWidgets('search displays "No results found" message correctly in English and Hebrew', (WidgetTester tester) async {
      const query = 'nonexistentquery';

      // Test English
      await _setupMockDataAndPump(tester, defaultMockTodoItems, defaultMockCategories, const Locale('en', 'US'));
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      final searchFieldEN = find.descendant(of: find.byType(AppBar), matching: find.byType(TextField));
      await tester.enterText(searchFieldEN, query);
      await tester.pumpAndSettle();
      final expectedNoResultsEN = (AppLocale.EN[AppLocale.noResultsFound] as String).replaceAll('{query}', query);
      expect(find.text(expectedNoResultsEN), findsOneWidget);

      // Test Hebrew
      await _setupMockDataAndPump(tester, defaultMockTodoItems, defaultMockCategories, const Locale('he', 'IL'));
      // Need to re-find search icon after locale change and repump
      final appBarFinderHE = find.byType(AppBar);
      final searchIconFinderHE = find.descendant(of: appBarFinderHE, matching: find.byIcon(Icons.search));
      await tester.tap(searchIconFinderHE);
      await tester.pumpAndSettle();
      final searchFieldHE = find.descendant(of: find.byType(AppBar), matching: find.byType(TextField));
      await tester.enterText(searchFieldHE, query);
      await tester.pumpAndSettle();
      final expectedNoResultsHE = (AppLocale.HE[AppLocale.noResultsFound] as String).replaceAll('{query}', query);
      expect(find.text(expectedNoResultsHE), findsOneWidget);
    });

    testWidgets('TabBar visibility toggles with search mode', (WidgetTester tester) async {
      await tester.pumpWidget(app.MyApp(isAlreadyEnteredTodos: true));
      await tester.pumpAndSettle();

      // Initially, TabBar is visible
      expect(find.byType(TabBar), findsOneWidget);

      // Enter search mode
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // TabBar should be hidden
      expect(find.byType(TabBar), findsNothing);

      // Exit search mode
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // TabBar should be visible again
      expect(find.byType(TabBar), findsOneWidget);
    });

    // Best effort localization tests
    testWidgets('Search UI elements have expected tooltips and hints (English fallback)', (WidgetTester tester) async {
      await _setupMockData([], []); // No data needed, just UI
      await tester.pumpWidget(app.MyApp(isAlreadyEnteredTodos: true));
      await tester.pumpAndSettle();

      // ENGLISH
      await _setupMockDataAndPump(tester, [], [], const Locale('en', 'US'));
      final expectedSearchTooltipEN = AppLocale.EN[AppLocale.searchTodosTooltip] as String;
      expect(find.widgetWithTooltip(IconButton, expectedSearchTooltipEN), findsOneWidget);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      final appBarSearchFieldEN = find.descendant(of: find.byType(AppBar), matching: find.byType(TextField));
      expect(appBarSearchFieldEN, findsOneWidget);
      TextField searchTextFieldWidgetEN = tester.widget(appBarSearchFieldEN);
      final expectedHintTextEN = AppLocale.EN[AppLocale.searchTodosHint] as String;
      expect(searchTextFieldWidgetEN.decoration?.hintText, expectedHintTextEN);

      final expectedCloseTooltipEN = AppLocale.EN[AppLocale.closeSearchTooltip] as String;
      expect(find.widgetWithTooltip(IconButton, expectedCloseTooltipEN), findsOneWidget);

      // Exit search mode for next locale
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // HEBREW
      await _setupMockDataAndPump(tester, [], [], const Locale('he', 'IL'));
      final expectedSearchTooltipHE = AppLocale.HE[AppLocale.searchTodosTooltip] as String;
      // Need to re-find elements after locale change and repump
      final appBarFinderHE = find.byType(AppBar);
      final searchIconFinderHE = find.descendant(of: appBarFinderHE, matching: find.byIcon(Icons.search));
      expect(find.widgetWithTooltip(IconButton, expectedSearchTooltipHE), findsOneWidget);

      await tester.tap(searchIconFinderHE);
      await tester.pumpAndSettle();

      final appBarSearchFieldHE = find.descendant(of: find.byType(AppBar), matching: find.byType(TextField));
      expect(appBarSearchFieldHE, findsOneWidget);
      TextField searchTextFieldWidgetHE = tester.widget(appBarSearchFieldHE);
      final expectedHintTextHE = AppLocale.HE[AppLocale.searchTodosHint] as String;
      expect(searchTextFieldWidgetHE.decoration?.hintText, expectedHintTextHE);

      final expectedCloseTooltipHE = AppLocale.HE[AppLocale.closeSearchTooltip] as String;
      final closeButtonFinderHE = find.descendant(of: appBarFinderHE, matching: find.byIcon(Icons.close));
      expect(find.widgetWithTooltip(IconButton, expectedCloseTooltipHE), findsOneWidget);
    });

  });
}
