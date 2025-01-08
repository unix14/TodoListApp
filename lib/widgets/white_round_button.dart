

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
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      onPressed: onPressed != null ? () async {
          onPressed!();
      } : null,
      child: Text(text, style: const TextStyle(fontSize: 15, fontFamily: 'Roboto'),),
    );
  }
}