// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name =
        (locale.countryCode?.isEmpty ?? false)
            ? locale.languageCode
            : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Random Task`
  String get randomTaskMenuButton {
    return Intl.message(
      'Random Task',
      name: 'randomTaskMenuButton',
      desc: '',
      args: [],
    );
  }

  /// `Randomly Selected Task`
  String get randomTaskDialogTitle {
    return Intl.message(
      'Randomly Selected Task',
      name: 'randomTaskDialogTitle',
      desc: '',
      args: [],
    );
  }

  /// `No Tasks`
  String get noTasksAvailableDialogTitle {
    return Intl.message(
      'No Tasks',
      name: 'noTasksAvailableDialogTitle',
      desc: '',
      args: [],
    );
  }

  /// `There are no tasks available to pick from.`
  String get noTasksAvailableDialogMessage {
    return Intl.message(
      'There are no tasks available to pick from.',
      name: 'noTasksAvailableDialogMessage',
      desc: '',
      args: [],
    );
  }

  /// `All`
  String get all {
    return Intl.message('All', name: 'all', desc: '', args: []);
  }

  /// `Add New Category`
  String get addCategoryDialogTitle {
    return Intl.message(
      'Add New Category',
      name: 'addCategoryDialogTitle',
      desc: '',
      args: [],
    );
  }

  /// `Category Name`
  String get categoryNameHintText {
    return Intl.message(
      'Category Name',
      name: 'categoryNameHintText',
      desc: '',
      args: [],
    );
  }

  /// `Category name cannot be empty.`
  String get categoryNameEmptyError {
    return Intl.message(
      'Category name cannot be empty.',
      name: 'categoryNameEmptyError',
      desc: '',
      args: [],
    );
  }

  /// `This category name already exists.`
  String get categoryNameExistsError {
    return Intl.message(
      'This category name already exists.',
      name: 'categoryNameExistsError',
      desc: '',
      args: [],
    );
  }

  /// `OK`
  String get okButtonText {
    return Intl.message('OK', name: 'okButtonText', desc: '', args: []);
  }

  /// `Cancel`
  String get cancelButtonText {
    return Intl.message('Cancel', name: 'cancelButtonText', desc: '', args: []);
  }

  /// `Add new category`
  String get addCategoryTooltip {
    return Intl.message(
      'Add new category',
      name: 'addCategoryTooltip',
      desc: '',
      args: [],
    );
  }

  /// `Edit`
  String get editMenuItem {
    return Intl.message('Edit', name: 'editMenuItem', desc: '', args: []);
  }

  /// `Delete`
  String get deleteMenuItem {
    return Intl.message('Delete', name: 'deleteMenuItem', desc: '', args: []);
  }

  /// `Move to category`
  String get moveToCategoryMenuItem {
    return Intl.message(
      'Move to category',
      name: 'moveToCategoryMenuItem',
      desc: '',
      args: [],
    );
  }

  /// `Select Category`
  String get selectCategoryDialogTitle {
    return Intl.message(
      'Select Category',
      name: 'selectCategoryDialogTitle',
      desc: '',
      args: [],
    );
  }

  /// `Uncategorized`
  String get uncategorizedCategory {
    return Intl.message(
      'Uncategorized',
      name: 'uncategorizedCategory',
      desc: '',
      args: [],
    );
  }

  /// `Item moved to {categoryName}`
  String itemMovedSnackbar(Object categoryName) {
    return Intl.message(
      'Item moved to $categoryName',
      name: 'itemMovedSnackbar',
      desc: '',
      args: [categoryName],
    );
  }

  /// `Item moved to Uncategorized`
  String get itemUncategorizedSnackbar {
    return Intl.message(
      'Item moved to Uncategorized',
      name: 'itemUncategorizedSnackbar',
      desc: '',
      args: [],
    );
  }

  /// `The secret of getting ahead is getting started.`
  String get motivationalSentence1 {
    return Intl.message(
      'The secret of getting ahead is getting started.',
      name: 'motivationalSentence1',
      desc: '',
      args: [],
    );
  }

  /// `Don't watch the clock; do what it does. Keep going.`
  String get motivationalSentence2 {
    return Intl.message(
      'Don\'t watch the clock; do what it does. Keep going.',
      name: 'motivationalSentence2',
      desc: '',
      args: [],
    );
  }

  /// `The only way to do great work is to love what you do.`
  String get motivationalSentence3 {
    return Intl.message(
      'The only way to do great work is to love what you do.',
      name: 'motivationalSentence3',
      desc: '',
      args: [],
    );
  }

  /// `Your limitation—it's only your imagination.`
  String get motivationalSentence4 {
    return Intl.message(
      'Your limitation—it\'s only your imagination.',
      name: 'motivationalSentence4',
      desc: '',
      args: [],
    );
  }

  /// `Push yourself, because no one else is going to do it for you.`
  String get motivationalSentence5 {
    return Intl.message(
      'Push yourself, because no one else is going to do it for you.',
      name: 'motivationalSentence5',
      desc: '',
      args: [],
    );
  }

  /// `Task count display string`
  String taskCount(int count) {
    return Intl.plural(
      count,
      zero: 'No tasks',
      one: '$count task',
      other: '$count tasks',
      name: 'taskCount',
      desc: 'Task count display string',
      args: [count],
    );
  }

  /// `Empty Todo`
  String get emptyTodoDialogTitle {
    return Intl.message(
      'Empty Todo',
      name: 'emptyTodoDialogTitle',
      desc: '',
      args: [],
    );
  }

  /// `Please write something for your todo.`
  String get emptyTodoDialogMessage {
    return Intl.message(
      'Please write something for your todo.',
      name: 'emptyTodoDialogMessage',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'he'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
