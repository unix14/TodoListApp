import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../common/common_styles.dart';

// ignore: use_key_in_widget_constructors
class RoundedTextInputField extends StatefulWidget {
  String initialText;
  String hintText;

  FocusNode? focusNode;
  final Function()? callback;

  final ValueChanged<String>? onChanged;
  final _controller = TextEditingController();

  RoundedTextInputField({Key? key,
    this.initialText = "",
    this.hintText = "",
    this.focusNode,
    this.callback,
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
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (FocusScope.of(context).focusedChild != widget.focusNode &&
              widget.callback != null && event.logicalKey == LogicalKeyboardKey.enter) {
            widget.callback!();
          }
        },
        child: TextField(
          controller: widget._controller,
          focusNode: widget.focusNode,
          onChanged: widget.onChanged,
          onSubmitted: (value) {
            if (widget.callback != null) {
              widget.callback!(); // Trigger callback when Enter is pressed
            }
          },
          decoration: kFieldDecoration.copyWith(
            hintText: widget.hintText,
          ),
        ),
      ),
    );
  }
}
