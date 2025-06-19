const String appBaseUrl = "https://todo-later.web.app";
const String appGroupId = "group.com.eyalya94.tools.todoLater";
const String defaultProfilePicAsset = "assets/icons/Icon-192.png";
// Making defaultProfilePicUrl nullable as it might not always be available or could be an empty string.
// Using a const for the asset path is better for consistency.
const String? defaultProfilePicUrl = null; // Or some placeholder URL if absolutely needed, but asset path is preferred.

bool isLoggedIn = false;
String currentLocaleStr = "en";