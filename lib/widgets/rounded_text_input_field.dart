import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../common/common_styles.dart';

// ignore: use_key_in_widget_constructors
class RoundedTextInputField extends StatefulWidget {
  String initialText;
  String hintText;

  final ValueChanged<String>? onChanged;
  final _controller = TextEditingController();

  RoundedTextInputField({Key? key,
    this.initialText = "",
    this.hintText = "",
    required this.onChanged}) : super(key: key);

  @override
  State<RoundedTextInputField> createState() => _RoundedTextInputFieldState();

  void clear() {
    _controller.clear();
  }

  String getText() => _controller.value.text;
}

class _RoundedTextInputFieldState extends State<RoundedTextInputField> {

  @override
  void initState() {
    super.initState();
    widget._controller.text = widget.initialText;
  }


  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: TextField(
        controller: widget._controller,
        onChanged: widget.onChanged,
        decoration: kFieldDecoration.copyWith(
          // labelText: widget.hintText,
          hintText: widget.hintText,
        ),
      ),
    );
  }
}
