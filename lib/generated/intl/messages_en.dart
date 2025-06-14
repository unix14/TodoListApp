// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
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
  String get localeName => 'en';

  static String m0(text) => "Copied to clipboard: ${text}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "appIsInstalled": MessageLookupByLibrary.simpleMessage("App is installed"),
    "authEmailAlreadyInUse": MessageLookupByLibrary.simpleMessage(
      "The account already exists for that email.",
    ),
    "authNoUserFound": MessageLookupByLibrary.simpleMessage(
      "No user found for that email.",
    ),
    "authWeakPassword": MessageLookupByLibrary.simpleMessage(
      "The password provided is too weak.",
    ),
    "authWrongPassword": MessageLookupByLibrary.simpleMessage(
      "Wrong password provided for that user.",
    ),
    "cancelButton": MessageLookupByLibrary.simpleMessage("Cancel"),
    "closeButton": MessageLookupByLibrary.simpleMessage("Close"),
    "copiedToClipboard": m0,
    "deleteTodoMessage": MessageLookupByLibrary.simpleMessage(
      "This can\'t be undone",
    ),
    "deleteTodoTitle": MessageLookupByLibrary.simpleMessage(
      "Do you want to delete?",
    ),
    "editTodoHint": MessageLookupByLibrary.simpleMessage(
      "Edit your ToDo here!",
    ),
    "emptyTodoMessage": MessageLookupByLibrary.simpleMessage(
      "Please write a Todo",
    ),
    "emptyTodoTitle": MessageLookupByLibrary.simpleMessage("Empty Todo"),
    "loggedInWelcomeMessage": MessageLookupByLibrary.simpleMessage(
      "You are now logged in, Welcome",
    ),
    "loginFailedTitle": MessageLookupByLibrary.simpleMessage("Login failed"),
    "noTasksAvailableDialogMessage": MessageLookupByLibrary.simpleMessage(
      "There are no tasks available to pick from.",
    ),
    "noTasksAvailableDialogTitle": MessageLookupByLibrary.simpleMessage(
      "No Tasks",
    ),
    "okButton": MessageLookupByLibrary.simpleMessage("OK"),
    "randomTaskDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Randomly Selected Task",
    ),
    "randomTaskMenuButton": MessageLookupByLibrary.simpleMessage("Random Task"),
    "signupFailedTitle": MessageLookupByLibrary.simpleMessage("Signup failed"),
  };
}
