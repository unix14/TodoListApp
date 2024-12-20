
// import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

// String getFormattedDate(_date) {
//   var inputFormat = DateFormat('yyyy-MM-dd HH:mm');
//   var inputDate = inputFormat.parse(_date);
//   var outputFormat = DateFormat('dd/MM/yyyy HH:mm');
//   return outputFormat.format(inputDate);
// }


import 'package:flutter/cupertino.dart';

const String kAllListSavedPrefs = "LIST";

const kDefaultPadding = EdgeInsets.fromLTRB(19, 0, 0, 19);

const kDeleteAllMenuButtonName = "deleteAll";
const kArchiveMenuButtonName = "archive";
const kLoginButtonMenu = 'login';



/*static*/ final verticalDivider = Container(
  height: 1,
  color: Colors.grey,
  width: 80,
);


/*static*/ Widget orWidget = Padding(
  padding: const EdgeInsets.only(top: 28, bottom: 8),
  child: Row(
    mainAxisSize: MainAxisSize.max,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      verticalDivider,
      const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text("or", style: TextStyle(color: Colors.grey, fontSize: 12,),),
      ),
      verticalDivider,
    ],
  ),
);
