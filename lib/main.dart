import 'package:flutter/material.dart';
import 'package:flutter_example/common/consts.dart';
import 'package:flutter_example/common/encrypted_shared_preferences_helper.dart';
import 'package:flutter_example/common/globals.dart';
import 'package:flutter_example/managers/app_initializer.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'screens/homepage.dart';
import 'screens/onboarding.dart';

void main() {
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
    FlutterLocalization.instance.onTranslatedLanguage = _onTranslatedLanguage;
    _currentLocale = Locale(currentLocaleStr);
    super.initState();
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