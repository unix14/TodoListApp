
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_example/models/user.dart' as MyUser;


User? currentUser; // authenticationUser

MyUser.User? myCurrentUser; // MyUser

var isLoggedIn = false;

String currentLocaleStr = "en";


String appName = "Todo Later";