// lib/common/globals.dart
import 'package:flutter_example/models/user.dart' as AppUser; // Added for type safety

const String appBaseUrl = "https://todo-later.web.app";
const String appGroupId = "group.com.eyalya94.tools.todoLater";
const String defaultProfilePicAsset = "assets/icons/Icon-192.png";

AppUser.User? currentUser; // Made settable and typed
String currentLocaleStr = "en";
bool isLoggedIn = false; // Added from main.dart usage