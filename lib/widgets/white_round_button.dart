

import 'package:flutter/material.dart';

class WhiteRoundButton extends StatelessWidget {

  final String text;
  final Function? onPressed;

  const WhiteRoundButton({Key? key, required this.text, required this.onPressed}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black, backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
      ),
      onPressed: onPressed != null ? () async {
          onPressed!();
      } : null,
      child: Text(text),
    );
  }
}