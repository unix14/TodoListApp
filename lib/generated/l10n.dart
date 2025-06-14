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

  /// `OK`
  String get okButton {
    return Intl.message('OK', name: 'okButton', desc: '', args: []);
  }

  /// `Cancel`
  String get cancelButton {
    return Intl.message('Cancel', name: 'cancelButton', desc: '', args: []);
  }

  /// `Close`
  String get closeButton {
    return Intl.message('Close', name: 'closeButton', desc: '', args: []);
  }

  /// `Empty Todo`
  String get emptyTodoTitle {
    return Intl.message(
      'Empty Todo',
      name: 'emptyTodoTitle',
      desc: '',
      args: [],
    );
  }

  /// `Please write a Todo`
  String get emptyTodoMessage {
    return Intl.message(
      'Please write a Todo',
      name: 'emptyTodoMessage',
      desc: '',
      args: [],
    );
  }

  /// `Edit your ToDo here!`
  String get editTodoHint {
    return Intl.message(
      'Edit your ToDo here!',
      name: 'editTodoHint',
      desc: '',
      args: [],
    );
  }

  /// `Do you want to delete?`
  String get deleteTodoTitle {
    return Intl.message(
      'Do you want to delete?',
      name: 'deleteTodoTitle',
      desc: '',
      args: [],
    );
  }

  /// `This can't be undone`
  String get deleteTodoMessage {
    return Intl.message(
      'This can\'t be undone',
      name: 'deleteTodoMessage',
      desc: '',
      args: [],
    );
  }

  /// `App is installed`
  String get appIsInstalled {
    return Intl.message(
      'App is installed',
      name: 'appIsInstalled',
      desc: '',
      args: [],
    );
  }

  /// `Login failed`
  String get loginFailedTitle {
    return Intl.message(
      'Login failed',
      name: 'loginFailedTitle',
      desc: '',
      args: [],
    );
  }

  /// `Signup failed`
  String get signupFailedTitle {
    return Intl.message(
      'Signup failed',
      name: 'signupFailedTitle',
      desc: '',
      args: [],
    );
  }

  /// `You are now logged in, Welcome`
  String get loggedInWelcomeMessage {
    return Intl.message(
      'You are now logged in, Welcome',
      name: 'loggedInWelcomeMessage',
      desc: '',
      args: [],
    );
  }

  /// `No user found for that email.`
  String get authNoUserFound {
    return Intl.message(
      'No user found for that email.',
      name: 'authNoUserFound',
      desc: '',
      args: [],
    );
  }

  /// `Wrong password provided for that user.`
  String get authWrongPassword {
    return Intl.message(
      'Wrong password provided for that user.',
      name: 'authWrongPassword',
      desc: '',
      args: [],
    );
  }

  /// `The password provided is too weak.`
  String get authWeakPassword {
    return Intl.message(
      'The password provided is too weak.',
      name: 'authWeakPassword',
      desc: '',
      args: [],
    );
  }

  /// `The account already exists for that email.`
  String get authEmailAlreadyInUse {
    return Intl.message(
      'The account already exists for that email.',
      name: 'authEmailAlreadyInUse',
      desc: '',
      args: [],
    );
  }

  /// `Unknown Error`
  String get authUnknownError {
    return Intl.message(
      'Unknown Error, please try again later.',
      name: 'authUnknownError',
      desc: '',
      args: [],
    );
  }

    /// `Copied to clipboard: {text}`
    String copiedToClipboard(String text) {
      return Intl.message(
        'Copied to clipboard: $text',
        name: 'copiedToClipboard',
        desc: 'Snackbar message when text is copied',
        args: [text],
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
