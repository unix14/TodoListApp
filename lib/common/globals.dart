
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_example/mixin/app_locale.dart';
import 'package:flutter_example/models/user.dart' as MyUser;


User? currentUser; // authenticationUser

MyUser.User? myCurrentUser; // MyUser

var isLoggedIn = false;

String currentLocaleStr = "en";


String appName = "Todo Later";


final List<String> motivationalKeys = [
  AppLocale.motivationalSentence1,
  AppLocale.motivationalSentence2,
  AppLocale.motivationalSentence3,
  AppLocale.motivationalSentence4,
  AppLocale.motivationalSentence5,
  AppLocale.motivationalSentence6,
  AppLocale.motivationalSentence7,
  AppLocale.motivationalSentence8,
  AppLocale.motivationalSentence9,
  AppLocale.motivationalSentence10,
  AppLocale.motivationalSentence11,
  AppLocale.motivationalSentence12,
  AppLocale.motivationalSentence13,
  AppLocale.motivationalSentence14,
  AppLocale.motivationalSentence15,
  AppLocale.motivationalSentence16,
  AppLocale.motivationalSentence17,
  AppLocale.motivationalSentence18,
  AppLocale.motivationalSentence19,
  AppLocale.motivationalSentence20,
  AppLocale.motivationalSentence21,
  AppLocale.motivationalSentence22,
  AppLocale.motivationalSentence23,
  AppLocale.motivationalSentence24,
  AppLocale.motivationalSentence25,
  AppLocale.motivationalSentence26,
  AppLocale.motivationalSentence27,
  AppLocale.motivationalSentence28,
  AppLocale.motivationalSentence29,
  AppLocale.motivationalSentence30,
];