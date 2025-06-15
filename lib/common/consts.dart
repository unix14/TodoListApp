
// import 'package:intl/intl.dart';
import 'dart:js_interop';

import 'package:flutter/material.dart';

// String getFormattedDate(_date) {
//   var inputFormat = DateFormat('yyyy-MM-dd HH:mm');
//   var inputDate = inputFormat.parse(_date);
//   var outputFormat = DateFormat('dd/MM/yyyy HH:mm');
//   return outputFormat.format(inputDate);
// }


import 'package:flutter/cupertino.dart';
import 'package:flutter_localization/flutter_localization.dart';

import '../mixin/app_locale.dart';

const String kAllListSavedPrefs = "LIST";
const String kCurrentLocaleSavedPrefs = "CURRENT_LOCALE";


const String kAdUnitIdDebug  = "ca-app-pub-3940256099942544/6300978111";
const String kAdUnitIdProd = "ca-app-pub-7481638286003806/6665802500";

const kDefaultPadding = EdgeInsets.fromLTRB(19, 0, 0, 19);

const kDeleteAllMenuButtonName = "deleteAll";
const kSettingsMenuButtonName = "settings";
const kArchiveMenuButtonName = "archive";
const kInstallMenuButtonName = "installwpa";
const kLoginButtonMenu = 'login';

// Firebase Realtime Database Paths
const String kDBPathUsers = "users";
const String kDBPathSharedListConfigs = "shared_list_configs";
const String kDBPathSharedLinkPaths = "shared_link_paths";
const String kDBPathSharedTodos = "shared_todos";
const String kDBPathSharedTodosItems = "items";
const String kDBPathSharedTodosMetadata = "metadata";


/*static*/ final verticalDivider = Container(
  height: 1,
  color: Colors.grey,
  width: 80,
);

final simpleDivider = Container(
  height: 1,
  color: Colors.grey,
);

double fabOpacityOff = 0.42;


  Widget orWidget(BuildContext context) => Padding(
  padding: const EdgeInsets.only(top: 28, bottom: 8),
  child: Row(
    mainAxisSize: MainAxisSize.max,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      verticalDivider,
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(AppLocale.or.getString(context), style: const TextStyle(color: Colors.grey, fontSize: 12,),),
      ),
      verticalDivider,
    ],
  ),
);
