import 'package:flutter/material.dart';
import 'package:flutter_example/common/consts.dart';
import 'package:flutter_example/common/encrypted_shared_preferences_helper.dart';
import 'package:flutter_example/common/globals.dart';
import 'package:flutter_example/managers/app_initializer.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_example/mixin/app_locale.dart'; // Added for AppLocale.EN/HE
import 'package:home_widget/home_widget.dart';
import 'screens/homepage.dart';
import 'screens/onboarding.dart'; // Moved up
import 'package:flutter_example/common/encrypted_shared_preferences_helper.dart';
import 'package:flutter_example/models/todo_list_item.dart';
import 'dart:convert';
import 'package:flutter_example/common/encryption_helper.dart';

// const String kCategoriesPrefKey = "categories"; // This seems to be defined locally or not used here. Keeping it commented.


// Must be top-level or static function
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  print('[HomeWidget] backgroundCallback triggered with uri: $uri');
  // Initialize Flutter specific services
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize encryption if you need to decrypt/encrypt data
  await EncryptionHelper.initialize();
  // Initialize SharedPreferences
  // Note: EncryptedSharedPreferencesHelper itself might need initialization if it's not static or uses a plugin that needs it.
  // For this example, assuming direct SharedPreferences or that EncryptedSharedPreferencesHelper is safe to call.

  if (uri?.host == 'updatecounter') { // Example action, not used in our current widget
    // ...
  } else if (uri?.host == 'widgetclick') {
    print('[HomeWidget] Clicked on widget');
    // This area could be used if the widget itself sends data back via URI.
    // For now, our widget launches MainActivity directly.
  }

  // This callback is primarily for updating widget data when requested by OS or other triggers.
  // The current widget reads directly from SharedPreferences.
  // So, the main app's responsibility is to ensure SharedPreferences is up-to-date.
  // This callback could be used to *force* an update of SharedPreferences if needed from a background context,
  // but typically, the widget updates itself by re-reading when notified.

  // For now, this callback doesn't need to do much more than log,
  // as the widget's RemoteViewsService (`TodoWidgetItemFactory`) fetches data directly from SharedPreferences.
  // If we needed to *push* data from Flutter to a live widget instance without it re-fetching,
  // we'd use HomeWidget.saveWidgetData and read it in Kotlin.
  // But our current design is widget pull from SharedPreferences.
  print('[HomeWidget] backgroundCallback completed.');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await FlutterLocalization.instance.ensureInitialized(); // Removed as per instruction
  // Initialize encryption helper
  await EncryptionHelper.initialize();

  // Initialize home_widget background callback
  HomeWidget.registerBackgroundCallback(backgroundCallback);

  // Original AppInitializer logic
  AppInitializer.initialize(andThen: (isAlreadyEnteredTodos) {
    runApp(MyApp(isAlreadyEnteredTodos: isAlreadyEnteredTodos));
  });
}

class MyApp extends StatefulWidget {
  bool isAlreadyEnteredTodos;

  MyApp({Key? key, required this.isAlreadyEnteredTodos}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  Locale? _currentLocale = const Locale("en");

  @override
  void initState() {
    super.initState(); // Call super.initState() first

    FlutterLocalization.instance.init(
      mapLocales: [
        const MapLocale('en', AppLocale.EN),
        const MapLocale('he', AppLocale.HE),
      ],
      initLanguageCode: 'en', // Set initial language
    );

    FlutterLocalization.instance.onTranslatedLanguage = _onTranslatedLanguage;
    // _currentLocale can be initialized from FlutterLocalization.instance.currentLocale after init
    // or rely on the onTranslatedLanguage callback to set it.
    // For simplicity, let's ensure it's set from the instance after init,
    // though onTranslatedLanguage should also fire.
    _currentLocale = FlutterLocalization.instance.currentLocale ?? Locale(currentLocaleStr);
  }

  // the setState function here is a must to add
  void _onTranslatedLanguage(Locale? locale) {
    setState(() {
      _currentLocale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo Later',
      color: Colors.blueAccent,
      debugShowCheckedModeBanner: false,
      locale: _currentLocale, // Set this dynamically
      supportedLocales: FlutterLocalization.instance.supportedLocales,
      localizationsDelegates: FlutterLocalization.instance.localizationsDelegates,
      theme: ThemeData(
        useMaterial3: false,
        primarySwatch: Colors.blue,
        // todo try to replicate no internet - fonts downloading issues
        // todo also check when there's no internet - if the user still logged in
        // todo else do relogin if needed ( we can encrypt email and pass inside the shared prefs )
        fontFamily: 'Roboto', // Use your font family here
        fontFamilyFallback: const ['Arial', 'Helvetica', 'sans-serif'], // Define fallbacks to local fonts
          textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Roboto'),
          bodyMedium: TextStyle(fontFamily: 'Roboto'),
          displayLarge: TextStyle(fontFamily: 'Roboto'),
          displayMedium: TextStyle(fontFamily: 'Roboto'),
          // Add more text styles as needed
        ),
      ),
      //todo add rtl support??
      // home: Column(
      //   children: [
      home: isLoggedIn || widget.isAlreadyEnteredTodos
          ? const HomePage()
          : const OnboardingScreen(),
      // todo use banner here??
      //     Container(
      //       alignment: Alignment.bottomCenter,
      //       child: adWidget,
      //       width: myBanner?.size.width.toDouble() ?? 0,
      //       height: myBanner?.size.height.toDouble() ?? 0,
      //     )
      //   ],
      // ),
    );
  }
}