import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_example/mixin/app_locale.dart';

class DialogHelper {
  static Future<bool?> showAlertDialog(BuildContext context, String title, String message, // Renamed 'text' to 'message' for clarity
      VoidCallback? onOkButton, // This callback should ideally do Navigator.pop(context, true)
      VoidCallback? onCancelButton // This callback should ideally do Navigator.pop(context, false)
      ) async { // Added async and Future<bool?>

    // set up the button
    Widget okButton = TextButton(
      child: Text(AppLocale.okButtonText.getString(context)),
      onPressed: onOkButton, // Caller's callback, expected to pop with true
    );

    Widget? cancelButtonWidget; // Nullable
    if (onCancelButton != null) {
      cancelButtonWidget = TextButton(
        child: Text(AppLocale.cancelButtonText.getString(context)),
        onPressed: onCancelButton, // Caller's callback, expected to pop with false
      );
    }

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(message), // Used renamed parameter
      actions: <Widget>[ // Explicitly typed
        if(cancelButtonWidget != null) cancelButtonWidget,
        if(onOkButton != null) okButton, // Ensure okButton is only added if onOkButton is provided
      ],
    );

    // show the dialog and return its result
    return await showDialog<bool>( // Added await and return, specified type for showDialog
      context: context,
      barrierDismissible: onCancelButton == null, // Dismiss by clicking outside if no cancel button
      builder: (BuildContext dialogContext) { // Use dialogContext for builder
        return alert;
      },
    );
  }
}
