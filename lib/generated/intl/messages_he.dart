// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a he locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'he';

  static String m0(text) => "הועתק ללוח: ${text}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "appIsInstalled": MessageLookupByLibrary.simpleMessage("האפליקציה מותקנת"),
    "authEmailAlreadyInUse": MessageLookupByLibrary.simpleMessage(
      "החשבון כבר קיים עבור אימייל זה.",
    ),
    "authNoUserFound": MessageLookupByLibrary.simpleMessage(
      "לא נמצא משתמש עבור אימייל זה.",
    ),
    "authWeakPassword": MessageLookupByLibrary.simpleMessage(
      "הסיסמה שסופקה חלשה מדי.",
    ),
    "authWrongPassword": MessageLookupByLibrary.simpleMessage(
      "סיסמה שגויה עבור משתמש זה.",
    ),
    "cancelButton": MessageLookupByLibrary.simpleMessage("ביטול"),
    "closeButton": MessageLookupByLibrary.simpleMessage("סגור"),
    "copiedToClipboard": m0,
    "deleteTodoMessage": MessageLookupByLibrary.simpleMessage(
      "לא ניתן לשחזר פעולה זו",
    ),
    "deleteTodoTitle": MessageLookupByLibrary.simpleMessage("האם למחוק?"),
    "editTodoHint": MessageLookupByLibrary.simpleMessage(
      "ערוך את המשימה שלך כאן!",
    ),
    "emptyTodoMessage": MessageLookupByLibrary.simpleMessage("אנא כתוב משימה"),
    "emptyTodoTitle": MessageLookupByLibrary.simpleMessage("משימה ריקה"),
    "loggedInWelcomeMessage": MessageLookupByLibrary.simpleMessage(
      "התחברת בהצלחה, ברוך הבא",
    ),
    "loginFailedTitle": MessageLookupByLibrary.simpleMessage("התחברות נכשלה"),
    "okButton": MessageLookupByLibrary.simpleMessage("אישור"),
    "signupFailedTitle": MessageLookupByLibrary.simpleMessage("הרשמה נכשלה"),
  };
}
