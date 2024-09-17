import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_example/firebase_options.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AppInitializer class is responsible for initializing the app.
/// It ensures that the app is initialized with all the necessary services before it starts.
/// It initializes Firebase, Google Mobile Ads, and other services can be added in the future.
class AppInitializer {

  //todo add crash detection and analytics with Firebase
  static Future<void> initialize({required Function andThen}) async {
    WidgetsFlutterBinding.ensureInitialized();
    MobileAds.instance.initialize();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
    andThen();
  }
}