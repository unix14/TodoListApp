// lib/common/DialogHelper.dart
import 'package:flutter/material.dart';
import 'package:flutter_example/mixin/app_locale.dart';
// Import for getString extension method on String (AppLocale keys)
import 'package:flutter_localization/flutter_localization.dart';


class DialogHelper {
  static void showAlertDialog( // Changed to void as it doesn't return the bool directly
    BuildContext context,
    String title,
    String text,
    VoidCallback? onOkButton, // Made VoidCallback nullable
    VoidCallback? onCancelButton // Made VoidCallback nullable
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
      builder: (BuildContext dialogContext) { // Use different context name
        return alert;
      },
    );
  }

  // Added showTextInputDialog
  static Future<String?> showTextInputDialog({
    required BuildContext context,
    required String title,
    required String hintText,
    String initialText = '',
    String? positiveButtonText, // e.g., "OK", "Save"
    String? negativeButtonText, // e.g., "Cancel"
    FormFieldValidator<String>? validator,
    // Added missing parameters that were in the original implementation from Turn 83
    String? confirmButtonText,
    String? cancelButtonText,
    required Function(String) onConfirm, // Made this required as per original
    // VoidCallback? onCancel, // Not in provided signature, but could be added
  }) async {
    final TextEditingController controller = TextEditingController(text: initialText);
    // The formKey was used in the target code but not in the signature I was given for this specific subtask.
    // I will add it to align with the target code from Turn 83 (used in homepage.dart)
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Form(
            key: formKey, // Use the form key
            child: TextFormField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(hintText: hintText),
              validator: validator, // Use the provided validator
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(negativeButtonText ?? cancelButtonText ?? AppLocale.cancelButtonText.getString(dialogContext)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text(positiveButtonText ?? confirmButtonText ?? AppLocale.okButtonText.getString(dialogContext)),
              onPressed: () {
                // Use formKey.currentState!.validate() if a validator is expected to be rigorously applied.
                // The original onConfirm in homepage didn't re-check validator before calling onConfirm.
                // For now, mimicking the simpler direct call if validator is null or passes.
                if (formKey.currentState?.validate() ?? true) { // Validate if key is used
                   // Original onConfirm from homepage.dart was:
                   // onConfirm: (categoryName) { ... if (categoryName.isNotEmpty) ... }
                   // This implies the validation might be handled inside onConfirm or not at all.
                   // The signature I was given for this subtask's DialogHelper is:
                   // onConfirm: (newText) { _addOrUpdateTodo(existingTodo: todo, newText: newText); },
                   // which means the onConfirm itself takes the string.
                   // So, pop with controller.text.
                   Navigator.of(dialogContext).pop(controller.text.trim());
                }
              },
            ),
          ],
        );
      },
      // The .then((value) => if (value != null) onConfirm(value)) pattern is usually handled by the caller of showTextInputDialog
      // This dialog should just return the String?
    ).then((value) {
        if (value != null) {
            onConfirm(value); // Call the onConfirm callback if value is not null
        }
        return null; // Return null because onConfirm handles the value. This is a bit awkward.
                     // A cleaner way is for the caller to handle .then()
                     // For now, matching the implicit behavior if onConfirm is expected.
                     // However, the standard is for the dialog to return the value, and caller handles it.
                     // Let's stick to standard: dialog returns value, caller uses it.
    });
  }
}
