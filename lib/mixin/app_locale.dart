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

  static const Map<String, dynamic> EN = {
    'title': 'Todo List',
    'lang': 'Language',
    'settings': "Settings",
    'archive': "Archive",
    'installApp': "Install App",
    'deleteAll': "Delete All",
    'appIsInstalled': "App is installed",
    'deleteAllSubtitle': "Delete all TODOs in the account, this action will also clear the archive",
    'logout': "Log out",
    'login': "Login",
    'enterTodoTextPlaceholder': "Enter a Todo here..",
    'add': "Add",
    'account': "Account",
    'version': "Version",
    'name': "Name",
    'archivedTodos': "Archived Todos",
    'guest': "Guest",
    'unknown': "unknown",
    'archivedTodosSubtitle': "Todos are added to the archive after 24 hours since they're checked as done.",
    'close': "Close",
    'loginWEmail': "Login with Email",
    'loginAsGuest': "Try as Guest",
    'todoLater': "Todo Later",
    'email': "Email",
    'password': "Password",
    'or': "or",
    'ok': "OK",
    'signup': "Signup",
    'cancel': "Cancel",
    'todoExample1': "Get clean clothes",
    'todoExample2': "Buy gas",
    'todoExample3': "Buy milk",
    'logoutText': "Are you sure you want to logout?",
    'areUsure': "Are you sure?",
    'deleteAllSubtext': "Deleting all Todos will result in an empty list and an empty archive list. Do you really want to delete everything?",
    'doUwant2Delete': "Do you want to delete?",
    'thisCantBeUndone': "This can't be undone",
    'selectLanguage': "Select Language",
    'randomTaskMenuButton': "Random Task",
    'randomTaskDialogTitle': "Randomly Selected Task",
    'noTasksAvailableDialogTitle': "No Tasks",
    'noTasksAvailableDialogMessage': "There are no tasks available to pick from.",
    'loginFailedTitle': 'Login failed',
    'signupFailedTitle': 'Signup failed',
    'authNoUserFound': 'No user found for that email.',
    'authWrongPassword': 'Wrong password provided for that user.',
    'authWeakPassword': 'The password provided is too weak.',
    'authEmailAlreadyInUse': 'The account already exists for that email.',
    'authUnknownError': 'An unexpected authentication error occurred.',
    'copiedToClipboard': 'Copied to clipboard:',
    'editTodoHint': 'Edit your ToDo here!',
    'emptyTodoTitle': 'Empty Todo',
    'emptyTodoMessage': 'Please write a Todo',
  };
  static const Map<String, dynamic> HE = {
    'title': 'המשימות שלי',
    'lang': 'שפה',
    'settings': "הגדרות",
    'archive': "ארכיון",
    'installApp': "התקנת אפליקציה",
    'deleteAll': "מחק הכל",
    'appIsInstalled': "האפליקציה הותקנה בהצלחה",
    'deleteAllSubtitle': "מחיקת כל הטודו בחשבון, פעולה זו תמחק גם את הארכיון",
    'logout': "התנתקות",
    'login': "התחברות",
    'enterTodoTextPlaceholder': "הוספת משימה חדשה...",
    'add': "הוספה",
    'account': "חשבון",
    'version': "גרסה",
    'name': "שם משתמש",
    'archivedTodos': "ארכיון המשימות",
    'guest': "אורח",
    'unknown': "לא ידוע",
    'archivedTodosSubtitle': "משימות שבוצעו יועברו לארכיון המשימות לאחר כ-24 שעות.",
    'close': "סגירה",
    'loginWEmail': "כניסה עם דוא''ל",
    'loginAsGuest': "כניסה בתור אורח",
    'todoLater': "המשימות שלי",
    'email': "כתובת דוא''ל",
    'password': "סיסמה",
    'or': "או",
    'ok': "אוקיי",
    'signup': "הרשמה",
    'cancel': "ביטול",
    'todoExample1': "להוציא כביסה מהמייבש",
    'todoExample2': "לתדלק את האוטו",
    'todoExample3': "לקנות חלב",
    'logoutText': "האם ברצונכם להתנתק מהמשתמש?",
    'areUsure': "האם אתם בטוחים?",
    'deleteAllSubtext': "מחיקת כל המשימות תגרום לרשימה שלכם להיות ריקה, ולארכיון להתרוקן. האם אתם בטוחים שזה מה שאתם רוצים לעשות?",
    'doUwant2Delete': "האם למחוק?",
    'thisCantBeUndone': "פעולה זו בלתי הפיכה",
    'selectLanguage': "בחר שפה",
    'randomTaskMenuButton': "משימה אקראית",
    'randomTaskDialogTitle': "משימה שנבחרה בצורה אקראית",
    'noTasksAvailableDialogTitle': "אין משימות",
    'noTasksAvailableDialogMessage': "אין כרגע משימות שעלייך לבצע",
    'loginFailedTitle': 'התחברות נכשלה',
    'signupFailedTitle': 'הרשמה נכשלה',
    'authNoUserFound': 'לא נמצא משתמש עבור אימייל זה.',
    'authWrongPassword': 'סיסמה שגויה עבור משתמש זה.',
    'authWeakPassword': 'הסיסמה שסופקה חלשה מדי.',
    'authEmailAlreadyInUse': 'החשבון כבר קיים עבור אימייל זה.',
    'authUnknownError': 'אירעה שגיאת אימות בלתי צפויה.',
    'copiedToClipboard': 'הועתק ללוח:',
    'editTodoHint': 'ערוך את המשימה שלך כאן!',
    'emptyTodoTitle': 'משימה ריקה',
    'emptyTodoMessage': 'אנא כתוב משימה',
  };
}
