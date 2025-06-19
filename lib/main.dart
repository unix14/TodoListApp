import 'package:flutter/material.dart';
import 'package:flutter_example/common/consts.dart';
import 'package:flutter_example/common/encrypted_shared_preferences_helper.dart';
import 'package:flutter_example/common/globals.dart';
import 'package:flutter_example/managers/app_initializer.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_example/mixin/app_locale.dart';
import 'package:home_widget/home_widget.dart';
import 'screens/homepage.dart';
import 'screens/onboarding.dart';
// import 'dart:convert'; // No longer needed directly here if not used
import 'package:flutter_example/common/encryption_helper.dart';

// Must be top-level or static function
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  print('[HomeWidget] backgroundCallback triggered with uri: $uri');
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter bindings are initialized
  await EncryptionHelper.initialize();
  // EncryptedSharedPreferencesHelper.initialize() might also be needed if it involves async plugin calls
  // However, if it's just setting up a variable or a synchronous Dart class, it might not be needed here.
  // For safety, let's assume it's quick and synchronous or already handled by main app's launch.
  // await EncryptedSharedPreferencesHelper.initialize();


  if (uri?.host == 'updatecounter') {
    // This part seems to be example code not directly used by the main app's widget functionality.
    // Actual logic for widget updates would depend on what data the widget needs.
  } else if (uri?.host == 'widgetclick') {
    print('[HomeWidget] Clicked on widget - specific action can be handled here.');
  }
  print('[HomeWidget] backgroundCallback completed.');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // REMOVED: await FlutterLocalization.instance.ensureInitialized(); // ensureInitialized is not needed if using init()
  await EncryptionHelper.initialize();
  await EncryptedSharedPreferencesHelper.initialize(); // Call initialize here

  HomeWidget.registerBackgroundCallback(backgroundCallback);

  // Initialize other app services and then run the app
  AppInitializer.initialize(andThen: (isAlreadyEnteredTodos) {
    runApp(MyApp(isAlreadyEnteredTodos: isAlreadyEnteredTodos));
  });
}

class MyApp extends StatefulWidget {
  final bool isAlreadyEnteredTodos;

  const MyApp({Key? key, required this.isAlreadyEnteredTodos}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FlutterLocalization _localization = FlutterLocalization.instance;
  Locale? _currentLocale; // Will be set by onTranslatedLanguage or init

  @override
  void initState() {
    super.initState();

    _localization.init(
      mapLocales: [
        const MapLocale('en', AppLocale.EN, fontFamily: 'Roboto'),
        const MapLocale('he', AppLocale.HE, fontFamily: 'Roboto'),
      ],
      initLanguageCode: 'en', // Default language
    );

    _localization.onTranslatedLanguage = _onTranslatedLanguage;
    // Set initial locale after init has processed
    _currentLocale = _localization.currentLocale;
  }

  void _onTranslatedLanguage(Locale? locale) {
    if (mounted) {
      setState(() {
        _currentLocale = locale;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo Later', // This title is not localized by flutter_localization here.
      color: Colors.blueAccent,
      debugShowCheckedModeBanner: false,
      locale: _currentLocale, // Driven by FlutterLocalization
      supportedLocales: _localization.supportedLocales,
      localizationsDelegates: _localization.localizationsDelegates,
      theme: ThemeData(
        useMaterial3: false, // Or true, based on your design preference
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        fontFamilyFallback: const ['Arial', 'Helvetica', 'sans-serif'],
        textTheme: const TextTheme( // Ensure Roboto is applied if default is different
          bodyLarge: TextStyle(fontFamily: 'Roboto'),
          bodyMedium: TextStyle(fontFamily: 'Roboto'),
          displayLarge: TextStyle(fontFamily: 'Roboto'),
          displayMedium: TextStyle(fontFamily: 'Roboto'),
          // Define other styles as needed
        ),
      ),
      home: isLoggedIn || widget.isAlreadyEnteredTodos
          ? const HomePage()
          : const OnboardingScreen(),
    );
  }
}