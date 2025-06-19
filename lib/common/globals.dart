// lib/common/globals.dart
const String appBaseUrl = "https://todo-later.web.app";
const String appGroupId = "group.com.eyalya94.tools.todoLater"; // As used in homepage
const String defaultProfilePicAsset = "assets/icons/Icon-192.png"; // As used in settings

// These might be managed by a state management solution or auth status in a real app,
// but if they are simple globals, ensure they are initialized appropriately.
// For example, isLoggedIn might be set after checking FirebaseAuth.instance.currentUser.
// For now, keeping them as they were if they existed, or simple defaults.
bool isLoggedIn = false;
String currentLocaleStr = "en";

// It's better practice to avoid mutable globals like isLoggedIn and currentLocaleStr.
// Consider managing these via a state management solution or app-level state.