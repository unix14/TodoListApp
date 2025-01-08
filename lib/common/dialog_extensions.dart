

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    showSnackBar("Copied to clipboard: $text");
  }


  Future<String> getAppVersion() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      print("Package info is not supported on this platform.");
      return "Unknown - todo";
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      print('App Version: ${packageInfo.version}');
      return packageInfo.version;
    } catch (e) {
      print('Failed to get app version: $e');
      return "-1";
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
              child: const Text('OK', style: TextStyle(color: Colors.black),),
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
        String firstButtonText = "OK",
        String secondButtonText = "Cancel",
        String? thirdButtonText,
        Function()? thirdButtonCallback,
        bool thirdButtonShouldClose = true,
      }) {
    // AnalytixManager().logEvent('user_click', 'show_are_you_sure_dialog', params: {
    //   'title': title,
    //   'message': message,
    //   'thirdButtonText': thirdButtonText ?? "",
    // });
    showDialog(
      context: this,
      builder: (context) {
        return getDialog(
          context,
          title,
          message,
          callback,
          bottomWidget: bottomWidget,
          firstButtonText: firstButtonText,
          secondButtonText: secondButtonText,
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
        String firstButtonText = "OK",
        String secondButtonText = "Cancel",
        String? thirdButtonText,
        Function()? thirdButtonCallback,
        bool thirdButtonShouldClose = true,
      }) {
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
                  child: Text(secondButtonText, style: TextStyle(color: Colors.black),),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    callback();
                  },
                  child: Text(firstButtonText, style: TextStyle(color: Colors.black),),
                ),
              ],
            ),
          ],
        ),
      ],
    );

  }




}