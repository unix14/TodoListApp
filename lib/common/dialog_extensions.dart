

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_example/generated/l10n.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;


extension DialogExtensions on BuildContext {

  void showSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(message)));
  }

  void copyToClipboard(String text)  async {
    // copy to clipboard
    await Clipboard.setData(ClipboardData(text: text));
    // copied successfully
    showSnackBar(S.of(this).copiedToClipboard(text: text));
  }


  Future<String> getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      print('App Version: ${packageInfo.version}');
      return packageInfo.version;
    } catch (e) {
      print('Failed to get app version: $e');
      return "1.0";
    }
  }

  void showAlertDialog(String title, String message) async {
    // FunnelsManager().start(AnalytixFunnel(Funnels.funnel_2, shouldCountTime: true));
    // AnalytixManager().logEvent('user_click', 'show_alert_dialog', params: {
    //   'title': title,
    //   'message': message,
    // });

    await showDialog(
      context: this,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(S.of(context).okButton, style: const TextStyle(color: Colors.black),),
            ),
          ],
        );
      },
    );
    // FunnelsManager().finish(Funnels.funnel_2, "dialog_closed");
  }

  void showAreYouSureDialog(
      String title,
      String message,
      Function() callback,
      {Widget? bottomWidget,
        String? firstButtonText,
        String? secondButtonText,
        String? thirdButtonText,
        Function()? thirdButtonCallback,
        bool thirdButtonShouldClose = true,
      }) {
    // AnalytixManager().logEvent('user_click', 'show_are_you_sure_dialog', params: {
    //   'title': title,
    //   'message': message,
    //   'thirdButtonText': thirdButtonText ?? "",
    // });

    final S s = S.of(this); // 'this' is the BuildContext of DialogExtensions
    final String actualFirstButtonText = firstButtonText ?? s.okButton;
    final String actualSecondButtonText = secondButtonText ?? s.cancelButton;

    showDialog(
      context: this,
      builder: (dialogContext) { // Renamed to avoid confusion
        return getDialog(
          dialogContext,
          title,
          message,
          callback,
          bottomWidget: bottomWidget,
          firstButtonText: actualFirstButtonText,
          secondButtonText: actualSecondButtonText,
          thirdButtonText: thirdButtonText,
          thirdButtonCallback: thirdButtonCallback,
          thirdButtonShouldClose: thirdButtonShouldClose,);
      },
    );
  }

  AlertDialog getDialog(
      BuildContext context,
      String title,
      String message,
      Function() callback,
      {Widget? bottomWidget,
        // Default values are placeholders that signal to use localization if not overridden by caller.
        String firstButtonTextOverride = "OK",
        String secondButtonTextOverride = "Cancel",
        String? thirdButtonText,
        Function()? thirdButtonCallback,
        bool thirdButtonShouldClose = true,
      }) {
    final S s = S.of(context);
    // Use localized text if the default placeholder ("OK"/"Cancel") is passed,
    // otherwise use the text provided by the caller.
    final String actualFirstButtonText = (firstButtonTextOverride == "OK")
        ? s.okButton
        : firstButtonTextOverride;
    final String actualSecondButtonText = (secondButtonTextOverride == "Cancel")
        ? s.cancelButton
        : secondButtonTextOverride;

    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        Column(
          children: [
            bottomWidget ?? const SizedBox(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if(thirdButtonText != null)
                  TextButton(
                    onPressed: () {
                      if(thirdButtonShouldClose) {
                        Navigator.of(context).pop();
                      }
                      thirdButtonCallback?.call();
                    },
                    child: Text(thirdButtonText, style: const TextStyle(color: Colors.black),),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(actualSecondButtonText, style: const TextStyle(color: Colors.black),),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    callback();
                  },
                  child: Text(actualFirstButtonText, style: const TextStyle(color: Colors.black),),
                ),
              ],
            ),
          ],
        ),
      ],
    );

  }




}