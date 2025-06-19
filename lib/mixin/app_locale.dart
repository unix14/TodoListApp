mixin AppLocale {
  static const String title = 'title';
  static const String lang = 'lang';
  static const String settings = 'settings';
  static const String archive = "archive";
  static const String installApp = "installApp";
  static const String deleteAll = "deleteAll";
  static const String appIsInstalled = "appIsInstalled";
  static const String deleteAllSubtitle = "deleteAllSubtitle";
  static const String logout = "logout";
  static const String login = "login";
  static const String add = "add";
  static const String enterTodoTextPlaceholder = "enterTodoTextPlaceholder";
  static const String account = "account";
  static const String version = "version";
  static const String name = "name"; // User's display name
  static const String archivedTodos = "archivedTodos";
  static const String guest = "guest";
  static const String unknown = "unknown";
  static const String archivedTodosSubtitle = "archivedTodosSubtitle";
  static const String close = "close";
  static const String loginWEmail = "loginWEmail";
  static const String loginAsGuest = "loginAsGuest";
  static const String todoLater = "todoLater"; // App name
  static const String email = "email";
  static const String password = "password";
  static const String or = "or";
  static const String ok = "ok";
  static const String signup = "signup";
  static const String cancel = "cancel";
  static const String todoExample1 = "todoExample1";
  static const String todoExample2 = "todoExample2";
  static const String todoExample3 = "todoExample3";
  static const String logoutText = "logoutText";
  static const String areUsure = "areUsure"; // Generic confirmation
  static const String deleteAllSubtext = "deleteAllSubtext";
  static const String doUwant2Delete = "doUwant2Delete"; // More specific confirmation
  static const String thisCantBeUndone = "thisCantBeUndone";
  static const String selectLanguage = "selectLanguage";

  static const String randomTaskMenuButton = 'randomTaskMenuButton';
  static const String randomTaskDialogTitle = 'randomTaskDialogTitle';
  static const String noTasksAvailableDialogTitle = 'noTasksAvailableDialogTitle';
  static const String noTasksAvailableDialogMessage = 'noTasksAvailableDialogMessage';

  static const String addCategoryTooltip = 'addCategoryTooltip';
  static const String uncategorizedCategory = 'uncategorizedCategory'; // "All"
  static const String itemUncategorizedSnackbar = 'itemUncategorizedSnackbar';
  static const String itemMovedSnackbar = 'itemMovedSnackbar'; // Takes {categoryName}
  static const String all = 'all'; // Alternative for "All" category if needed, usually same as uncategorizedCategory
  static const String addCategoryDialogTitle = 'addCategoryDialogTitle';
  static const String categoryNameHintText = 'categoryNameHintText';
  static const String categoryNameEmptyError = 'categoryNameEmptyError';
  static const String categoryNameExistsError = 'categoryNameExistsError';
  static const String cancelButtonText = 'cancelButtonText'; // Specific for dialogs
  static const String okButtonText = 'okButtonText'; // Specific for dialogs
  static const String editMenuItem = 'editMenuItem';
  static const String moveToCategoryMenuItem = 'moveToCategoryMenuItem';
  static const String deleteMenuItem = 'deleteMenuItem';
  static const String selectCategoryDialogTitle = 'selectCategoryDialogTitle';
  static const String addNewCategoryMenuItem = 'addNewCategoryMenuItem';
  static const String renameCategoryDialogTitle = 'renameCategoryDialogTitle';
  static const String renameButtonText = 'renameButtonText';
  static const String categoryRenamedSnackbar = 'categoryRenamedSnackbar'; // Takes {oldName}, {newName}
  static const String renameCategoryMenuButton = 'renameCategoryMenuButton';
  static const String deleteCategoryMenuButton = 'deleteCategoryMenuButton';
  static const String deleteCategoryConfirmationTitle = 'deleteCategoryConfirmationTitle';
  static const String deleteCategoryConfirmationMessage = 'deleteCategoryConfirmationMessage'; // Takes {categoryName}
  static const String categoryDeletedSnackbar = 'categoryDeletedSnackbar'; // Takes {categoryName}

  static const String motivationalSentence1 = 'motivationalSentence1';
  static const String motivationalSentence2 = 'motivationalSentence2';
  static const String motivationalSentence3 = 'motivationalSentence3';
  static const String motivationalSentence4 = 'motivationalSentence4';
  static const String motivationalSentence5 = 'motivationalSentence5'; // Often "empty list" message

  static const String tasksCount = 'tasksCount'; // Takes {count}
  static const String tasksCountSingular = 'tasksCountSingular';
  static const String tasksCountZero = 'tasksCountZero';

  static const String emptyTodoDialogTitle = 'emptyTodoDialogTitle';
  static const String emptyTodoDialogMessage = 'emptyTodoDialogMessage';
  static const String editTaskHintText = 'editTaskHintText';

  static const String timeFewSecondsAgo = 'timeFewSecondsAgo';
  static const String timeFewMinutesAgo = 'timeFewMinutesAgo';
  static const String timeMinuteAgo = 'timeMinuteAgo'; // Takes {minutes}
  static const String timeMinutesAgo = 'timeMinutesAgo'; // Takes {minutes}
  static const String timeHourAgo = 'timeHourAgo';   // Takes {hours}
  static const String timeHoursAgo = 'timeHoursAgo';   // Takes {hours}
  static const String timeYesterday = 'timeYesterday';
  static const String timeDaysAgo = 'timeDaysAgo';     // Takes {days}

  // ---- New Keys for Profile Picture & Sharing ----
  static const String changeProfilePictureButton = 'changeProfilePictureButton';
  static const String uploadProfilePictureButton = 'uploadProfilePictureButton';
  static const String profilePictureUpdated = 'profilePictureUpdated';
  static const String errorUploadingProfilePicture = 'errorUploadingProfilePicture'; // Can take {errorDetails}
  static const String imagePickingNotImplemented = 'imagePickingNotImplemented'; // For settings screen placeholder

  static const String shareDialogTitle = 'shareDialogTitle'; // Takes {categoryName}
  static const String shareableLink = 'shareableLink';
  static const String notSharedYet = 'notSharedYet';
  static const String customLinkPathHint = 'customLinkPathHint'; // For Share Dialog
  static const String copyLinkButton = 'copyLinkButton';
  static const String linkCopiedToClipboard = 'linkCopiedToClipboard';
  static const String authorizedUsersSectionTitle = 'authorizedUsersSectionTitle';
  static const String saveShareButton = 'saveShareButton';
  static const String updateShareButton = 'updateShareButton';
  static const String linkPathInvalid = 'linkPathInvalid'; // For Share Dialog & Join Dialog
  static const String shareError = 'shareError'; // Generic share error
  static const String loading = 'loading';
  static const String clearInput = 'clearInput'; // Tooltip for clearing text field
  static const String editSuffixTooltip = 'editSuffixTooltip'; // Tooltip for editing link suffix
  static const String shareSettingsUpdated = 'shareSettingsUpdated';
  static const String noAuthorizedUsers = 'noAuthorizedUsers';
  static const String unknownUser = 'unknownUser'; // For when user details can't be fetched
  static const String adminText = 'adminText';
  static const String removeUserButtonTooltip = 'removeUserButtonTooltip';
  static const String removeUserConfirmationTitle = 'removeUserConfirmationTitle';
  static const String removeUserConfirmationMessage = 'removeUserConfirmationMessage'; // Takes {userName}
  static const String userRemovedSuccess = 'userRemovedSuccess'; // Takes {userName}
  static const String userRemovedError = 'userRemovedError'; // Takes {userName}
  static const String adminRequiredToRemoveUser = 'adminRequiredToRemoveUser';
  static const String fetchConfigError = 'fetchConfigError'; // Takes {errorDetails}
  static const String fetchParticipantsError = 'fetchParticipantsError'; // Takes {errorDetails}
  static const String loginToSharePrompt = 'loginToSharePrompt'; // Added for ShareListDialog

  static const String joinListSuccess = 'joinListSuccess'; // Takes {listName}
  static const String joinListError = 'joinListError'; // Can take {errorDetails}
  static const String loginToJoinPrompt = 'loginToJoinPrompt';
  static const String joinSharedListMenuButtonName = 'joinSharedListMenuButtonName'; // Text for menu item / dialog title
  static const String enterLinkPathHint = 'enterLinkPathHint'; // For Join Dialog
  static const String joinButtonText = 'joinButtonText'; // For Join Dialog button

  static const String manageShareSettings = 'manageShareSettings'; // Menu item for already shared list by admin
  static const String noTasksInSharedList = 'noTasksInSharedList'; // Empty state for shared list
  static const String noCategoriesYet = 'noCategoriesYet'; // Overall empty state
  static const String addTodo = 'addTodo'; // FAB tooltip, if different from AppLocale.add
  static const String errorLoadingList = 'errorLoadingList'; // Takes {errorDetails} for StreamBuilder error
  static const String shareCategoryButtonTooltip = 'shareCategoryButtonTooltip';
  static const String personalTasksTab = 'personalTasksTab'; // For HomePage tabs
  static const String sharedWithYouTab = 'sharedWithYouTab'; // For HomePage tabs

  static const Map<String, dynamic> EN = {
    AppLocale.title: 'Todo List',
    AppLocale.lang: 'Language',
    AppLocale.settings: 'Settings',
    AppLocale.archive: "Archive",
    AppLocale.installApp: "Install App",
    AppLocale.deleteAll: "Delete All Todos",
    AppLocale.appIsInstalled: "App is already installed.",
    AppLocale.deleteAllSubtitle: "Permanently delete all your todos.",
    AppLocale.logout: "Logout",
    AppLocale.login: "Login",
    AppLocale.add: "Add",
    AppLocale.enterTodoTextPlaceholder: "What do you need to do?",
    AppLocale.account: "Account",
    AppLocale.version: "Version",
    AppLocale.name: "Name",
    AppLocale.archivedTodos: "Archived Todos",
    AppLocale.guest: "Guest",
    AppLocale.unknown: "Unknown",
    AppLocale.archivedTodosSubtitle: "View your archived todos.",
    AppLocale.close: "Close",
    AppLocale.loginWEmail: "Login with Email",
    AppLocale.loginAsGuest: "Login as Guest",
    AppLocale.todoLater: "TodoLater",
    AppLocale.email: "Email",
    AppLocale.password: "Password",
    AppLocale.or: "OR",
    AppLocale.ok: "OK",
    AppLocale.signup: "Sign Up",
    AppLocale.cancel: "Cancel",
    AppLocale.todoExample1: "Buy groceries for dinner 🛒",
    AppLocale.todoExample2: "Call the doctor to make an appointment 👨‍⚕️",
    AppLocale.todoExample3: "Finish the report for work 📝",
    AppLocale.logoutText: "Are you sure you want to log out?",
    AppLocale.areUsure: "Are you sure?",
    AppLocale.deleteAllSubtext: "Are you sure you want to delete all your todos?",
    AppLocale.doUwant2Delete: "Do you want to delete this item?",
    AppLocale.thisCantBeUndone: "This action cannot be undone.",
    AppLocale.selectLanguage: "Select Language",
    AppLocale.randomTaskMenuButton: 'Random Task',
    AppLocale.randomTaskDialogTitle: 'Your Random Task',
    AppLocale.noTasksAvailableDialogTitle: 'No Tasks Available',
    AppLocale.noTasksAvailableDialogMessage: 'You have no tasks to choose from!',
    AppLocale.addCategoryTooltip: 'Add new category',
    AppLocale.uncategorizedCategory: 'All',
    AppLocale.itemUncategorizedSnackbar: 'Item moved to "All"',
    AppLocale.itemMovedSnackbar: 'Item moved to {categoryName}',
    AppLocale.all: 'All',
    AppLocale.addCategoryDialogTitle: 'Add New Category',
    AppLocale.categoryNameHintText: 'Category name',
    AppLocale.categoryNameEmptyError: 'Category name cannot be empty',
    AppLocale.categoryNameExistsError: 'Category with this name already exists',
    AppLocale.cancelButtonText: 'Cancel',
    AppLocale.okButtonText: 'OK',
    AppLocale.editMenuItem: 'Edit',
    AppLocale.moveToCategoryMenuItem: 'Move to...',
    AppLocale.deleteMenuItem: 'Delete',
    AppLocale.selectCategoryDialogTitle: 'Select Category',
    AppLocale.addNewCategoryMenuItem: 'Add New Category...',
    AppLocale.renameCategoryDialogTitle: 'Rename Category',
    AppLocale.renameButtonText: 'Rename',
    AppLocale.categoryRenamedSnackbar: 'Category "{oldName}" renamed to "{newName}"',
    AppLocale.renameCategoryMenuButton: 'Rename Category',
    AppLocale.deleteCategoryMenuButton: 'Delete Category',
    AppLocale.deleteCategoryConfirmationTitle: 'Delete Category?',
    AppLocale.deleteCategoryConfirmationMessage: 'Are you sure you want to delete the category "{categoryName}"? All tasks within it will be moved to "All".',
    AppLocale.categoryDeletedSnackbar: 'Category "{categoryName}" deleted',
    AppLocale.motivationalSentence1: 'Great job on clearing your tasks! 🎉',
    AppLocale.motivationalSentence2: 'Nothing to see here. Add some tasks!',
    AppLocale.motivationalSentence3: 'All caught up! Time for a break? ☕',
    AppLocale.motivationalSentence4: 'Your todo list is empty. Well done!',
    AppLocale.motivationalSentence5: 'An empty list is a world of possibilities!',
    AppLocale.tasksCount: '{count} tasks',
    AppLocale.tasksCountSingular: '1 task',
    AppLocale.tasksCountZero: 'No tasks',
    AppLocale.emptyTodoDialogTitle: 'Task cannot be empty',
    AppLocale.emptyTodoDialogMessage: 'Please enter some text for your task.',
    AppLocale.editTaskHintText: 'Edit your task...',
    AppLocale.timeFewSecondsAgo: 'few seconds ago',
    AppLocale.timeFewMinutesAgo: 'few minutes ago',
    AppLocale.timeMinuteAgo: '{minutes} minute ago',
    AppLocale.timeMinutesAgo: '{minutes} minutes ago',
    AppLocale.timeHourAgo: '{hours} hour ago',
    AppLocale.timeHoursAgo: '{hours} hours ago',
    AppLocale.timeYesterday: 'yesterday',
    AppLocale.timeDaysAgo: '{days} days ago',
    AppLocale.changeProfilePictureButton: 'Change Profile Picture',
    AppLocale.uploadProfilePictureButton: 'Upload Picture',
    AppLocale.profilePictureUpdated: 'Profile picture updated!',
    AppLocale.errorUploadingProfilePicture: 'Error uploading profile picture: {errorDetails}',
    AppLocale.imagePickingNotImplemented: 'Image picking not implemented yet.',
    AppLocale.shareDialogTitle: 'Share "{categoryName}"',
    AppLocale.shareableLink: 'Shareable link:',
    AppLocale.notSharedYet: 'Not shared yet. Create a link to share.',
    AppLocale.customLinkPathHint: 'Custom link path (e.g., school-stuff)',
    AppLocale.copyLinkButton: 'Copy Link',
    AppLocale.linkCopiedToClipboard: 'Link copied to clipboard!',
    AppLocale.authorizedUsersSectionTitle: 'People with access',
    AppLocale.saveShareButton: 'Save & Share',
    AppLocale.updateShareButton: 'Update Share Settings',
    AppLocale.linkPathInvalid: 'Link path can only contain letters, numbers, and hyphens, and cannot be empty.',
    AppLocale.shareError: 'Could not update share settings. Please try again.',
    AppLocale.loading: 'Loading...',
    AppLocale.clearInput: 'Clear input',
    AppLocale.editSuffixTooltip: 'Edit link path',
    AppLocale.shareSettingsUpdated: 'Share settings updated!',
    AppLocale.noAuthorizedUsers: 'No other users have access yet.',
    AppLocale.unknownUser: 'Unknown User',
    AppLocale.adminText: '(Admin)',
    AppLocale.removeUserButtonTooltip: 'Remove user from list',
    AppLocale.removeUserConfirmationTitle: 'Remove User?',
    AppLocale.removeUserConfirmationMessage: 'Are you sure you want to remove {userName} from this shared list?',
    AppLocale.userRemovedSuccess: '{userName} has been removed.',
    AppLocale.userRemovedError: 'Could not remove {userName}. Please try again.',
    AppLocale.adminRequiredToRemoveUser: 'Only the list admin can remove users.',
    AppLocale.fetchConfigError: 'Error fetching share configuration: {errorDetails}',
    AppLocale.fetchParticipantsError: 'Error fetching participants: {errorDetails}',
    AppLocale.loginToSharePrompt: 'Please log in or sign up to create or update share settings.',
    AppLocale.joinListSuccess: 'Successfully joined list: "{listName}"',
    AppLocale.joinListError: 'Shared list not found or an error occurred.',
    AppLocale.loginToJoinPrompt: 'Please log in or sign up to join a shared list.',
    AppLocale.joinSharedListMenuButtonName: 'Join Shared List',
    AppLocale.enterLinkPathHint: 'Enter shared link path',
    AppLocale.joinButtonText: 'Join',
    AppLocale.manageShareSettings: 'Manage Sharing',
    AppLocale.noTasksInSharedList: 'No tasks in this shared list yet. Be the first to add one!',
    AppLocale.noCategoriesYet: 'No categories or shared lists yet. Add one below!',
    AppLocale.addTodo: 'Add Todo',
    AppLocale.errorLoadingList: 'Error loading list: {errorDetails}',
    AppLocale.shareCategoryButtonTooltip: 'Share this category',
    AppLocale.personalTasksTab: 'Personal',
    AppLocale.sharedWithYouTab: 'Shared',
  };

  static const Map<String, dynamic> HE = {
    AppLocale.title: 'המשימות שלי',
    AppLocale.lang: 'שפה',
    AppLocale.settings: 'הגדרות',
    AppLocale.archive: "ארכיון",
    AppLocale.installApp: "התקן אפליקציה",
    AppLocale.deleteAll: "מחק הכל",
    AppLocale.appIsInstalled: "האפליקציה כבר מותקנת.",
    AppLocale.deleteAllSubtitle: "מחק את כל המשימות שלך לצמיתות.",
    AppLocale.logout: "התנתק",
    AppLocale.login: "התחבר",
    AppLocale.add: "הוסף",
    AppLocale.enterTodoTextPlaceholder: "מה אתה צריך לעשות?",
    AppLocale.account: "חשבון",
    AppLocale.version: "גרסה",
    AppLocale.name: "שם",
    AppLocale.archivedTodos: "משימות בארכיון",
    AppLocale.guest: "אורח",
    AppLocale.unknown: "לא ידוע",
    AppLocale.archivedTodosSubtitle: "צפה במשימות שלך בארכיון.",
    AppLocale.close: "סגור",
    AppLocale.loginWEmail: "התחבר עם אימייל",
    AppLocale.loginAsGuest: "התחבר כאורח",
    AppLocale.todoLater: "TodoLater",
    AppLocale.email: "אימייל",
    AppLocale.password: "סיסמה",
    AppLocale.or: "או",
    AppLocale.ok: "אישור",
    AppLocale.signup: "הירשם",
    AppLocale.cancel: "ביטול",
    AppLocale.todoExample1: "לקנות מצרכים לארוחת ערב 🛒",
    AppLocale.todoExample2: "להתקשר לרופא לקבוע תור 👨‍⚕️",
    AppLocale.todoExample3: "לסיים את הדוח לעבודה 📝",
    AppLocale.logoutText: "האם אתה בטוח שברצונך להתנתק?",
    AppLocale.areUsure: "האם אתה בטוח?",
    AppLocale.deleteAllSubtext: "האם אתה בטוח שברצונך למחוק את כל המשימות שלך?",
    AppLocale.doUwant2Delete: "האם אתה רוצה למחוק פריט זה?",
    AppLocale.thisCantBeUndone: "לא ניתן לבטל פעולה זו.",
    AppLocale.selectLanguage: "בחר שפה",
    AppLocale.randomTaskMenuButton: '[HE] Random Task',
    AppLocale.randomTaskDialogTitle: '[HE] Your Random Task',
    AppLocale.noTasksAvailableDialogTitle: '[HE] No Tasks Available',
    AppLocale.noTasksAvailableDialogMessage: '[HE] You have no tasks to choose from!',
    AppLocale.addCategoryTooltip: '[HE] Add new category',
    AppLocale.uncategorizedCategory: 'הכל',
    AppLocale.itemUncategorizedSnackbar: '[HE] Item moved to "All"',
    AppLocale.itemMovedSnackbar: '[HE] Item moved to {categoryName}',
    AppLocale.all: 'הכל',
    AppLocale.addCategoryDialogTitle: '[HE] Add New Category',
    AppLocale.categoryNameHintText: '[HE] Category name',
    AppLocale.categoryNameEmptyError: '[HE] Category name cannot be empty',
    AppLocale.categoryNameExistsError: '[HE] Category with this name already exists',
    AppLocale.cancelButtonText: '[HE] Cancel',
    AppLocale.okButtonText: '[HE] OK',
    AppLocale.editMenuItem: '[HE] Edit',
    AppLocale.moveToCategoryMenuItem: '[HE] Move to...',
    AppLocale.deleteMenuItem: '[HE] Delete',
    AppLocale.selectCategoryDialogTitle: '[HE] Select Category',
    AppLocale.addNewCategoryMenuItem: '[HE] Add New Category...',
    AppLocale.renameCategoryDialogTitle: '[HE] Rename Category',
    AppLocale.renameButtonText: '[HE] Rename',
    AppLocale.categoryRenamedSnackbar: '[HE] Category "{oldName}" renamed to "{newName}"',
    AppLocale.renameCategoryMenuButton: '[HE] Rename Category',
    AppLocale.deleteCategoryMenuButton: '[HE] Delete Category',
    AppLocale.deleteCategoryConfirmationTitle: '[HE] Delete Category?',
    AppLocale.deleteCategoryConfirmationMessage: '[HE] Are you sure you want to delete the category "{categoryName}"? All tasks within it will be moved to "All".',
    AppLocale.categoryDeletedSnackbar: '[HE] Category "{categoryName}" deleted',
    AppLocale.motivationalSentence1: '[HE] Great job on clearing your tasks! 🎉',
    AppLocale.motivationalSentence2: '[HE] Nothing to see here. Add some tasks!',
    AppLocale.motivationalSentence3: '[HE] All caught up! Time for a break? ☕',
    AppLocale.motivationalSentence4: '[HE] Your todo list is empty. Well done!',
    AppLocale.motivationalSentence5: '[HE] An empty list is a world of possibilities!',
    AppLocale.tasksCount: '[HE] {count} tasks',
    AppLocale.tasksCountSingular: '[HE] 1 task',
    AppLocale.tasksCountZero: '[HE] No tasks',
    AppLocale.emptyTodoDialogTitle: '[HE] Task cannot be empty',
    AppLocale.emptyTodoDialogMessage: '[HE] Please enter some text for your task.',
    AppLocale.editTaskHintText: '[HE] Edit your task...',
    AppLocale.timeFewSecondsAgo: '[HE] few seconds ago',
    AppLocale.timeFewMinutesAgo: '[HE] few minutes ago',
    AppLocale.timeMinuteAgo: '[HE] {minutes} minute ago',
    AppLocale.timeMinutesAgo: '[HE] {minutes} minutes ago',
    AppLocale.timeHourAgo: '[HE] {hours} hour ago',
    AppLocale.timeHoursAgo: '[HE] {hours} hours ago',
    AppLocale.timeYesterday: '[HE] yesterday',
    AppLocale.timeDaysAgo: '[HE] {days} days ago',
    AppLocale.changeProfilePictureButton: '[HE] Change Profile Picture',
    AppLocale.uploadProfilePictureButton: '[HE] Upload Picture',
    AppLocale.profilePictureUpdated: '[HE] Profile picture updated!',
    AppLocale.errorUploadingProfilePicture: '[HE] Error uploading profile picture: {errorDetails}',
    AppLocale.imagePickingNotImplemented: '[HE] Image picking not implemented yet.',
    AppLocale.shareDialogTitle: '[HE] Share "{categoryName}"',
    AppLocale.shareableLink: '[HE] Shareable link:',
    AppLocale.notSharedYet: '[HE] Not shared yet. Create a link to share.',
    AppLocale.customLinkPathHint: '[HE] Custom link path (e.g., school-stuff)',
    AppLocale.copyLinkButton: '[HE] Copy Link',
    AppLocale.linkCopiedToClipboard: '[HE] Link copied to clipboard!',
    AppLocale.authorizedUsersSectionTitle: '[HE] People with access',
    AppLocale.saveShareButton: '[HE] Save & Share',
    AppLocale.updateShareButton: '[HE] Update Share Settings',
    AppLocale.linkPathInvalid: '[HE] Link path can only contain letters, numbers, and hyphens, and cannot be empty.',
    AppLocale.shareError: '[HE] Could not update share settings. Please try again.',
    AppLocale.loading: '[HE] Loading...',
    AppLocale.clearInput: '[HE] Clear input',
    AppLocale.editSuffixTooltip: '[HE] Edit link path',
    AppLocale.shareSettingsUpdated: '[HE] Share settings updated!',
    AppLocale.noAuthorizedUsers: '[HE] No other users have access yet.',
    AppLocale.unknownUser: '[HE] Unknown User',
    AppLocale.adminText: '[HE] (Admin)',
    AppLocale.removeUserButtonTooltip: '[HE] Remove user from list',
    AppLocale.removeUserConfirmationTitle: '[HE] Remove User?',
    AppLocale.removeUserConfirmationMessage: '[HE] Are you sure you want to remove {userName} from this shared list?',
    AppLocale.userRemovedSuccess: '[HE] {userName} has been removed.',
    AppLocale.userRemovedError: '[HE] Could not remove {userName}. Please try again.',
    AppLocale.adminRequiredToRemoveUser: '[HE] Only the list admin can remove users.',
    AppLocale.fetchConfigError: '[HE] Error fetching share configuration: {errorDetails}',
    AppLocale.fetchParticipantsError: '[HE] Error fetching participants: {errorDetails}',
    AppLocale.loginToSharePrompt: '[HE] Please log in or sign up to create or update share settings.',
    AppLocale.joinListSuccess: '[HE] Successfully joined list: "{listName}"',
    AppLocale.joinListError: '[HE] Shared list not found or an error occurred.',
    AppLocale.loginToJoinPrompt: '[HE] Please log in or sign up to join a shared list.',
    AppLocale.joinSharedListMenuButtonName: '[HE] Join Shared List',
    AppLocale.enterLinkPathHint: '[HE] Enter shared link path',
    AppLocale.joinButtonText: '[HE] Join',
    AppLocale.manageShareSettings: '[HE] Manage Sharing',
    AppLocale.noTasksInSharedList: '[HE] No tasks in this shared list yet. Be the first to add one!',
    AppLocale.noCategoriesYet: '[HE] No categories or shared lists yet. Add one below!',
    AppLocale.addTodo: '[HE] Add Todo',
    AppLocale.errorLoadingList: '[HE] Error loading list: {errorDetails}',
    AppLocale.shareCategoryButtonTooltip: '[HE] Share this category',
    AppLocale.personalTasksTab: '[HE] Personal',
    AppLocale.sharedWithYouTab: '[HE] Shared',
  };
}
