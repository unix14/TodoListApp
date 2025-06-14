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
  static const String ok = "ok";
  static const String signup = "signup";
  static const String cancel = "cancel";
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
  static const String addNewCategoryMenuItem = 'addNewCategoryMenuItem'; // This was actually added in the previous step, ensure it's here or matches.
  static const String renameCategoryDialogTitle = 'renameCategoryDialogTitle';
  static const String renameButtonText = 'renameButtonText';
  static const String categoryRenamedSnackbar = 'categoryRenamedSnackbar';
  static const String renameCategoryMenuButton = 'renameCategoryMenuButton';
  static const String deleteCategoryMenuButton = 'deleteCategoryMenuButton';
  static const String deleteCategoryConfirmationTitle = 'deleteCategoryConfirmationTitle';
  static const String deleteCategoryConfirmationMessage = 'deleteCategoryConfirmationMessage';
  static const String categoryDeletedSnackbar = 'categoryDeletedSnackbar';

  static const Map<String, dynamic> EN = {
    title: 'Todo List',
    lang: 'Language',
    settings: "Settings",
    archive: "Archive",
    installApp: "Install App",
    deleteAll: "Delete All",
    appIsInstalled: "App is installed",
    deleteAllSubtitle: "Delete all TODOs in the account, this action will also clear the archive",
    logout: "Log out",
    login: "Login",
    enterTodoTextPlaceholder: "Enter a Todo here..",
    add: "Add",
    account: "Account",
    version: "Version",
    name: "Name",
    archivedTodos: "Archived Todos",
    guest: "Guest",
    unknown: "unknown",
    archivedTodosSubtitle: "Todos are added to the archive after 24 hours since they're checked as done.",
    close: "Close",
    loginWEmail: "Login with Email",
    loginAsGuest: "Try as Guest",
    todoLater: "Todo Later",
    email: "Email",
    password: "Password",
    or: "or",
    ok: "OK",
    signup: "Signup",
    cancel: "Cancel",
    todoExample1: "Get clean clothes",
    todoExample2: "Buy gas",
    todoExample3: "Buy milk",
    logoutText: "Are you sure you want to logout?",
    areUsure: "Are you sure?",
    deleteAllSubtext: "Deleting all Todos will result in an empty list and an empty archive list. Do you really want to delete everything?",
    doUwant2Delete: "Do you want to delete?",
    thisCantBeUndone: "This can't be undone",
    selectLanguage: "Select Language",
    AppLocale.randomTaskMenuButton: "Random Task",
    AppLocale.randomTaskDialogTitle: "Randomly Selected Task",
    AppLocale.noTasksAvailableDialogTitle: "No Tasks",
    AppLocale.noTasksAvailableDialogMessage: "There are no tasks available to pick from.",
    AppLocale.addCategoryTooltip: 'Add new category',
    AppLocale.uncategorizedCategory: 'All',
    AppLocale.itemUncategorizedSnackbar: 'Item moved to All',
    AppLocale.itemMovedSnackbar: 'Item moved to {categoryName}',
    AppLocale.all: 'All',
    AppLocale.addNewCategoryMenuItem: 'Add New Category', // Ensure this line is present and correct from previous step
    AppLocale.renameCategoryDialogTitle: 'Rename Category',
    AppLocale.renameButtonText: 'Rename',
    AppLocale.categoryRenamedSnackbar: "Category '{oldName}' renamed to '{newName}'",
    AppLocale.renameCategoryMenuButton: "Rename Current Category",
    AppLocale.deleteCategoryMenuButton: "Delete Current Category",
    AppLocale.deleteCategoryConfirmationTitle: "Delete Category?",
    AppLocale.deleteCategoryConfirmationMessage: "Are you sure you want to delete the category '{categoryName}'? All items in this category will be moved to 'All'.",
    AppLocale.categoryDeletedSnackbar: "Category '{categoryName}' deleted.",
    AppLocale.addCategoryDialogTitle: 'Add New Category',
    AppLocale.categoryNameHintText: 'Category name',
    AppLocale.categoryNameEmptyError: 'Category name cannot be empty',
    AppLocale.categoryNameExistsError: 'Category name already exists',
    AppLocale.cancelButtonText: 'Cancel',
    AppLocale.okButtonText: 'OK',
    AppLocale.editMenuItem: 'Edit',
    AppLocale.moveToCategoryMenuItem: 'Move to category',
    AppLocale.deleteMenuItem: 'Delete',
    AppLocale.selectCategoryDialogTitle: 'Select Category',
  };
  static const Map<String, dynamic> HE = {
    title: 'המשימות שלי',
    lang: 'שפה',
    settings: "הגדרות",
    archive: "ארכיון",
    installApp: "התקנת אפליקציה",
    deleteAll: "מחק הכל",
    appIsInstalled: "האפליקציה הותקנה בהצלחה",
    deleteAllSubtitle: "מחיקת כל הטודו בחשבון, פעולה זו תמחק גם את הארכיון",
    logout: "התנתקות",
    login: "התחברות",
    enterTodoTextPlaceholder: "הוספת משימה חדשה...",
    add: "הוספה",
    account: "חשבון",
    version: "גרסה",
    name: "שם משתמש",
    archivedTodos: "ארכיון המשימות",
    guest: "אורח",
    unknown: "לא ידוע",
    archivedTodosSubtitle: "משימות שבוצעו יועברו לארכיון המשימות לאחר כ-24 שעות.",
    close: "סגירה",
    loginWEmail: "כניסה עם דוא''ל",
    loginAsGuest: "כניסה בתור אורח",
    todoLater: "המשימות שלי",
    email: "כתובת דוא''ל",
    password: "סיסמה",
    or: "או",
    ok: "אוקיי",
    signup: "הרשמה",
    cancel: "ביטול",
    todoExample1: "להוציא כביסה מהמייבש",
    todoExample2: "לתדלק את האוטו",
    todoExample3: "לקנות חלב",
    logoutText: "האם ברצונכם להתנתק מהמשתמש?",
    areUsure: "האם אתם בטוחים?",
    deleteAllSubtext: "מחיקת כל המשימות תגרום לרשימה שלכם להיות ריקה, ולארכיון להתרוקן. האם אתם בטוחים שזה מה שאתם רוצים לעשות?",
    doUwant2Delete: "האם למחוק?",
    thisCantBeUndone: "פעולה זו בלתי הפיכה",
    selectLanguage: "בחר שפה",
    AppLocale.randomTaskMenuButton: "משימה אקראית",
    AppLocale.randomTaskDialogTitle: "משימה שנבחרה בצורה אקראית",
    AppLocale.noTasksAvailableDialogTitle: "אין משימות",
    AppLocale.noTasksAvailableDialogMessage: "אין כרגע משימות שעלייך לבצע",
    AppLocale.addCategoryTooltip: 'הוסף קטגוריה חדשה',
    AppLocale.uncategorizedCategory: 'הכל',
    AppLocale.itemUncategorizedSnackbar: 'הפריט הועבר להכל',
    AppLocale.itemMovedSnackbar: 'הפריט הועבר לקטגוריה {categoryName}',
    AppLocale.all: 'הכל',
    AppLocale.addNewCategoryMenuItem: 'הוסף קטגוריה חדשה', // Ensure this line is present and correct from previous step
    AppLocale.renameCategoryDialogTitle: 'שנה שם קטגוריה',
    AppLocale.renameButtonText: 'שנה שם',
    AppLocale.categoryRenamedSnackbar: "קטגוריה '{oldName}' שונתה ל '{newName}'",
    AppLocale.renameCategoryMenuButton: "שנה שם קטגוריה נוכחית",
    AppLocale.deleteCategoryMenuButton: "מחק קטגוריה נוכחית",
    AppLocale.deleteCategoryConfirmationTitle: "למחוק קטגוריה?",
    AppLocale.deleteCategoryConfirmationMessage: "האם אתה בטוח שברצונך למחוק את הקטגוריה '{categoryName}'? כל הפריטים בקטגוריה זו יועברו ל'הכל'.",
    AppLocale.categoryDeletedSnackbar: "קטגוריה '{categoryName}' נמחקה.",
    AppLocale.addCategoryDialogTitle: 'הוסף קטגוריה חדשה',
    AppLocale.categoryNameHintText: 'שם הקטגוריה',
    AppLocale.categoryNameEmptyError: 'שם קטגוריה לא יכול להיות ריק',
    AppLocale.categoryNameExistsError: 'שם הקטגוריה כבר קיים',
    AppLocale.cancelButtonText: 'ביטול',
    AppLocale.okButtonText: 'אישור',
    AppLocale.editMenuItem: 'עריכה',
    AppLocale.moveToCategoryMenuItem: 'העבר לקטגוריה',
    AppLocale.deleteMenuItem: 'מחק',
    AppLocale.selectCategoryDialogTitle: 'בחר קטגוריה',
  };
}
