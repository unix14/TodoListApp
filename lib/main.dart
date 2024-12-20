import 'package:flutter/material.dart';
import 'package:flutter_example/common/globals.dart';
import 'package:flutter_example/managers/app_initializer.dart';


import 'screens/homepage.dart';
import 'screens/onboarding.dart';

void main() {
  AppInitializer.initialize(andThen: () {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo Later',
      color: Colors.blueAccent,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        primarySwatch: Colors.blue,
      ),
      //todo add rtl support??
      // home: Column(
      //   children: [
      home: isLoggedIn
          ? const HomePage(title: 'Todo Later')
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
//
//
}
