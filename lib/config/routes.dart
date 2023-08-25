import 'package:editor_demo/image_editor/home_screen.dart';
import 'package:editor_demo/utils/keyboard_dismiss.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const routeHome = '/routeHome';

class Routes {
  static final routes = [
    GetPage(
      name: routeHome,
      page: () => TKDismiss(HomeScreen()),
      binding: BindingsBuilder(() {}),
    ),
  ];
}

// Tap Keyboard dismiss
class TKDismiss extends StatelessWidget {
  const TKDismiss(this.child, {Key? key}) : super(key: key);
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(child: child);
  }
}
