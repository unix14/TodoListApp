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
import 'package:flutter_example/common/encryption_helper.dart';

// Must be top-level or static function
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  print('[HomeWidget] backgroundCallback triggered with uri: $uri');
  WidgetsFlutterBinding.ensureInitialized();
  await EncryptionHelper.initialize();
  await EncryptedSharedPreferencesHelper.initialize(); // Ensure helper is initialized for background

  // Potentially update widget data based on URI or other logic
  if (uri?.host == 'updatecounter') {
    // Example: int counter = await EncryptedSharedPreferencesHelper.getInt('counter') ?? 0;
    // await HomeWidget.saveWidgetData<int>('counter', counter);
    // await HomeWidget.updateWidget(name: 'TodoWidgetProvider', iOSName: 'TodoWidget');
  }
  print('[HomeWidget] backgroundCallback completed.');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // FlutterLocalization.instance.ensureInitialized() is NOT needed if using init()
  await EncryptionHelper.initialize();
  await EncryptedSharedPreferencesHelper.initialize();

  HomeWidget.registerBackgroundCallback(backgroundCallback);

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
  Locale? _currentLocale;

  @override
  void initState() {
    super.initState();

    _localization.init(
      mapLocales: [
        const MapLocale('en', AppLocale.EN, fontFamily: 'Roboto'),
        const MapLocale('he', AppLocale.HE, fontFamily: 'Roboto'),
      ],
      initLanguageCode: 'en',
    );

    _localization.onTranslatedLanguage = _onTranslatedLanguage;
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
      title: 'Todo Later',
      color: Colors.blueAccent,
      debugShowCheckedModeBanner: false,
      locale: _currentLocale,
      supportedLocales: _localization.supportedLocales,
      localizationsDelegates: _localization.localizationsDelegates,
      theme: ThemeData(
        useMaterial3: false,
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        fontFamilyFallback: const ['Arial', 'Helvetica', 'sans-serif'],
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Roboto'),
          bodyMedium: TextStyle(fontFamily: 'Roboto'),
          displayLarge: TextStyle(fontFamily: 'Roboto'),
          displayMedium: TextStyle(fontFamily: 'Roboto'),
        ),
      ),
      home: isLoggedIn || widget.isAlreadyEnteredTodos
          ? const HomePage()
          : const OnboardingScreen(),
    );
  }
}