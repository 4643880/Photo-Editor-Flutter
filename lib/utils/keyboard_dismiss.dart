import 'package:flutter/material.dart';

class KeyboardDismissOnTap extends StatelessWidget {
  const KeyboardDismissOnTap({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  void _hideKeyboard(BuildContext context) {
    final currentFocus = FocusScope.of(context);

    if (!currentFocus.hasPrimaryFocus && currentFocus.hasFocus) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _hideKeyboard(context);
      },
      child: child,
    );
  }
}