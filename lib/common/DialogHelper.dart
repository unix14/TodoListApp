// lib/common/DialogHelper.dart
import 'package:flutter/material.dart';
import 'package:flutter_example/mixin/app_locale.dart';
import 'package:flutter_localization/flutter_localization.dart'; // For AppLocale.KEY.getString

class DialogHelper {
  static void showAlertDialog(
    BuildContext context,
    String title,
    String text,
    VoidCallback? onOkButton,
    VoidCallback? onCancelButton
  ) {
    Widget okButton = TextButton(
      child: Text(AppLocale.okButtonText.getString(context)),
      onPressed: onOkButton,
    );

    Widget cancelButton = TextButton(
      child: Text(AppLocale.cancelButtonText.getString(context)),
      onPressed: onCancelButton,
    );

    List<Widget> actions = [];
    if(onCancelButton != null) actions.add(cancelButton);
    if(onOkButton != null) actions.add(okButton);

    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(text),
      actions: actions,
    );

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return alert;
      },
    );
  }

  static Future<String?> showTextInputDialog({
    required BuildContext context,
    required String title,
    required String hintText,
    String initialText = '',
    String? positiveButtonText,
    String? negativeButtonText,
    FormFieldValidator<String>? validator,
  }) async {
    final TextEditingController controller = TextEditingController(text: initialText);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>(); // Changed to FormState

    return await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(hintText: hintText),
              validator: validator,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(negativeButtonText ?? AppLocale.cancelButtonText.getString(dialogContext)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text(positiveButtonText ?? AppLocale.okButtonText.getString(dialogContext)),
              onPressed: () {
                if (formKey.currentState?.validate() == true) { // Use FormState
                   Navigator.of(dialogContext).pop(controller.text.trim());
                }
              },
            ),
          ],
        );
      },
    );
  }
}
