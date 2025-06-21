mixin AppLocale {
  static const String account = "account";
  static const String add = "add";
  static const String addCategoryDialogTitle = 'addCategoryDialogTitle';
  static const String addCategoryTooltip = 'addCategoryTooltip';
  static const String addNewCategoryMenuItem = 'addNewCategoryMenuItem'; // Ensure this is added
  static const String all = 'all';
  static const String appIsInstalled = "appIsInstalled";
  static const String archive = "archive";
  static const String archivedTodos = "archivedTodos";
  static const String archivedTodosSubtitle = "archivedTodosSubtitle";
  static const String areUsure = "areUsure";
  static const String cancel = "cancel";
  static const String cancelButtonText = 'cancelButtonText';
  static const String categoryDeletedSnackbar = 'categoryDeletedSnackbar';
  static const String categoryNameEmptyError = 'categoryNameEmptyError';
  static const String categoryNameExistsError = 'categoryNameExistsError';
  static const String categoryNameHintText = 'categoryNameHintText';
  static const String categoryRenamedSnackbar = 'categoryRenamedSnackbar';
  static const String close = "close";
  static const String closeSearchTooltip = 'closeSearchTooltip';
  static const String deleteAll = "deleteAll";
  static const String deleteAllSubtext = "deleteAllSubtext";
  static const String deleteAllSubtitle = "deleteAllSubtitle";
  static const String deleteCategoryConfirmationMessage = 'deleteCategoryConfirmationMessage';
  static const String deleteCategoryConfirmationTitle = 'deleteCategoryConfirmationTitle';
  static const String deleteCategoryMenuButton = 'deleteCategoryMenuButton';
  static const String deleteMenuItem = 'deleteMenuItem';
  static const String doUwant2Delete = "doUwant2Delete";
  static const String editMenuItem = 'editMenuItem';
  static const String editTaskHintText = 'editTaskHintText';
  static const String email = "email";
  static const String emptyTodoDialogMessage = 'emptyTodoDialogMessage';
  static const String emptyTodoDialogTitle = 'emptyTodoDialogTitle';
  static const String enterSearchQueryPrompt = 'enterSearchQueryPrompt';
  static const String enterTodoTextPlaceholder = "enterTodoTextPlaceholder";
  static const String guest = "guest";
  static const String installApp = "installApp";
  static const String itemMovedSnackbar = 'itemMovedSnackbar';
  static const String itemUncategorizedSnackbar = 'itemUncategorizedSnackbar';
  static const String lang = 'lang';
  static const String login = "login";
  static const String loginAsGuest = "loginAsGuest";
  static const String loginWEmail = "loginWEmail";
  static const String logout = "logout";
  static const String logoutText = "logoutText";
  static const String motivationalSentence1 = 'motivationalSentence1';
  static const String motivationalSentence2 = 'motivationalSentence2';
  static const String motivationalSentence3 = 'motivationalSentence3';
  static const String motivationalSentence4 = 'motivationalSentence4';
  static const String motivationalSentence5 = 'motivationalSentence5';
  static const String moreResults = 'moreResults'; // Re-added
  static const String moveToCategoryMenuItem = 'moveToCategoryMenuItem';
  static const String name = "name";
  static const String noResultsFound = 'noResultsFound';
  static const String noTasksAvailableDialogMessage = 'noTasksAvailableDialogMessage';
  static const String noTasksAvailableDialogTitle = 'noTasksAvailableDialogTitle';
  static const String ok = "ok";
  static const String okButtonText = 'okButtonText';
  static const String or = "or";
  static const String password = "password";
  static const String randomTaskDialogTitle = 'randomTaskDialogTitle';
  static const String randomTaskMenuButton = 'randomTaskMenuButton';
  static const String renameButtonText = 'renameButtonText';
  static const String renameCategoryDialogTitle = 'renameCategoryDialogTitle';
  static const String renameCategoryMenuButton = 'renameCategoryMenuButton';
  // resultsFromAll removed as per redundancy check
  static const String resultsInCategory = 'resultsInCategory';
  static const String resultsInAllCategory = 'resultsInAllCategory';
  static const String searchTodosHint = 'searchTodosHint';
  static const String searchTodosTooltip = 'searchTodosTooltip';
  static const String selectCategoryDialogTitle = 'selectCategoryDialogTitle';
  static const String selectLanguage = "selectLanguage";
  static const String settings = 'settings';
  static const String signup = "signup";
  static const String tasksCount = 'tasksCount';
  static const String tasksFoundCount = 'tasksFoundCount'; // Added
  static const String tasksCountSingular = 'tasksCountSingular';
  static const String tasksCountZero = 'tasksCountZero';
  static const String thisCantBeUndone = "thisCantBeUndone";
  static const String timeDaysAgo = 'timeDaysAgo';
  static const String timeFewMinutesAgo = 'timeFewMinutesAgo';
  static const String timeFewSecondsAgo = 'timeFewSecondsAgo';
  static const String timeHourAgo = 'timeHourAgo';
  static const String timeHoursAgo = 'timeHoursAgo';
  static const String timeMinuteAgo = 'timeMinuteAgo';
  static const String timeMinutesAgo = 'timeMinutesAgo';
  static const String timeYesterday = 'timeYesterday';
  static const String title = 'title';
  static const String todoExample1 = "todoExample1";
  static const String todoExample2 = "todoExample2";
  static const String todoExample3 = "todoExample3";
  static const String todoLater = "todoLater";
  static const String uncategorizedCategory = 'uncategorizedCategory';
  static const String uncategorizedResults = 'uncategorizedResults';
  static const String unknown = "unknown";
  static const String version = "version";

  // Settings Screen - Import/Export & Delete Account
  static const String settingsExportDataTitle = 'settingsExportDataTitle';
  static const String settingsExportErrorNotLoggedIn = 'settingsExportErrorNotLoggedIn';
  static const String settingsExportErrorFetchFailed = 'settingsExportErrorFetchFailed';
  static const String settingsExportErrorGeneral = 'settingsExportErrorGeneral';
  static const String settingsImportDataTitle = 'settingsImportDataTitle';
  static const String settingsImportFileParseSuccess = 'settingsImportFileParseSuccess';
  static const String settingsImportErrorNoFile = 'settingsImportErrorNoFile';
  static const String settingsImportErrorMobileNotFullyImplemented = 'settingsImportErrorMobileNotFullyImplemented';
  static const String settingsImportConfirmDialogTitle = 'settingsImportConfirmDialogTitle';
  static const String settingsImportConfirmDialogMessage = 'settingsImportConfirmDialogMessage';
  static const String settingsImportErrorMismatchUser = 'settingsImportErrorMismatchUser'; // Will take {email}
  static const String settingsImportSuccess = 'settingsImportSuccess';
  static const String settingsImportErrorSaveFailed = 'settingsImportErrorSaveFailed';
  static const String settingsImportCancelled = 'settingsImportCancelled';
  static const String settingsDeleteAccountDialogMessage = 'settingsDeleteAccountDialogMessage'; // New message for the enhanced delete
  static const String settingsDeleteErrorAuthFailed = 'settingsDeleteErrorAuthFailed';
  static const String settingsDeleteErrorCloudDataFailed = 'settingsDeleteErrorCloudDataFailed';

  // Settings Screen - Anonymous User Flows
  static const String settingsAnonExportTitle = 'settingsAnonExportTitle';
  static const String settingsAnonExportSuccess = 'settingsAnonExportSuccess';
  static const String settingsAnonImportTitle = 'settingsAnonImportTitle';
  static const String settingsAnonImportConfirmMessage = 'settingsAnonImportConfirmMessage';
  static const String settingsAnonDeleteError = 'settingsAnonDeleteError';
  static const String settingsAnonImportSuccess = 'settingsAnonImportSuccess';
  static const String settingsAnonImportCancelled = 'settingsAnonImportCancelled';
  static const String settingsAnonDeleteDialogTitle = 'settingsAnonDeleteDialogTitle';
  static const String settingsAnonDeleteDialogMessage = 'settingsAnonDeleteDialogMessage';


  static const String loginFailedTitle = 'loginFailedTitle';
  static const String signupFailedTitle = 'signupFailedTitle';
  static const String authNoUserFound = 'authNoUserFound';
  static const String authWrongPassword = 'authWrongPassword';
  static const String authWeakPassword = 'authWeakPassword';
  static const String authEmailAlreadyInUse = 'authEmailAlreadyInUse';
  static const String authUnknownError = 'authUnknownError';
  static const String copiedToClipboard = 'copiedToClipboard';
  static const String editTodoHint = 'editTodoHint';
  static const String emptyTodoTitle = 'emptyTodoTitle';
  static const String emptyTodoMessage = 'emptyTodoMessage';
  static const String shareCategory = "shareCategory";
  static const String profilePicture = "profilePicture";
  static const String profilePictureUpdated = "profilePictureUpdated";
  static const String copyLink = 'copyLink';
  static const String sharedWith = 'sharedWith';
  static const String createdOn = 'createdOn';
  static const String shareFailed = "shareFailed";

  static const Map<String, dynamic> EN = {
    AppLocale.title: 'Todo List',
    AppLocale.lang: 'Language',
    AppLocale.settings: "Settings",
    AppLocale.archive: "Archive",
    AppLocale.installApp: "Install App",
    AppLocale.deleteAll: "Delete All",
    AppLocale.appIsInstalled: "App is installed",
    AppLocale.deleteAllSubtitle: "Delete all TODOs in the account, this action will also clear the archive",
    AppLocale.logout: "Log out",
    AppLocale.login: "Login",
    AppLocale.enterTodoTextPlaceholder: "Enter a Todo here..",
    AppLocale.add: "Add",
    AppLocale.account: "Account",
    AppLocale.version: "Version",
    AppLocale.name: "Name",
    AppLocale.archivedTodos: "Archived Todos",
    AppLocale.guest: "Guest",
    AppLocale.unknown: "unknown",
    AppLocale.archivedTodosSubtitle: "Todos are added to the archive after 24 hours since they're checked as done.",
    AppLocale.close: "Close",
    AppLocale.loginWEmail: "Login with Email",
    AppLocale.loginAsGuest: "Try as Guest",
    AppLocale.todoLater: "Todo Later",
    AppLocale.email: "Email",
    AppLocale.password: "Password",
    AppLocale.or: "or",
    AppLocale.ok: "OK",
    AppLocale.signup: "Signup",
    AppLocale.cancel: "Cancel",
    AppLocale.todoExample1: "Get clean clothes",
    AppLocale.todoExample2: "Buy gas",
    AppLocale.todoExample3: "Buy milk",
    AppLocale.logoutText: "Are you sure you want to logout?",
    AppLocale.areUsure: "Are you sure?",
    AppLocale.deleteAllSubtext: "Deleting all Todos will result in an empty list and an empty archive list. Do you really want to delete everything?",
    AppLocale.doUwant2Delete: "Do you want to delete?",
    AppLocale.thisCantBeUndone: "This can't be undone",
    AppLocale.selectLanguage: "Select Language",
    AppLocale.randomTaskMenuButton: "Random Task",
    AppLocale.randomTaskDialogTitle: "Randomly Selected Task",
    AppLocale.noTasksAvailableDialogTitle: "No Tasks",
    AppLocale.noTasksAvailableDialogMessage: "There are no tasks available to pick from.",
    AppLocale.addCategoryTooltip: 'Add new category',
    AppLocale.uncategorizedCategory: 'All',
    AppLocale.itemUncategorizedSnackbar: 'Item moved to All',
    // AppLocale.itemMovedSnackbar: 'Item moved to {categoryName}', // Already included below
    AppLocale.all: 'All',
    AppLocale.addCategoryDialogTitle: 'Add New Category',
    AppLocale.addNewCategoryMenuItem: 'Add New Category', // Ensured
    AppLocale.cancelButtonText: 'Cancel',
    AppLocale.categoryDeletedSnackbar: "Category '{categoryName}' deleted.",
    AppLocale.categoryNameEmptyError: 'Category name cannot be empty',
    AppLocale.categoryNameExistsError: 'Category name already exists',
    AppLocale.categoryNameHintText: 'Category name',
    AppLocale.categoryRenamedSnackbar: "Category '{oldName}' renamed to '{newName}'",
    AppLocale.closeSearchTooltip: "Close Search",
    AppLocale.deleteCategoryConfirmationMessage: "Are you sure you want to delete the category '{categoryName}'? All items in this category will be moved to 'All'.",
    AppLocale.deleteCategoryConfirmationTitle: "Delete Category?",
    AppLocale.deleteCategoryMenuButton: "Delete Current Category",
    AppLocale.deleteMenuItem: 'Delete',
    AppLocale.editMenuItem: 'Edit',
    AppLocale.editTaskHintText: 'Edit task...',
    AppLocale.emptyTodoDialogMessage: "Please write a Todo",
    AppLocale.emptyTodoDialogTitle: "Empty Todo",
    AppLocale.enterSearchQueryPrompt: "Type to start searching.",
    AppLocale.itemMovedSnackbar: 'Item moved to {categoryName}',
    // AppLocale.itemUncategorizedSnackbar: 'Item moved to All', // Already included above
    AppLocale.shareCategory: "Share Category",
    AppLocale.profilePicture: "Profile Picture",
    AppLocale.profilePictureUpdated: "Profile picture updated" ,
    AppLocale.shareFailed: "Could not share list",
    AppLocale.copiedToClipboard: "Copied to clipboard",
    AppLocale.copyLink: "Copy link",
    AppLocale.sharedWith: "Shared with",
    AppLocale.createdOn: "Created on {date}",
    AppLocale.motivationalSentence1: "Let's get something done!",
    AppLocale.motivationalSentence2: "What's on your mind today?",
    AppLocale.motivationalSentence3: "Time to be productive!",
    AppLocale.motivationalSentence4: "Add a task and feel the accomplishment.",
    AppLocale.motivationalSentence5: "An empty list is a world of possibilities!",
    AppLocale.moreResults: "More results", // Re-added
    AppLocale.moveToCategoryMenuItem: 'Move to category',
    AppLocale.noResultsFound: "No results found for '{query}'",
    // AppLocale.noTasksAvailableDialogMessage: "There are no tasks available to pick from.", // Already included above
    // AppLocale.noTasksAvailableDialogTitle: "No Tasks", // Already included above
    AppLocale.okButtonText: 'OK',
    // AppLocale.randomTaskDialogTitle: "Randomly Selected Task", // Already included above
    // AppLocale.randomTaskMenuButton: "Random Task", // Already included above
    AppLocale.renameButtonText: 'Rename',
    AppLocale.renameCategoryDialogTitle: 'Rename Category',
    AppLocale.renameCategoryMenuButton: "Rename Current Category",
    // AppLocale.resultsFromAll: "Results from All", // Removed
    AppLocale.resultsInCategory: "Results in {categoryName}",
    AppLocale.resultsInAllCategory: "More results",
    AppLocale.searchTodosHint: "Search Todos...",
    AppLocale.searchTodosTooltip: "Search Todos",
    AppLocale.selectCategoryDialogTitle: 'Select Category',
    AppLocale.tasksCount: "{count} tasks",
    AppLocale.tasksFoundCount: "{count} tasks found", // Added
    AppLocale.tasksCountSingular: "1 task",
    AppLocale.tasksCountZero: "No tasks",
    AppLocale.timeDaysAgo: '{days} days ago',
    AppLocale.timeFewMinutesAgo: 'a few minutes ago',
    AppLocale.timeFewSecondsAgo: 'a few seconds ago',
    AppLocale.timeHourAgo: '{hours} hour ago',
    AppLocale.timeHoursAgo: '{hours} hours ago',
    AppLocale.timeMinuteAgo: '{minutes} minute ago',
    AppLocale.timeMinutesAgo: '{minutes} minutes ago',
    AppLocale.timeYesterday: 'yesterday',

    // Settings Screen - Import/Export & Delete Account
    AppLocale.settingsExportDataTitle: "Export Data",
    AppLocale.settingsExportErrorNotLoggedIn: "User not logged in. Please log in to export.",
    AppLocale.settingsExportErrorFetchFailed: "Failed to fetch user data.",
    AppLocale.settingsExportErrorGeneral: "An error occurred while exporting data.",
    AppLocale.settingsImportDataTitle: "Import Data",
    AppLocale.settingsImportFileParseSuccess: "File parsed. Ready for import.",
    AppLocale.settingsImportErrorNoFile: "No file selected or error during file picking.",
    AppLocale.settingsImportErrorMobileNotFullyImplemented: "File selected. Full import for mobile not yet implemented.",
    AppLocale.settingsImportConfirmDialogTitle: "Confirm Import",
    AppLocale.settingsImportConfirmDialogMessage: "This will overwrite your current cloud data and cannot be undone. Proceed?",
    AppLocale.settingsImportErrorMismatchUser: "Imported data is for user {email}. Current user is different. Aborting.",
    AppLocale.settingsImportSuccess: "Data imported successfully.",
    AppLocale.settingsImportErrorSaveFailed: "Failed to save imported data to the cloud.",
    AppLocale.settingsImportCancelled: "Import cancelled.",
    AppLocale.settingsDeleteAccountDialogMessage: "This permanently deletes all your data AND your account. This action cannot be undone. Are you sure?",
    AppLocale.settingsDeleteErrorAuthFailed: "Failed to delete account. You may need to log out and log back in, then try again.",
    AppLocale.settingsDeleteErrorCloudDataFailed: "Account deleted, but failed to clear all cloud data. Please contact support.",

    // Settings Screen - Anonymous User Flows
    AppLocale.settingsAnonExportTitle: "Export Local Data",
    AppLocale.settingsAnonExportSuccess: "Local data exported.",
    AppLocale.settingsAnonImportTitle: "Import Local Data",
    AppLocale.settingsAnonImportConfirmMessage: "This will overwrite your current local data. This action cannot be undone. Proceed?",
    AppLocale.settingsAnonImportSuccess: "Local data imported successfully.",
    AppLocale.settingsAnonDeleteError: "Local data import faild, please try again later.",
    AppLocale.settingsAnonImportCancelled: "Local data import cancelled.",
    AppLocale.settingsAnonDeleteDialogTitle: "Delete Local Data",
    AppLocale.settingsAnonDeleteDialogMessage: "This will permanently delete all your locally stored data. This cannot be undone. Are you sure?",
    AppLocale.uncategorizedResults: "Results in Uncategorized",
  };

  static const Map<String, dynamic> HE = {
    AppLocale.title: 'המשימות שלי',
    AppLocale.lang: 'שפה',
    AppLocale.settings: "הגדרות",
    AppLocale.archive: "ארכיון",
    AppLocale.installApp: "התקנת אפליקציה",
    AppLocale.deleteAll: "מחק הכל",
    AppLocale.appIsInstalled: "האפליקציה הותקנה בהצלחה",
    AppLocale.deleteAllSubtitle: "מחיקת כל הטודו בחשבון, פעולה זו תמחק גם את הארכיון",
    AppLocale.logout: "התנתקות",
    AppLocale.login: "התחברות",
    AppLocale.enterTodoTextPlaceholder: "הוספת משימה חדשה...",
    AppLocale.add: "הוספה",
    AppLocale.account: "חשבון",
    AppLocale.version: "גרסה",
    AppLocale.name: "שם משתמש",
    AppLocale.archivedTodos: "ארכיון המשימות",
    AppLocale.guest: "אורח",
    AppLocale.unknown: "לא ידוע",
    AppLocale.archivedTodosSubtitle: "משימות שבוצעו יועברו לארכיון המשימות לאחר כ-24 שעות.",
    AppLocale.close: "סגירה",
    AppLocale.loginWEmail: "כניסה עם דוא''ל",
    AppLocale.loginAsGuest: "כניסה בתור אורח",
    AppLocale.todoLater: "המשימות שלי",
    AppLocale.email: "כתובת דוא''ל",
    AppLocale.password: "סיסמה",
    AppLocale.or: "או",
    AppLocale.ok: "אוקיי",
    AppLocale.signup: "הרשמה",
    AppLocale.cancel: "ביטול",
    AppLocale.todoExample1: "להוציא כביסה מהמייבש",
    AppLocale.todoExample2: "לתדלק את האוטו",
    AppLocale.todoExample3: "לקנות חלב",
    AppLocale.logoutText: "האם ברצונכם להתנתק מהמשתמש?",
    AppLocale.areUsure: "האם אתם בטוחים?",
    AppLocale.deleteAllSubtext: "מחיקת כל המשימות תגרום לרשימה שלכם להיות ריקה, ולארכיון להתרוקן. האם אתם בטוחים שזה מה שאתם רוצים לעשות?",
    AppLocale.doUwant2Delete: "האם למחוק?",
    AppLocale.thisCantBeUndone: "פעולה זו בלתי הפיכה",
    AppLocale.selectLanguage: "בחר שפה",
    AppLocale.randomTaskMenuButton: "משימה אקראית",
    AppLocale.randomTaskDialogTitle: "משימה שנבחרה בצורה אקראית",
    AppLocale.noTasksAvailableDialogTitle: "אין משימות",
    AppLocale.noTasksAvailableDialogMessage: "אין כרגע משימות שעלייך לבצע",
    AppLocale.addCategoryTooltip: 'הוסף קטגוריה חדשה',
    AppLocale.uncategorizedCategory: 'הכל',
    // AppLocale.itemUncategorizedSnackbar: 'הפריט הועבר להכל', // Already included below
    AppLocale.itemMovedSnackbar: 'הפריט הועבר לקטגוריה {categoryName}',
    AppLocale.all: 'הכל',
    AppLocale.addCategoryDialogTitle: 'הוסף קטגוריה חדשה',
    AppLocale.addNewCategoryMenuItem: 'הוסף קטגוריה חדשה', // Ensured
    AppLocale.cancelButtonText: 'ביטול',
    AppLocale.categoryDeletedSnackbar: "קטגוריה '{categoryName}' נמחקה.",
    AppLocale.categoryNameEmptyError: 'שם קטגוריה לא יכול להיות ריק',
    AppLocale.categoryNameExistsError: 'שם הקטגוריה כבר קיים',
    AppLocale.categoryNameHintText: 'שם הקטגוריה',
    AppLocale.categoryRenamedSnackbar: "קטגוריה '{oldName}' שונתה ל '{newName}'",
    AppLocale.closeSearchTooltip: "סגור חיפוש",
    AppLocale.deleteCategoryConfirmationMessage: "האם אתה בטוח שברצונך למחוק את הקטגוריה '{categoryName}'? כל הפריטים בקטגוריה זו יועברו ל'הכל'.",
    AppLocale.deleteCategoryConfirmationTitle: "למחוק קטגוריה?",
    AppLocale.deleteCategoryMenuButton: "מחק קטגוריה נוכחית",
    AppLocale.deleteMenuItem: 'מחק',
    AppLocale.editMenuItem: 'עריכה',
    AppLocale.editTaskHintText: 'ערוך משימה...',
    AppLocale.emptyTodoDialogMessage: "אנא כתוב משימה",
    AppLocale.emptyTodoDialogTitle: "משימה ריקה",
    AppLocale.enterSearchQueryPrompt: "הקלד כדי להתחיל בחיפוש.",
    // AppLocale.itemMovedSnackbar: 'הפריט הועבר לקטגוריה {categoryName}', // Already included above
    AppLocale.itemUncategorizedSnackbar: 'הפריט הועבר להכל',
    AppLocale.shareCategory: "שתף קטגוריה",
    AppLocale.profilePicture: "תמונת פרופיל",
    AppLocale.profilePictureUpdated: "התמונה עודכנה",
    AppLocale.shareFailed: "לא ניתן לשתף את הרשימה",
    AppLocale.copiedToClipboard: "הועתק ללוח",
    AppLocale.copyLink: "העתק קישור",
    AppLocale.sharedWith: "שותף עם",
    AppLocale.createdOn: "נוצר ב {date}",
    AppLocale.motivationalSentence1: "דברים גדולים לעולם לא מגיעים מאזורי נוחות. בוא נתמודד עם משימה!",
    AppLocale.motivationalSentence2: "הסוד להתקדם הוא להתחיל. מה הדבר הראשון?",
    AppLocale.motivationalSentence3: "רשימה ריקה היא בד ציור ריק. צייר את יצירת המופת שלך בפרודוקטיביות!",
    AppLocale.motivationalSentence4: "אל תסתכל על השעון; עשה מה שהוא עושה. המשך להתקדם! הוסף משימה.",
    AppLocale.motivationalSentence5: "המסע של אלף מייל מתחיל בצעד אחד... או במשימה אחת!",
    AppLocale.moreResults: "משימות נוספות", // Re-added with user-specified translation
    AppLocale.moveToCategoryMenuItem: 'העבר לקטגוריה',
    AppLocale.noResultsFound: "לא נמצאו תוצאות עבור '{query}'",
    // AppLocale.noTasksAvailableDialogMessage: "אין כרגע משימות שעלייך לבצע", // Already included above
    // AppLocale.noTasksAvailableDialogTitle: "אין משימות", // Already included above
    AppLocale.okButtonText: 'אישור',
    // AppLocale.randomTaskDialogTitle: "משימה שנבחרה בצורה אקראית", // Already included above
    // AppLocale.randomTaskMenuButton: "משימה אקראית", // Already included above
    AppLocale.renameButtonText: 'שנה שם',
    AppLocale.renameCategoryDialogTitle: 'שנה שם קטגוריה',
    AppLocale.renameCategoryMenuButton: "שנה שם קטגוריה נוכחית",
    // AppLocale.resultsFromAll: "תוצאות מהכל", // Removed
    AppLocale.resultsInCategory: "תוצאות בקטגוריה {categoryName}",
    AppLocale.resultsInAllCategory: "תוצאות נוספות",
    AppLocale.searchTodosHint: "חפש משימות...",
    AppLocale.searchTodosTooltip: "חפש משימות",
    AppLocale.selectCategoryDialogTitle: 'בחר קטגוריה',
    AppLocale.tasksCount: "{count} משימות",
    AppLocale.tasksFoundCount: "{count} משימות נמצאו", // Added
    AppLocale.tasksCountSingular: "משימה אחת",
    AppLocale.tasksCountZero: "אין משימות",
    AppLocale.timeFewSecondsAgo: 'לפני מספר שניות', // Placeholder
    AppLocale.timeFewMinutesAgo: 'לפני מספר דקות', // Placeholder
    AppLocale.timeMinuteAgo: 'לפני דקה', // Placeholder for singular minute, assuming {minutes} will be 1
    AppLocale.timeMinutesAgo: 'לפני {minutes} דקות', // Placeholder
    AppLocale.timeHourAgo: 'לפני שעה',   // Placeholder for singular hour, assuming {hours} will be 1
    AppLocale.timeHoursAgo: 'לפני {hours} שעות',   // Placeholder
    AppLocale.timeYesterday: 'אתמול',      // Placeholder
    AppLocale.timeDaysAgo: 'לפני {days} ימים',     // Placeholder

    // Settings Screen - Import/Export & Delete Account
    AppLocale.settingsExportDataTitle: "ייצוא נתונים",
    AppLocale.settingsExportErrorNotLoggedIn: "המשתמש אינו מחובר. אנא התחבר כדי לייצא.",
    AppLocale.settingsExportErrorFetchFailed: "נכשל בטעינת נתוני משתמש.",
    AppLocale.settingsExportErrorGeneral: "אירעה שגיאה במהלך ייצוא הנתונים.",
    AppLocale.settingsImportDataTitle: "ייבוא נתונים",
    AppLocale.settingsImportFileParseSuccess: "הקובץ עבר ניתוח. מוכן לייבוא.",
    AppLocale.settingsImportErrorNoFile: "לא נבחר קובץ או שאירעה שגיאה בבחירת הקובץ.",
    AppLocale.settingsImportErrorMobileNotFullyImplemented: "הקובץ נבחר. ייבוא מלא למובייל עדיין לא מיושם.",
    AppLocale.settingsImportConfirmDialogTitle: "אישור ייבוא",
    AppLocale.settingsImportConfirmDialogMessage: "פעולה זו תחליף את נתוני הענן הנוכחיים שלך ולא ניתן לבטלה. להמשיך?",
    AppLocale.settingsImportErrorMismatchUser: "הנתונים המיובאים הם עבור משתמש {email}. המשתמש הנוכחי שונה. הייבוא מבוטל.",
    AppLocale.settingsImportSuccess: "הנתונים יובאו בהצלחה.",
    AppLocale.settingsImportErrorSaveFailed: "נכשל בשמירת הנתונים המיובאים לענן.",
    AppLocale.settingsImportCancelled: "הייבוא בוטל.",
    AppLocale.settingsDeleteAccountDialogMessage: "פעולה זו מוחקת לצמיתות את כל הנתונים שלך ואת חשבונך. לא ניתן לבטל פעולה זו. האם אתה בטוח?",
    AppLocale.settingsDeleteErrorAuthFailed: "נכשל במחיקת החשבון. ייתכן שתצטרך להתנתק ולהתחבר מחדש, ואז לנסות שוב.",
    AppLocale.settingsDeleteErrorCloudDataFailed: "החשבון נמחק, אך נכשל בניקוי כל נתוני הענן. אנא פנה לתמיכה.",

    // Settings Screen - Anonymous User Flows
    AppLocale.settingsAnonExportTitle: "ייצוא נתונים מקומיים",
    AppLocale.settingsAnonExportSuccess: "הנתונים המקומיים יוצאו.",
    AppLocale.settingsAnonImportTitle: "ייבוא נתונים מקומיים",
    AppLocale.settingsAnonImportConfirmMessage: "פעולה זו תחליף את הנתונים המקומיים הנוכחיים שלך. לא ניתן לבטל פעולה זו. להמשיך?",
    AppLocale.settingsAnonImportSuccess: "הנתונים המקומיים יובאו בהצלחה.",
    AppLocale.settingsAnonDeleteError: "ייבוא הנתונים המקומיים נכשל, אנא נסה שנית מאוחר יותר.",
    AppLocale.settingsAnonImportCancelled: "ייבוא הנתונים המקומיים בוטל.",
    AppLocale.settingsAnonDeleteDialogTitle: "מחיקת נתונים מקומיים",
    AppLocale.settingsAnonDeleteDialogMessage: "פעולה זו תמחק לצמיתות את כל הנתונים המאוחסנים מקומית. לא ניתן לבטל פעולה זו. האם אתה בטוח?",
    AppLocale.uncategorizedResults: "תוצאות ללא קטגוריה",
  };
}
