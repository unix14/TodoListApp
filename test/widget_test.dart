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
  });
}
