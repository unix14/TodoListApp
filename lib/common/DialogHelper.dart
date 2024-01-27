import 'package:flutter/material.dart';

class DialogHelper {
  static showAlertDialog(BuildContext context, String title, String text,
      VoidCallback? onOkButton) {

    // set up the button
    Widget okButton = TextButton(
      child: const Text("OK"),
      onPressed: onOkButton,
    );

    Widget cancelButton = TextButton(
      child: const Text("Cancel"),
      onPressed: () {
        Navigator.of(context).pop(); // dismiss dialog
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(text),
      actions: [
        cancelButton,
        okButton,
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
