
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_example/models/user.dart' as MyUser;


User? currentUser; // authenticationUser

MyUser.User? myCurrentUser; // MyUser

var isLoggedIn = false;

String currentLocaleStr = "en";

// Base URL for shareable links (e.g., for dynamic links or web app links)
// Used in ShareListDialog and potentially other places where full share links are constructed.
// Example: https://yourdomain.web.app/share (no trailing slash)
// or just https://yourdomain.web.app if paths are like /share/path
const String appBaseUrl = "https://todo-later.web.app";