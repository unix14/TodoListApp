import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_example/mixin/app_locale.dart';

class DialogHelper {
  static showAlertDialog(BuildContext context, String title, String text,
      VoidCallback? onOkButton,
      VoidCallback? onCancelButton
      ) {

    // set up the button
    Widget okButton = TextButton(
      child: Text(AppLocale.ok.getString(context)),
      onPressed: onOkButton,
    );

    Widget cancelButton = TextButton(
      child: Text(AppLocale.cancel.getString(context)),
      onPressed: onCancelButton,
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(text),
      actions: [
        if(onCancelButton != null) cancelButton,
        if(onOkButton != null) okButton,
      ],
    );
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
