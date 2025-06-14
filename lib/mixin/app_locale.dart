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
  static const String name = "name";
  static const String archivedTodos = "archivedTodos";
  static const String guest = "guest";
  static const String unknown = "unknown";
  static const String archivedTodosSubtitle = "archivedTodosSubtitle";
  static const String close = "close";
  static const String loginWEmail = "loginWEmail";
  static const String loginAsGuest = "loginAsGuest";
  static const String todoLater = "todoLater";
  static const String email = "email";
  static const String password = "password";
  static const String or = "or";
  static const String ok = "ok"; // Consider if this should be okButtonText primarily
  static const String signup = "signup";
  static const String cancel = "cancel"; // Consider if this should be cancelButtonText primarily
  static const String todoExample1 = "todoExample1";
  static const String todoExample2 = "todoExample2";
  static const String todoExample3 = "todoExample3";
  static const String logoutText = "logoutText";
  static const String areUsure = "areUsure";
  static const String deleteAllSubtext = "deleteAllSubtext";
  static const String doUwant2Delete = "doUwant2Delete";
  static const String thisCantBeUndone = "thisCantBeUndone";
  static const String selectLanguage = "selectLanguage";

  static const String randomTaskMenuButton = 'randomTaskMenuButton';
  static const String randomTaskDialogTitle = 'randomTaskDialogTitle';
  static const String noTasksAvailableDialogTitle = 'noTasksAvailableDialogTitle';
  static const String noTasksAvailableDialogMessage = 'noTasksAvailableDialogMessage';

  static const String addCategoryTooltip = 'addCategoryTooltip';
  static const String uncategorizedCategory = 'uncategorizedCategory';
  static const String itemUncategorizedSnackbar = 'itemUncategorizedSnackbar';
  static const String itemMovedSnackbar = 'itemMovedSnackbar';
  static const String all = 'all';
  static const String addCategoryDialogTitle = 'addCategoryDialogTitle';
  static const String categoryNameHintText = 'categoryNameHintText';
  static const String categoryNameEmptyError = 'categoryNameEmptyError';
  static const String categoryNameExistsError = 'categoryNameExistsError';
  static const String cancelButtonText = 'cancelButtonText';
  static const String okButtonText = 'okButtonText';
  static const String editMenuItem = 'editMenuItem';
  static const String moveToCategoryMenuItem = 'moveToCategoryMenuItem';
  static const String deleteMenuItem = 'deleteMenuItem';
  static const String selectCategoryDialogTitle = 'selectCategoryDialogTitle';
  static const String addNewCategoryMenuItem = 'addNewCategoryMenuItem';
  static const String renameCategoryDialogTitle = 'renameCategoryDialogTitle';
  static const String renameButtonText = 'renameButtonText';
  static const String categoryRenamedSnackbar = 'categoryRenamedSnackbar';
  static const String renameCategoryMenuButton = 'renameCategoryMenuButton';
  static const String deleteCategoryMenuButton = 'deleteCategoryMenuButton';
  static const String deleteCategoryConfirmationTitle = 'deleteCategoryConfirmationTitle';
  static const String deleteCategoryConfirmationMessage = 'deleteCategoryConfirmationMessage';
  static const String categoryDeletedSnackbar = 'categoryDeletedSnackbar';

  // New fields for motivational sentences
  static const String motivationalSentence1 = 'motivationalSentence1';
  static const String motivationalSentence2 = 'motivationalSentence2';
  static const String motivationalSentence3 = 'motivationalSentence3';
  static const String motivationalSentence4 = 'motivationalSentence4';
  static const String motivationalSentence5 = 'motivationalSentence5';

  // New fields for task counts
  static const String tasksCount = 'tasksCount';
  static const String tasksCountSingular = 'tasksCountSingular';
  static const String tasksCountZero = 'tasksCountZero';

  // New fields for empty todo dialog
  static const String emptyTodoDialogTitle = 'emptyTodoDialogTitle';
  static const String emptyTodoDialogMessage = 'emptyTodoDialogMessage';

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
    AppLocale.ok: "OK", // Retained for broader compatibility if used elsewhere, but specific okButtonText is better for dialogs
    AppLocale.signup: "Signup",
    AppLocale.cancel: "Cancel", // Retained for broader compatibility, but specific cancelButtonText is better for dialogs
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
    AppLocale.uncategorizedCategory: 'All', // 'All' is often a better default than 'Uncategorized' for the main view
    AppLocale.itemUncategorizedSnackbar: 'Item moved to All',
    AppLocale.itemMovedSnackbar: 'Item moved to {categoryName}',
    AppLocale.all: 'All',
    AppLocale.addCategoryDialogTitle: 'Add New Category',
    AppLocale.categoryNameHintText: 'Category name',
    AppLocale.categoryNameEmptyError: 'Category name cannot be empty',
    AppLocale.categoryNameExistsError: 'Category name already exists',
    AppLocale.cancelButtonText: 'Cancel', // Specific key for dialog cancel
    AppLocale.okButtonText: 'OK',       // Specific key for dialog OK
    AppLocale.editMenuItem: 'Edit',
    AppLocale.moveToCategoryMenuItem: 'Move to category',
    AppLocale.deleteMenuItem: 'Delete',
    AppLocale.selectCategoryDialogTitle: 'Select Category',
    AppLocale.addNewCategoryMenuItem: 'Add New Category',
    AppLocale.renameCategoryDialogTitle: 'Rename Category',
    AppLocale.renameButtonText: 'Rename',
    AppLocale.categoryRenamedSnackbar: "Category '{oldName}' renamed to '{newName}'",
    AppLocale.renameCategoryMenuButton: "Rename Current Category",
    AppLocale.deleteCategoryMenuButton: "Delete Current Category",
    AppLocale.deleteCategoryConfirmationTitle: "Delete Category?",
    AppLocale.deleteCategoryConfirmationMessage: "Are you sure you want to delete the category '{categoryName}'? All items in this category will be moved to 'All'.",
    AppLocale.categoryDeletedSnackbar: "Category '{categoryName}' deleted.",
    AppLocale.motivationalSentence1: "Let's get something done!",
    AppLocale.motivationalSentence2: "What's on your mind today?",
    AppLocale.motivationalSentence3: "Time to be productive!",
    AppLocale.motivationalSentence4: "Add a task and feel the accomplishment.",
    AppLocale.motivationalSentence5: "An empty list is a world of possibilities!",
    AppLocale.tasksCount: "{count} tasks",
    AppLocale.tasksCountSingular: "1 task",
    AppLocale.tasksCountZero: "No tasks",
    AppLocale.emptyTodoDialogTitle: "Empty Todo",
    AppLocale.emptyTodoDialogMessage: "Please write a Todo",
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
    AppLocale.ok: "אוקיי", // Retained for broader compatibility
    AppLocale.signup: "הרשמה",
    AppLocale.cancel: "ביטול", // Retained for broader compatibility
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
    AppLocale.itemUncategorizedSnackbar: 'הפריט הועבר להכל',
    AppLocale.itemMovedSnackbar: 'הפריט הועבר לקטגוריה {categoryName}',
    AppLocale.all: 'הכל',
    AppLocale.addCategoryDialogTitle: 'הוסף קטגוריה חדשה',
    AppLocale.categoryNameHintText: 'שם הקטגוריה',
    AppLocale.categoryNameEmptyError: 'שם קטגוריה לא יכול להיות ריק',
    AppLocale.categoryNameExistsError: 'שם הקטגוריה כבר קיים',
    AppLocale.cancelButtonText: 'ביטול', // Specific key for dialog cancel
    AppLocale.okButtonText: 'אישור',    // Specific key for dialog OK
    AppLocale.editMenuItem: 'עריכה',
    AppLocale.moveToCategoryMenuItem: 'העבר לקטגוריה',
    AppLocale.deleteMenuItem: 'מחק',
    AppLocale.selectCategoryDialogTitle: 'בחר קטגוריה',
    AppLocale.addNewCategoryMenuItem: 'הוסף קטגוריה חדשה',
    AppLocale.renameCategoryDialogTitle: 'שנה שם קטגוריה',
    AppLocale.renameButtonText: 'שנה שם',
    AppLocale.categoryRenamedSnackbar: "קטגוריה '{oldName}' שונתה ל '{newName}'",
    AppLocale.renameCategoryMenuButton: "שנה שם קטגוריה נוכחית",
    AppLocale.deleteCategoryMenuButton: "מחק קטגוריה נוכחית",
    AppLocale.deleteCategoryConfirmationTitle: "למחוק קטגוריה?",
    AppLocale.deleteCategoryConfirmationMessage: "האם אתה בטוח שברצונך למחוק את הקטגוריה '{categoryName}'? כל הפריטים בקטגוריה זו יועברו ל'הכל'.",
    AppLocale.categoryDeletedSnackbar: "קטגוריה '{categoryName}' נמחקה.",
    AppLocale.motivationalSentence1: "בואו נעשה משהו!",
    AppLocale.motivationalSentence2: "מה בראש שלך היום?",
    AppLocale.motivationalSentence3: "זמן להיות פרודוקטיבי!",
    AppLocale.motivationalSentence4: "הוסף משימה והרגש את ההישג.",
    AppLocale.motivationalSentence5: "רשימה ריקה היא עולם של אפשרויות!",
    AppLocale.tasksCount: "{count} משימות",
    AppLocale.tasksCountSingular: "משימה אחת",
    AppLocale.tasksCountZero: "אין משימות",
    AppLocale.emptyTodoDialogTitle: "משימה ריקה",
    AppLocale.emptyTodoDialogMessage: "אנא כתוב משימה",
  };
}
