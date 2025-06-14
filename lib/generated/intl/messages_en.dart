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

  static String m0(categoryName) => "Item moved to ${categoryName}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "addCategoryDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Add New Category",
    ),
    "addCategoryTooltip": MessageLookupByLibrary.simpleMessage(
      "Add new category",
    ),
    "all": MessageLookupByLibrary.simpleMessage("All"),
    "cancelButtonText": MessageLookupByLibrary.simpleMessage("Cancel"),
    "categoryNameEmptyError": MessageLookupByLibrary.simpleMessage(
      "Category name cannot be empty.",
    ),
    "categoryNameExistsError": MessageLookupByLibrary.simpleMessage(
      "This category name already exists.",
    ),
    "categoryNameHintText": MessageLookupByLibrary.simpleMessage(
      "Category Name",
    ),
    "deleteMenuItem": MessageLookupByLibrary.simpleMessage("Delete"),
    "editMenuItem": MessageLookupByLibrary.simpleMessage("Edit"),
    "itemMovedSnackbar": m0,
    "itemUncategorizedSnackbar": MessageLookupByLibrary.simpleMessage(
      "Item moved to Uncategorized",
    ),
    "moveToCategoryMenuItem": MessageLookupByLibrary.simpleMessage(
      "Move to category",
    ),
    "noTasksAvailableDialogMessage": MessageLookupByLibrary.simpleMessage(
      "There are no tasks available to pick from.",
    ),
    "noTasksAvailableDialogTitle": MessageLookupByLibrary.simpleMessage(
      "No Tasks",
    ),
    "okButtonText": MessageLookupByLibrary.simpleMessage("OK"),
    "randomTaskDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Randomly Selected Task",
    ),
    "randomTaskMenuButton": MessageLookupByLibrary.simpleMessage("Random Task"),
    "selectCategoryDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Select Category",
    ),
    "uncategorizedCategory": MessageLookupByLibrary.simpleMessage(
      "Uncategorized",
    ),
  };
}
